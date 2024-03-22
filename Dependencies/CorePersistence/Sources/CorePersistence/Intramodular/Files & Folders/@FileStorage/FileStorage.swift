//
// Copyright (c) Vatsal Manot
//

import Foundation
@_spi(Internal) import Merge
import Runtime
import Swallow

/// The strategy used to recover from a read error.
public enum _FileStorageReadErrorRecoveryStrategy: String, Codable, Hashable, Sendable {
    /// Halt the execution of the app.
    case fatalError
    /// Discard existing data (if any) and reset with the initial value.
    case discardAndReset
}

/// A property wrapper type that reflects data stored in a file on the disk.
///
/// The initial read is done asynchronously if possible, synchronously if the `wrappedValue` is accessed before the background read can complete.
///
/// Writing is done asynchronously on a high-priority background thread, and synchronously on the deinitialization of the internal storage of this property wrapper.
@propertyWrapper
public final class FileStorage<ValueType, UnwrappedType> {
    public typealias Coordinator = _AnyFileStorageCoordinator<ValueType, UnwrappedType>
    
    private let coordinator: Coordinator
    private var objectWillChangeConduit: AnyCancellable?
    
    public var wrappedValue: UnwrappedType {
        get {
            coordinator.wrappedValue
        } set {
            coordinator.wrappedValue = newValue
        }
    }
    
    public var projectedValue: FileStorage {
        self
    }
    
    public var url: URL {
        get throws {
            try coordinator.fileSystemResource._toURL()
        }
    }
    
    public static subscript<EnclosingSelf>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, UnwrappedType>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, FileStorage>
    ) -> UnwrappedType {
        get {
            instance[keyPath: storageKeyPath]._setUpEnclosingInstance(instance)
            
            return instance[keyPath: storageKeyPath].wrappedValue
        } set {
            instance[keyPath: storageKeyPath]._setUpEnclosingInstance(instance)
            
            _ObservableObject_objectWillChange_send(instance)
            
            instance[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
    
    fileprivate func _setUpEnclosingInstance<EnclosingSelf>(
        _ object: EnclosingSelf
    ) {
        guard let object = (object as? any ObservableObject) else {
            return
        }
        
        defer {
            self.coordinator._enclosingInstance = object
        }
        
        guard objectWillChangeConduit == nil else {
            return
        }
        
        if let objectWillChange = (object.objectWillChange as any Publisher) as? _opaque_VoidSender {
            objectWillChangeConduit = coordinator.objectWillChange
                .publish(to: objectWillChange)
                .sink()
        } else {
            assertionFailure()
        }
    }
    
    init(
        coordinator: @autoclosure () throws -> FileStorage.Coordinator
    ) {
        self.coordinator = try! coordinator()
    }
}

// MARK: - Extensions

extension FileStorage {
    public func commit() {
        coordinator.commit()
    }
}

// MARK: - Implemented Conformances

extension FileStorage: Publisher {
    public typealias Output = UnwrappedType
    public typealias Failure = Never
    
    public func receive<S: Subscriber<UnwrappedType, Never>>(subscriber: S) {
        coordinator.objectWillChange
            .compactMap({ [weak coordinator] in coordinator?.wrappedValue })
            .receive(subscriber: subscriber)
    }
}

// MARK: - Auxiliary

extension FileStorage {
    public typealias ReadErrorRecoveryStrategy = _FileStorageReadErrorRecoveryStrategy
}

public struct FileStorageOptions: Codable, ExpressibleByNilLiteral, Hashable {
    public typealias ReadErrorRecoveryStrategy = _FileStorageReadErrorRecoveryStrategy
    
    public var readErrorRecoveryStrategy: ReadErrorRecoveryStrategy?
    
    public init(
        readErrorRecoveryStrategy: ReadErrorRecoveryStrategy?
    ) {
        self.readErrorRecoveryStrategy = readErrorRecoveryStrategy
    }
    
    public init(nilLiteral: ()) {
        self.readErrorRecoveryStrategy = nil
    }
}

extension FileStorage: _FileOrFolderRepresenting {    
    public func _toURL() throws -> URL {
        try url
    }
    
    public func encode<T>(
        _ contents: T,
        using coder: _AnyConfiguredFileCoder
    ) throws {
        throw Never.Reason.illegal
    }
}
