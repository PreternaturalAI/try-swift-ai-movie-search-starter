//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import FoundationX
import Swallow

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension FileBundle {
    public typealias Children<Key: StringRepresentable, Value, WrappedValue> = _FileBundle_KeyedChildrenProperty<Key, Value, WrappedValue>
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
@propertyWrapper
public final class _FileBundle_KeyedChildrenProperty<Key: StringRepresentable, Value, WrappedValue>: _FileBundle_DynamicProperty {
    public typealias _SelfType = _FileBundle_KeyedChildrenProperty<Key, Value, WrappedValue>
    
    typealias Configuration = Base.Configuration
    typealias Base = _KeyedFileBundleChildren<Key, Value, WrappedValue>

    private let configuration: Configuration
    private var base: Base?
    
    @MainActor
    public var wrappedValue: [Key: Value] {
        get {
            _expectNoThrow {
                try base.unwrap().contents
            } ?? [:]
        } set {
            _expectNoThrow {
                let base = try self.base.unwrap()
                
                try base.setContents(newValue)
                
                try _tryAssert(base.contents.count == newValue.count)
            }
        }
    }
    
    init(
        configuration: Configuration
    ) {
        self.configuration = configuration
    }
    
    func _initialize(
        with parameters: InitializationParameters
    ) throws -> Bool {
        guard let base = try Base(
            parameters: parameters,
            configuration: configuration
        ) else {
            return false
        }
        
        self.base = base
        
        return true
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension _FileBundle_KeyedChildrenProperty {
    @MainActor
    convenience public init(
        wrappedValue: [Key: Value]? = nil,
        _ path: String
    ) where Value: FileBundle, WrappedValue == [Key: Value] {
        self.init(
            configuration: .init(
                folderConfiguration: .init(path: path, initialValue: nil),
                makeChild: { parameters in
                    try _KeyedFileBundleChildBundle(
                        parameters: .init(
                            enclosingInstance: parameters.enclosingInstance,
                            parent: parameters.parent,
                            key: parameters.key,
                            readOptions: parameters.readOptions
                        ),
                        configuration: { .init(path: nil, initialValue: nil) },
                        uninitializedContents: nil
                    )
                }
            )
        )
    }
}
