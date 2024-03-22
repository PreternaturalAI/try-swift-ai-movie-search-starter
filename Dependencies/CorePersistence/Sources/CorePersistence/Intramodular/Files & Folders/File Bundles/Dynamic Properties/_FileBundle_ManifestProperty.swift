//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Runtime
import Swallow

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
@propertyWrapper
public final class _FileBundle_ManifestProperty<Value: Equatable & Sendable>: _FileBundle_DynamicProperty {
    public typealias _SelfType = _FileBundle_ManifestProperty<Value>
    
    private let configuration: _RelativeFileConfiguration<Value>
    private var base: _KeyedFileBundleChildGenericBase<Value>?
    
    @MainActor
    public var wrappedValue: Value {
        get {
            try! base.unwrap().contents
        } set {
            _expectNoThrow {
                try base.unwrap().setContents(newValue)
            }
        }
    }
    
    init(
        configuration: _RelativeFileConfiguration<Value>
    ) {
        self.configuration = configuration
    }
    
    func _initialize(
        with parameters: InitializationParameters
    ) throws -> Bool {
        guard let base = try _KeyedFileBundleChildFile(
            parameters: parameters,
            configuration: { self.configuration }
        ) else {
            return false
        }
        
        self.base = base
        
        return true
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension _FileBundle_ManifestProperty {
    convenience public init<Coder: TopLevelDataCoder>(
        wrappedValue: Value,
        _ path: String,
        coder: Coder,
        options: FileStorageOptions = nil
    ) where Value: Codable {
        self.init(
            configuration: try! _RelativeFileConfiguration(
                path: path,
                coder: .init(.topLevelDataCoder(coder, forType: Value.self)),
                readWriteOptions: options,
                initialValue: wrappedValue
            )
        )
    }
    
    convenience public init(
        wrappedValue: Value,
        _ path: String,
        options: FileStorageOptions = nil
    ) where Value: Codable {
        self.init(
            configuration: try! _RelativeFileConfiguration(
                path: path,
                coder: .init(.topLevelDataCoder(JSONCoder(), forType: Value.self)),
                readWriteOptions: options,
                initialValue: wrappedValue
            )
        )
    }
}
