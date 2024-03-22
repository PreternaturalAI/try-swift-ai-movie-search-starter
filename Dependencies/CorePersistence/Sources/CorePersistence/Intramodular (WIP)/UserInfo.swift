//
// Copyright (c) Vatsal Manot
//

import _ModularDecodingEncoding
import Combine
import Swallow

public protocol _RawUserInfoProtocol: Hashable, Initiable, Sendable {
    
}

public enum _RawUserInfoKey: Codable, Hashable, @unchecked Sendable {
    case type(_SerializedTypeIdentity)
    case key(_SerializedTypeIdentity)
}

public struct _RawUserInfo: _RawUserInfoProtocol {
    typealias StorageKey = _UnsafelySerialized<_RawUserInfoKey>
    
    private var storage: [StorageKey: _HashableExistential<Any>] = [:]
    
    public init() {
        
    }
    
    public subscript<Value: Hashable>(
        _ type: Value.Type
    ) -> Value? {
        get {
            storage[_key(fromType: type)].map({ $0.wrappedValue as! Value })
        } set {
            if let newValue {
                storage[_key(fromType: type)] = _HashableExistential(wrappedValue: newValue)
            } else {
                storage[_key(fromType: type)] = nil
            }
        }
    }
    
    public mutating func assign<Value: Hashable>(
        _ value: Value
    ) {
        storage[_key(fromType: Swift.type(of: value))] = _HashableExistential(wrappedValue: value)
    }
    
    private func _key<Value: Hashable>(
        fromType type: Value.Type
    ) -> StorageKey {
        StorageKey(.type(.init(from: type)))
    }
}

// MARK: - Conformances

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension _RawUserInfo: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        
    }
}


public struct UserInfo: Hashable, Sendable {
    package let scope: Scope?
    package var storage = _RawUserInfo()
    
    public init(scope: Any.Type) {
        self.scope = .init(_swiftType: scope)
    }
    
    public init(unscoped: Void) {
        self.scope = nil
    }
}

extension UserInfo {
    public struct Scope: Hashable, Sendable {
        @_HashableExistential
        public var _swiftType: Any.Type
        
        public init(_swiftType: Any.Type) {
            self._swiftType = _swiftType
        }
    }
}
