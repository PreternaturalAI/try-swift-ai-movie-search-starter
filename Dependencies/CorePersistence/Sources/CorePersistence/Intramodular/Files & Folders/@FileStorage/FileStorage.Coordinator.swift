//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow

/// A namespace for @FileStorage coordinator implementations.
public enum _FileStorageCoordinators: _StaticNamespaceType {
    
}

public class _AnyFileStorageCoordinator<ValueType, UnwrappedValue>: ObservableObject, @unchecked Sendable {
    public enum StateFlag {
        case initialReadComplete
        case latestWritten
        case discarded
    }
    
    weak var _enclosingInstance: AnyObject? {
        didSet {
            guard !(_enclosingInstance === oldValue) else {
                return
            }
            
            if let _enclosingInstance = _enclosingInstance as? (any PersistenceRepresentable) {
                _persistenceContext.persistenceRepresentationResolutionContext.sourceList.insert(Weak(wrappedValue: _enclosingInstance))
            }
        }
    }
    
    let _persistenceContext = _PersistenceContext(for: ValueType.self)
    let cancellables = Cancellables()
    let lock = OSUnfairLock()
    
    public internal(set) var stateFlags: Set<StateFlag> = []

    let writeQueue = DispatchQueue(
        label: "com.vmanot.Data.FileStorage.Coordinator.write",
        qos: .default
    )
    
    var fileSystemResource: any _FileOrFolderRepresenting
    let configuration: _RelativeFileConfiguration<UnwrappedValue>
    
    @MainActor(unsafe)
    open var wrappedValue: UnwrappedValue {
        get {
            fatalError(.abstract)
        } set {
            fatalError(.abstract)
        }
    }
    
    @MainActor
    init(
        fileSystemResource: any _FileOrFolderRepresenting,
        configuration: _RelativeFileConfiguration<UnwrappedValue>
    ) throws {
        self.fileSystemResource = fileSystemResource
        self.configuration = configuration
    }
    
    open func commit() {
        fatalError(.abstract)
    }
    
    open func discard() {
        guard !stateFlags.contains(.discarded) else {
            return
        }
        
        stateFlags.insert(.discarded)
    }
    
    deinit {
        guard !stateFlags.contains(.discarded) else {
            return
        }

        commit()
    }
}

// MARK: - Initializers

extension _FileStorageCoordinators.RegularFile {
    @MainActor
    convenience init(
        initialValue: UnwrappedValue?,
        file: any _FileOrFolderRepresenting,
        coder: _AnyConfiguredFileCoder,
        options: FileStorageOptions
    ) throws {
        try self.init(
            fileSystemResource: file,
            configuration: try! _RelativeFileConfiguration(
                path: nil,
                coder: coder,
                readWriteOptions: options,
                initialValue: initialValue
            ),
            cache: InMemorySingleValueCache()
        )
    }
}
