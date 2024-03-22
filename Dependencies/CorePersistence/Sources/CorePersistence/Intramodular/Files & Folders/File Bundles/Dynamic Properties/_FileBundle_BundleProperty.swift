//
// Copyright (c) Vatsal Manot
//

import Merge
import Runtime
import Swallow

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
@propertyWrapper
public final class _FileBundle_BundleProperty<Parent, Contents: FileBundle>: _FileBundle_DynamicProperty {
    public typealias _SelfType = _FileBundle_BundleProperty<Parent, Contents>
    
    typealias Configuration = _RelativeFolderConfiguration<Contents>
    typealias Base = _KeyedFileBundleChildBundle<Contents>
    
    private let configuration: (Parent) -> Configuration
    private var assignedValue: Contents?
    private var base: Base?
    
    @MainActor
    public var wrappedValue: Contents {
        get {
            try! base.unwrap().contents
        } set {
            _expectNoThrow {
                try base.unwrap().setContents(newValue)
            }
        }
    }
    
    init(
        configuration: @escaping (Parent) -> _RelativeFolderConfiguration<Contents>
    ) {
        self.configuration = configuration
    }
    
    @MainActor
    func _initialize(
        with parameters: InitializationParameters
    ) throws -> Bool {
        try _withLogicalParent(parameters.enclosingInstance.unwrap()) { enclosingInstance in
            guard let base = try _KeyedFileBundleChildBundle(
                parameters: parameters,
                configuration: { [weak enclosingInstance] in
                    let parent = try enclosingInstance.map({ try cast($0, to: Parent.self) }).unwrap()
                    
                    return self.configuration(parent)
                },
                uninitializedContents: assignedValue
            ) else {
                return false
            }
            
            self.base = base
            
            return true
        }
    }
}

// MARK: - Initializers

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension _FileBundle_BundleProperty {
    convenience init(
        configuration: _RelativeFolderConfiguration<Contents>
    ) {
        self.init(configuration: { _ in configuration })
    }
    
    convenience public init(
        _ path: String
    ) {
        self.init(
            configuration: .init(
                path: path,
                initialValue: nil
            )
        )
    }

    convenience public init(
        wrappedValue: Contents,
        _ path: String
    ) {
        self.init(
            configuration: .init(
                path: path,
                initialValue: wrappedValue
            )
        )
    }
}
