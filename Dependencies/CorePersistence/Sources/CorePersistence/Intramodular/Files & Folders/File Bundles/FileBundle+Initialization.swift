//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Runtime
import Swallow

public enum FileDocumentReadOption: Hashable {
    case createIfNeeded
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension _FileBundle where Self: FileBundle {
    internal init?(
        parameters: _FileBundleInitializationParameters
    ) throws {
        self = try _generatePlaceholder()
        
        if try !_initializeBackingObject(parameters: parameters) {
            return nil
        }
        
        do {
            try _load()
        } catch {
            runtimeIssue(error)
            
            return nil
        }
    }
    
    public init?(
        directory: URL,
        options: Set<FileDocumentReadOption> = [.createIfNeeded]
    ) throws {
        try self.init(
            parameters: .init(
                parent: nil,
                file: FileURL(directory),
                readOptions: options,
                owner: nil
            )
        )
    }
    
    public init!(
        directory: CanonicalFileDirectory,
        path: String
    ) throws {
        try self.init(directory: directory + path, options: [.createIfNeeded])
    }
}

private let _fileBundleObjectKey = ObjCAssociationKey<_FileBundleBackingObject?>()

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension FileBundle {
    var _fileBundleObject: _FileBundleBackingObject? {
        get {
            asObjCObject(self)[_fileBundleObjectKey]?.flatMap({ $0 })
        } set {
            asObjCObject(self)[_fileBundleObjectKey] = newValue
        }
    }
    
    public var _fileBundleURL: (any _FileOrFolderRepresenting)? {
        _fileBundleObject
    }
    
    private func _initializeFileBundleAnnotations(
        readOptions: Set<FileDocumentReadOption>
    ) throws -> Bool {
        guard let mirror = AnyNominalOrTupleMirror(self) else {
            assertionFailure()
            
            return false
        }
        
        for (field, value) in mirror {
            if let value = value as? _FileBundle_DynamicProperty {
                let initialized = try value._initialize(
                    with: .init(
                        enclosingInstance: self,
                        parent: _fileBundleObject!,
                        key: field.stringValue.dropPrefixIfPresent("_"),
                        readOptions: readOptions
                    )
                )
                
                guard initialized else {
                    if readOptions.contains(.createIfNeeded) {
                        throw _FileBundleError.annotationInitializationFailed
                    }
                    
                    return false
                }
            }
        }
        
        try _load()
        
        return true
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct _FileBundleInitializationParameters {
    let parent: (any FileBundle)?
    let file: any _FileOrFolderRepresenting
    let readOptions: Set<FileDocumentReadOption>
    let owner: (any _FileBundleContainerElement)?
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension FileBundle {
    func _initializeBackingObject(
        parameters: _FileBundleInitializationParameters
    ) throws -> Bool {
        if let file = parameters.file as? FileURL {
            _fileBundleObject = try _FileBundleBackingObject.Root(
                _enclosingInstance: self,
                directory: file,
                readOptions: parameters.readOptions
            )
            
            assert(parameters.owner == nil)
        } else {
            let file = try cast(parameters.file, to: _FileRepresentingFileWrapper<AnyHashable>.self)
            
            _fileBundleObject = try _FileBundleBackingObject.KeyedChild(
                _enclosingInstance: self,
                owner: parameters.owner,
                fileWrapper: file.base
            )
        }
        
        guard try _initializeFileBundleAnnotations(readOptions: parameters.readOptions) else {
            return false
        }
        
        return true
    }
}
