//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow

public final class _ObservableIdentifiedFolderContents<Item, ID: Hashable>: MutablePropertyWrapper, ObservableObject {
    public enum Element {
        case url(any _FileOrFolderRepresenting)
        case inMemory(Item)
    }
    
    public typealias WrappedValue = IdentifierIndexingArray<Item, ID>
    
    public let folder: any _FileOrFolderRepresenting
    public let fileConfiguration: (Element) throws -> _RelativeFileConfiguration<Item>
    public let id: (Item) -> ID
    
    private var storage: [ID: _FileStorageCoordinators.RegularFile<MutableValueBox<Item>, Item>] = [:]
    
    public private(set) var _resolvedWrappedValue: WrappedValue?
    
    @MainActor
    public var _wrappedValue: WrappedValue {
        get {
            guard let result = _resolvedWrappedValue else {
                self._resolvedWrappedValue = WrappedValue(id: id)
                
                _initializeWrappedValue()
                
                return _resolvedWrappedValue!
            }
            
            return result
        } set {
            assert(_resolvedWrappedValue != nil)
            
            _resolvedWrappedValue = newValue
        }
    }
    
    @MainActor
    public var folderURL: URL {
        get throws {
            try self.folder._toURL()
        }
    }
    
    @MainActor
    public var wrappedValue: WrappedValue {
        get {
            _wrappedValue
        } set {
            objectWillChange.send()
            
            try! FileManager.default.withUserGrantedAccess(to: folderURL) { folderURL in
                try! _setNewValue(newValue, withFolderURL: folderURL)
            }
        }
    }
    
    @MainActor
    public init(
        folder: any _FileOrFolderRepresenting,
        fileConfiguration: @escaping (Element) throws -> _RelativeFileConfiguration<Item>,
        id: @escaping (Item) -> ID
    ) {
        self.folder = folder
        self.fileConfiguration = fileConfiguration
        self.id = id
    }
    
    @MainActor
    private func _initializeWrappedValue() {
        _expectNoThrow {
            let folderURL = try self.folderURL
            
            do {
                if !FileManager.default.fileExists(at: folderURL) {
                    try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
                }
            } catch {
                runtimeIssue(error)
            }
            
            try FileManager.default.withUserGrantedAccess(to: folderURL) { url in
                try _initialize(withFolderURL: url)
            }
        }
    }
    
    @MainActor
    private func _initialize(
        withFolderURL folderURL: URL
    ) throws {
        try FileManager.default.createDirectoryIfNecessary(at: folderURL, withIntermediateDirectories: true)
        
        let urls = try FileManager.default.contentsOfDirectory(at: folderURL)
        
        for url in urls {
            do {
                if FileManager.default.isDirectory(at: url) {
                    continue
                }
                
                var fileConfiguration = try self.fileConfiguration(.url(FileURL(url)))
                let relativeFilePath = try fileConfiguration.consumePath()
                let fileURL = try FileURL(folder._toURL().appendingPathComponent(relativeFilePath))
                
                let fileCoordinator = try _FileStorageCoordinators.RegularFile<MutableValueBox<Item>, Item>(
                    fileSystemResource: fileURL,
                    configuration: fileConfiguration
                )
                
                _expectNoThrow {
                    try _withLogicalParent(ofType: AnyObject.self) {
                        fileCoordinator._enclosingInstance = $0
                    }
                }
                
                let element = try fileCoordinator._wrappedValue
                
                self.storage[self.id(element)] = fileCoordinator
                
                self._wrappedValue.append(element)
            } catch {
                runtimeIssue("An error occurred while reading \(url)")
            }
        }
    }
    
    @MainActor
    public func _setNewValue(
        _ newValue: IdentifierIndexingArray<Item, ID>,
        withFolderURL folderURL: URL
    ) throws {
        let oldValue = self._wrappedValue
        let difference = Set(newValue.identifiers).difference(from: Set(oldValue.identifiers))
        
        var removedKeysByValue: [_HashableOrObjectIdentifier: ID] = [:]
        var insertedKeysByValue: [_HashableOrObjectIdentifier: ID] = [:]
        var valuesInsertedMultipleTimes: Set<_HashableOrObjectIdentifier> = []
        
        for key in difference.removals {
            let _value = try oldValue[id: key].unwrap()
            
            if let value = _HashableOrObjectIdentifier(from: _value) {
                removedKeysByValue[value] = key
            }
        }
        
        for key in difference.insertions {
            let _value = try newValue[id: key].unwrap()
            
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
        
        var renamedKeys: [ID: ID] = [:]
        
        for (value, removedKey) in removedKeysByValue {
            if let insertedKey = insertedKeysByValue[value] {
                renamedKeys[removedKey] = insertedKey
            }
        }
        
        var updatedNewValue = oldValue
        
        for key in difference.removals {
            guard renamedKeys[key] == nil else {
                continue
            }
            
            let fileURL = try storage[key].unwrap().fileSystemResource._toURL()
            
            assert(FileManager.default.regularFileExists(at: fileURL))
            
            storage[key]?.discard()
            storage[key] = nil
            
            updatedNewValue[id: key] = nil
            
            try FileManager.default.removeItemIfNecessary(at: fileURL)
        }
        
        for key in difference.insertions {
            guard renamedKeys[key] == nil else {
                fatalError(.unexpected)
            }
            
            let element = newValue[id: key]!
            var fileConfiguration = try fileConfiguration(.inMemory(element))
            let relativeFilePath = try fileConfiguration.consumePath()
            let fileURL = folderURL.appendingPathComponent(relativeFilePath)
            
            fileConfiguration.serialization.initialValue = .available(element)
            
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            
            let fileCoordinator = try! _FileStorageCoordinators.RegularFile<MutableValueBox<Item>, Item>(
                fileSystemResource: FileURL(fileURL),
                configuration: fileConfiguration
            )
            
            fileCoordinator.commit()
            
            storage[key] = fileCoordinator
            updatedNewValue[id: key] = element
        }
        
        let updated = updatedNewValue._unorderedIdentifiers.removing(contentsOf: difference.insertions)
        
        for identifier in updated {
            let updatedElement = newValue[id: identifier]!
            
            self.storage[identifier]!.wrappedValue = updatedElement
            
            updatedNewValue[id: identifier] = updatedElement
        }
        
        self._wrappedValue = updatedNewValue
    }
}
