//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Runtime
import Swallow

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension _KeyedFileBundleChildren {
    struct ChildConfiguration {
        weak var enclosingInstance: (any FileBundle)?
        
        let parent: any _FileBundleContainerElement
        let key: String
        let readOptions: Set<FileDocumentReadOption>
        let fileWrapper: _AsyncFileWrapper?
        let initialValue: Value?
        
        init(
            enclosingInstance: (any FileBundle)?,
            parent: any _FileBundleContainerElement,
            key: String,
            readOptions: Set<FileDocumentReadOption>,
            fileWrapper: _AsyncFileWrapper?,
            initialValue: Value?)
        {
            self.enclosingInstance = enclosingInstance
            self.parent = parent
            self.key = key
            self.readOptions = readOptions
            self.fileWrapper = fileWrapper
            self.initialValue = initialValue
        }
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
final class _KeyedFileBundleChildren<Key: StringRepresentable, Value, WrappedValue>: ObservableObject, _KeyedFileBundleChild, _FileBundleContainerElement {
    typealias Contents = [Key: Value]
    typealias MakeChild = (ChildConfiguration) throws -> (any _KeyedFileBundleChild<Value>)?
    
    struct Configuration {
        let folderConfiguration: _RelativeFolderConfiguration<[String: Value]>
        let makeChild: MakeChild
    }
    
    weak private(set) var enclosingInstance: (any FileBundle)?
    weak private(set) var parent: (any _FileBundleContainerElement)?
    
    let key: String
    var stateFlags: StateFlags = []
    
    public var knownFileURL: URL? {
        get throws {
            try parent?.knownFileURL?.appending(URL.PathComponent(rawValue: _fileName, isDirectory: true))
        }
    }
    
    fileprivate(set) var fileWrapper: _AsyncFileWrapper? {
        willSet {
            guard fileWrapper != newValue else {
                return
            }
            
            _expectNoThrow {
                try _removeFileWrapperFromParent(forReplacementWith: newValue)
            }
        } didSet {
            guard oldValue != fileWrapper else {
                return
            }
            
            _expectNoThrow {
                try _addFileWrapperToParent()
            }
        }
    }
    
    private let configuration: Configuration
    
    private var children: [Key: any _KeyedFileBundleChild<Value>] = [:] {
        willSet {
            objectWillChange.send()
        }
    }
    
    var contents: Contents {
        get throws {
            try children
                .mapValues { child in
                    try child.contents
                }
        }
    }
    
    var preferredFileName: String?
    
    init?(
        parameters: InitializationParameters,
        configuration: Configuration
    ) throws {
        self.enclosingInstance = parameters.enclosingInstance
        self.parent = parameters.parent
        self.key = parameters.key
        self.configuration = configuration
        self.preferredFileName = configuration.folderConfiguration.path
        
        guard let fileWrapper = try initializeFileWrapper(parameters: parameters) else {
            return nil
        }
        
        try _withLogicalParent(enclosingInstance) {
            try initializeChildren(parameters: parameters, fileWrapper: fileWrapper)
        }
    }
    
    private func initializeChildren(
        parameters: InitializationParameters,
        fileWrapper: _AsyncFileWrapper
    ) throws {
        let childFileWrappers = try fileWrapper.fileWrappers.unwrap()
        
        for (key, childFileWrapper) in childFileWrappers {
            if key == ".DS_Store" {
                fileWrapper.removeFileWrapper(childFileWrapper)
                
                continue
            }
            
            let childParameters = ChildConfiguration(
                enclosingInstance: enclosingInstance,
                parent: self,
                key: key,
                readOptions: parameters.readOptions,
                fileWrapper: fileWrapper,
                initialValue: nil
            )
            
            _expectNoThrow {
                do {
                    if let child = try configuration.makeChild(childParameters) {
                        let key = try Key(stringValue: child.key).unwrap()
                        
                        if key.stringValue != child.key {
                            assertionFailure()
                        }
                        
                        children[key] = child
                    } else {
                        fileWrapper.removeFileWrapper(childFileWrapper)
                    }
                } catch {
                    fileWrapper.removeFileWrapper(childFileWrapper)
                    
                    throw error
                }
            }
        }
    }
    
    private func initializeFileWrapper(
        parameters: InitializationParameters
    ) throws -> _AsyncFileWrapper? {
        if let parentFileWrapper = parameters.parent.fileWrapper {
            if let fileWrapper = try parentFileWrapper.fileWrappers.unwrap()[self._fileName] {
                self.fileWrapper = fileWrapper
            } else {
                if parameters.readOptions.contains(.createIfNeeded) {
                    self.fileWrapper = _AsyncFileWrapper(directoryWithFileWrappers: [:])
                } else {
                    self.fileWrapper = nil
                }
            }
        } else {
            throw Never.Reason.unimplemented
        }
        
        return self.fileWrapper
    }
    
    func childDidUpdate(_ node: _FileBundleChild) {
        parent?.childDidUpdate(self)
    }
    
    @MainActor
    public func setContents(
        _ newValue: Contents
    ) throws {
        let difference = Set(newValue.keys).difference(from: Set(children.keys))
        
        var removedKeysByValue: [_HashableOrObjectIdentifier: Key] = [:]
        var insertedKeysByValue: [_HashableOrObjectIdentifier: Key] = [:]
        var valuesInsertedMultipleTimes: Set<_HashableOrObjectIdentifier> = []
        
        for key in difference.removals {
            let _value = try children[key].unwrap().contents
            
            if let value = _HashableOrObjectIdentifier(from: _value) {
                removedKeysByValue[value] = key
            }
        }
        
        for key in difference.insertions {
            let _value = try newValue[key].unwrap()
            
            if let value = _HashableOrObjectIdentifier(from: _value) {
                if insertedKeysByValue[value] != nil {
                    valuesInsertedMultipleTimes.insert(value)
                }
                
                insertedKeysByValue[value] = key
            }
        }
        
        for value in valuesInsertedMultipleTimes {
            insertedKeysByValue[value] = nil
        }
        
        var renamedKeys: [Key: Key] = [:]
        
        for (value, removedKey) in removedKeysByValue {
            if let insertedKey = insertedKeysByValue[value] {
                renamedKeys[removedKey] = insertedKey
            }
        }
        
        var newChildren = children
        
        for key in difference.removals {
            guard renamedKeys[key] == nil else {
                continue
            }
            
            let child = try children[key].unwrap()
            
            try _tryAssert(Key(stringValue: child.key).unwrap() == key)
            
            child.stateFlags.insert(.deletedByParent)
            
            try child._removeFileWrapperFromParent(forReplacementWith: nil)
            
            _expectNoThrow {
                if let childURL = try child.knownFileURL {
                    try FileManager.default.removeItemIfNecessary(at: childURL)
                }
            }
            
            newChildren[key] = nil
        }
        
        for key in difference.insertions {
            guard renamedKeys[key] == nil else {
                fatalError(.unexpected)
            }
            
            let value = newValue[key]!
            
            let childParameters = ChildConfiguration(
                enclosingInstance: enclosingInstance,
                parent: self,
                key: key.stringValue,
                readOptions: [.createIfNeeded],
                fileWrapper: nil,
                initialValue: value
            )
            
            if var value = value as? (any FileBundle), value._fileBundleObject == nil {
                value = try _withLogicalParent(enclosingInstance) {
                    value
                }
                
                let temporaryID: AnyHashable = UUID()
                let childFileWrapper = _AsyncFileWrapper(directoryWithFileWrappers: .init())
                
                childFileWrapper.preferredFileName = key.stringValue
                
                try self.fileWrapper.unwrap().addFileWrapper(childFileWrapper)
                
                let newChild = try value._createKeyedFileBundleChildWithUnitializedSelf(
                    enclosingInstance: enclosingInstance,
                    parent: self,
                    key: key.stringValue,
                    existingFileWrapper: childFileWrapper
                )
                
                let initialized = try value._initializeBackingObject(
                    parameters: .init(
                        parent: enclosingInstance,
                        file: _FileRepresentingFileWrapper(childFileWrapper, id: temporaryID),
                        readOptions: [.createIfNeeded],
                        owner: newChild
                    )
                )
                
                try _tryAssert(initialized)
                
                newChildren[key] = try cast(newChild)
            } else if let child = try configuration.makeChild(childParameters) {
                newChildren[key] = child
            }
        }
        
        self.children = newChildren
        
        parent?.childDidUpdate(self)
    }
    
    func refresh() throws {
        
    }
}
