//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Runtime
import Swallow

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
@propertyWrapper
public final class _FileBundle_KeyedFileProperty<Parent, Contents>: _FileBundle_DynamicProperty {
    public typealias _SelfType = _FileBundle_KeyedFileProperty<Parent, Contents>
    
    typealias Configuration = _RelativeFileConfiguration<Contents>
    typealias Base = _KeyedFileBundleChildGenericBase<Contents>
    
    private let configuration: (Parent) -> _RelativeFileConfiguration<Contents>    
    private var initialValue: Contents?
    private var assignedValue: Contents?
    private var base: Base?
    
    @MainActor
    public var wrappedValue: Contents {
        get {
            if let base {
                return try! base.contents
            } else {
                if let assignedValue {
                    return assignedValue
                } else {
                    return initialValue!
                }
            }
        } set {
            if let base {
                _expectNoThrow {
                    try base.setContents(newValue)
                }
            } else {
                assignedValue = newValue
            }
        }
    }
    
    init(
        configuration: @escaping (Parent) -> _RelativeFileConfiguration<Contents>
    ) {
        self.configuration = configuration
    }
    
    convenience init(
        configuration: _RelativeFileConfiguration<Contents>,
        initialValue: Contents?
    ) {
        self.init(configuration: { _ in configuration })
        
        self.initialValue = initialValue
    }
    
    func _initialize(
        with parameters: InitializationParameters
    ) throws -> Bool {
        guard let base = try _KeyedFileBundleChildFile(
            parameters: parameters,
            configuration: _makeConfigurationBuilder(enclosingInstance: parameters.enclosingInstance)
        ) else {
            return false
        }
        
        self.base = base
        
        return true
    }
    
    private func _makeConfigurationBuilder(
        enclosingInstance: (any FileBundle)?
    ) -> () throws -> _RelativeFileConfiguration<Contents> {
        return { [weak self, weak enclosingInstance] () -> _RelativeFileConfiguration<Contents> in
            let `self` = try self.unwrap()
            let parent = try enclosingInstance.map({ try cast($0, to: Parent.self) }).unwrap()
            let configuration = self.configuration(parent)
            
            if let assignedValue = self.assignedValue {
                configuration.serialization.initialValue = .init(assignedValue)
            }
            
            return configuration
        }
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension _FileBundle_KeyedFileProperty {
    convenience public init(
        wrappedValue: Contents,
        _ path: String,
        options: FileStorageOptions = nil
    ) where Contents: _FileDocumentProtocol {
        self.init(
            configuration: try! _RelativeFileConfiguration(
                path: path,
                coder: .init(Contents.self),
                readWriteOptions: options,
                initialValue: wrappedValue
            ),
            initialValue: wrappedValue
        )
    }
    
    convenience public init(
        _ path: String,
        options: FileStorageOptions = nil
    ) where Contents: _FileDocumentProtocol & Initiable {
        let initialValue = Contents()
        
        self.init(
            configuration: try! _RelativeFileConfiguration(
                path: path,
                coder: .init(Contents.self),
                readWriteOptions: options,
                initialValue: initialValue
            ),
            initialValue: initialValue
        )
    }
    
    convenience public init(
        wrappedValue: Contents? = nil,
        _ path: String,
        options: FileStorageOptions = nil
    ) where Contents: Initiable, Contents: _FileDocumentProtocol {
        self.init(
            configuration: try! _RelativeFileConfiguration(
                path: path,
                coder: .init(Contents.self),
                readWriteOptions: options,
                initialValue: wrappedValue ?? .init()
            ),
            initialValue: wrappedValue
        )
    }
    
    convenience public init(
        wrappedValue: Contents = .init(nilLiteral: ()),
        _ path: String,
        options: FileStorageOptions = nil
    ) where Contents: OptionalProtocol, Contents.Wrapped: _FileDocumentProtocol {
        self.init(
            configuration: try! _RelativeFileConfiguration(
                path: path,
                coder: .init(Contents.Wrapped.self),
                readWriteOptions: options,
                initialValue: wrappedValue
            ),
            initialValue: wrappedValue
        )
    }
    
    convenience public init<Coder: TopLevelDataCoder>(
        wrappedValue: Contents,
        _ path: String,
        coder: Coder,
        options: FileStorageOptions = nil
    ) where Contents: Codable {
        self.init(
            configuration: try! _RelativeFileConfiguration(
                path: path,
                coder: .init(.topLevelDataCoder(coder, forType: Contents.self)),
                readWriteOptions: options,
                initialValue: wrappedValue
            ),
            initialValue: wrappedValue
        )
    }
    
    convenience public init<Coder: TopLevelDataCoder>(
        _ path: String,
        coder: Coder,
        options: FileStorageOptions = nil
    ) where Contents: Codable & Initiable {
        let initialValue = Contents()
        
        self.init(
            configuration: try! _RelativeFileConfiguration(
                path: path,
                coder: .init(.topLevelDataCoder(coder, forType: Contents.self)),
                readWriteOptions: options,
                initialValue: initialValue
            ),
            initialValue: initialValue
        )
    }
    
    convenience public init(
        wrappedValue: Contents,
        _ path: String,
        options: FileStorageOptions = nil
    ) where Contents: Codable {
        self.init(
            configuration: try! _RelativeFileConfiguration(
                path: path,
                readWriteOptions: options,
                initialValue: wrappedValue
            ),
            initialValue: wrappedValue
        )
    }
    
    convenience public init(
        _ path: String,
        options: FileStorageOptions = nil
    ) where Contents: Codable & Initiable {
        let initialValue = Contents()
        
        self.init(
            configuration: try! _RelativeFileConfiguration(
                path: path,
                readWriteOptions: options,
                initialValue: initialValue
            ),
            initialValue: initialValue
        )
    }
    
    convenience public init(
        _ path: String,
        options: FileStorageOptions = nil
    ) where Contents: Codable & ExpressibleByNilLiteral {
        let initialValue = Contents(nilLiteral: ())
        
        self.init(
            configuration: try! _RelativeFileConfiguration(
                path: path,
                readWriteOptions: options,
                initialValue: initialValue
            ),
            initialValue: initialValue
        )
    }
}
