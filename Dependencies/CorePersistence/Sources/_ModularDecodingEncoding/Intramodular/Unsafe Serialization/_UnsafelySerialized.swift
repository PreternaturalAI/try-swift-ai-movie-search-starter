//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Runtime
import Swallow

public typealias _UnsafelySerializedAny = _UnsafelySerialized<Any>

/// A protocol for the property wrapper `@_UnsafelySerialized`.
public protocol _UnsafelySerializedType: Codable, ParameterlessPropertyWrapper {
    
}

@propertyWrapper
public struct _UnsafelySerialized<Value>: _UnsafelySerializedType, ParameterlessPropertyWrapper {
    public var wrappedValue: Value
    private var _cachedHashValue: Int?
    
    private init(wrappedValue: Value, _cachedHashValue: Int?) {
        self.wrappedValue = wrappedValue
        self._cachedHashValue = _cachedHashValue
    }
    
    public init(wrappedValue: Value)  {
        if wrappedValue is (any _UnsafelySerializedType) {
            assertionFailure()
        }
        
        if Value.self == Any.self {
            guard let _value = Optional(_unwrapping: wrappedValue) else {
                self.wrappedValue = EmptyValue() as! Value
                
                assertionFailure()
                
                return
            }
            
            self.wrappedValue = _value as! Value
        } else {
            self.wrappedValue = wrappedValue
        }
        
        _recomputeCachedHashValue()
    }
    
    public init(_ value: Value) {
        self.init(wrappedValue: value)
    }
    
    public enum _Error: Error {
        case failedToHashValue(Value)
    }
}

// MARK: - Conformances

extension _UnsafelySerialized: Codable {
    public init(from decoder: Decoder) throws {
        let intermediate = try _IntermediateRepresentation(from: decoder)
        
        try self.init(
            wrappedValue: intermediate.value,
            _cachedHashValue: intermediate.hashValue
        )
        
        if wrappedValue is any _UnsafelySerializedType {
            assertionFailure()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        let intermediateRepresentation = try _IntermediateRepresentation(wrappedValue)
        
        try intermediateRepresentation.encode(to: encoder)
    }
}

extension _UnsafelySerialized: CustomStringConvertible {
    public var description: String {
        let type = "\(Swift.type(of: wrappedValue))"
        
        if (Value.self is any OptionalProtocol.Type) {
            return "[unsafely serialized \(type)] \(wrappedValue)"
        } else {
            if let value = Optional(_unwrapping: wrappedValue) {
                return "[unsafely serialized \(type)] \(value)"
            } else {
                return "[unsafely serialized \(type)] \(wrappedValue)"
            }
        }
    }
}

extension _UnsafelySerialized: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        if let _lhsHashValue = lhs._cachedHashValue, let _rhsHashValue = rhs._cachedHashValue {
            return _lhsHashValue == _rhsHashValue
        }
        
        do {
            let _lhs = try _IntermediateRepresentation(lhs.wrappedValue)
            let _rhs = try _IntermediateRepresentation(rhs.wrappedValue)
            
            return _lhs == _rhs
        } catch {
            assertionFailure(error)
            
            return false
        }
    }
}

extension _UnsafelySerialized: Hashable {
    public func hash(into hasher: inout Hasher) {
        do {
            try _hash(into: &hasher)
        } catch {
            assertionFailure(error)
        }
    }
    
    fileprivate func _hash(into hasher: inout Hasher) throws  {
        do {
            if let wrappedValue = wrappedValue as? any Hashable {
                hasher.combine(wrappedValue)
            } else if let wrappedValue = wrappedValue as? _UnsafeHashable {
                try wrappedValue._unsafelyHash(into: &hasher)
            } else {
                do {
                    hasher.combine(try _IntermediateRepresentation(wrappedValue))
                } catch {
                    if let wrappedValue = wrappedValue as? (any _UnsafeSerializationRepresentable) {
                        try wrappedValue._unsafeSerializationRepresentation.hash(into: &hasher)
                    } else {
                        throw error
                    }
                }
            }
        } catch {
            XcodeRuntimeIssueLogger.default.error(_Error.failedToHashValue(wrappedValue))
            
            throw error
        }
    }
    
    fileprivate mutating func _recomputeCachedHashValue() {
        _cachedHashValue = self.hashValue
    }
}

extension _UnsafelySerialized: @unchecked Sendable {
    
}

extension _UnsafelySerialized: ExpressibleByNilLiteral where Value: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.init(.init(nilLiteral: ()))
    }
}

extension _UnsafelySerialized: Initiable where Value: Initiable {
    public init() {
        self.init(Value.init())
    }
}

// MARK: - Auxiliary

extension _UnsafelySerialized {
    private enum _IntermediateRepresentation: Codable, Hashable {
        case metatype(_SerializedTypeIdentity?)
        case representable(any Hashable & Codable)
        case anything(_TypeSerializingAnyCodable)
        
        /// Whether this `_UnsafelySerialized` is representing a metatype.
        private static var isMetatypeContainer: Bool? {
            let valueType = Metatype(Value.self).unwrapped
            
            guard !valueType._isAnyOrNever() else {
                return false
            }
            
            return valueType._isTypeOfType
        }
        
        var value: Value {
            get throws {
                switch self {
                    case .metatype(let value):
                        return try cast(try value?.resolveType(), to: Value.self)
                    case .representable(let value):
                        let valueType = try cast(Value.self, to: (any _UnsafeSerializationRepresentable.Type).self)
                        
                        return try cast(valueType.init(_opaque_unsafeSerializationRepresentation: value), to: Value.self)
                    case .anything(let value):
                        return try value.decode(Value.self)
                }
            }
        }
        
        init(_ value: Any) throws {
            let declaredValueType = Metatype(Value.self)
            
            if let isMetatype = Self.isMetatypeContainer, isMetatype {
                let value = try _unwrapPossiblyTypeErasedValue(value)
                    .map({ try cast($0, to: Any.Type.self) })
                    .map(_SerializedTypeIdentity.init(_fromUnwrappedType:))
                
                if value == nil {
                    try _tryAssert(_isTypeOptionalType(Value.self))
                }
                
                self = .metatype(value)
            } else if let value = value as? any _UnsafeSerializationRepresentable {
                assert(Value.self is any _UnsafeSerializationRepresentable.Type)
                
                self = try .representable(value._unsafeSerializationRepresentation)
            } else if let type = value as? Any.Type {
                assert(declaredValueType._isAnyOrNever(unwrapIfNeeded: true))
                
                self = .metatype(_SerializedTypeIdentity(from: type))
            } else {
                self = try .anything(_TypeSerializingAnyCodable(value))
            }
        }
        
        private init(_ value: Either<_SerializedTypeIdentity, _TypeSerializingAnyCodable>) {
            switch value {
                case .left(let type):
                    self = .metatype(type)
                case .right(let x):
                    self = .anything(x)
            }
        }
        
        init(from decoder: Decoder) throws {
            if Self.isMetatypeContainer == true {
                do {
                    self = try .metatype(Optional<_SerializedTypeIdentity>(from: decoder))
                } catch {
                    throw error
                }
            } else {
                do {
                    switch Value.self {
                        case let valueType as any _UnsafeSerializationRepresentable.Type:
                            do {
                                self = .representable(try valueType._opaque_decodeUnsafeSerializationRepresentation(from: decoder))
                            } catch {
                                throw error
                            }
                        default:
                            do {
                                self = try .anything(_TypeSerializingAnyCodable(from: decoder))
                            } catch {
                                throw error
                            }
                    }
                } catch(let error) {
                    let container: SingleValueDecodingContainer
                    
                    do {
                        container = try decoder.singleValueContainer()
                    } catch(_) {
                        throw error
                    }
                    
                    if container.decodeNil() {
                        throw error
                    }
                    
                    do {
                        self = try .metatype(container.decode(_SerializedTypeIdentity.self))
                    } catch(_) {
                        throw error
                    }
                }
            }
        }
        
        func encode(to encoder: Encoder) throws {
            switch self {
                case .metatype(let value):
                    try value.encode(to: encoder)
                case .representable(let value):
                    try value.encode(to: encoder)
                case .anything(let value):
                    try value.encode(to: encoder)
            }
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
                case (.metatype(let lhs), .metatype(let rhs)):
                    return lhs == rhs
                case (.representable(let lhs), .representable(let rhs)):
                    return lhs.eraseToAnyHashable() == rhs.eraseToAnyHashable()
                case (.anything(let lhs), .anything(let rhs)):
                    return lhs == rhs
                default:
                    return false
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
                case .metatype(let value):
                    value.hash(into: &hasher)
                case .representable(let value):
                    value.hash(into: &hasher)
                case .anything(let value):
                    value.hash(into: &hasher)
            }
        }
    }
}

extension _UnsafelySerialized: _UnsafeSerializationRepresentable where Value: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = Value._UnsafeSerializationRepresentation
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try wrappedValue._unsafeSerializationRepresentation
        }
    }
    
    init(
        _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation
    ) throws {
        self.init(wrappedValue: try .init(_unsafeSerializationRepresentation: _unsafeSerializationRepresentation))
    }
}

// MARK: - Decoding & Encoding

extension KeyedDecodingContainer {
    public func decode<T>(
        _ type: _UnsafelySerialized<Optional<T>>.Type,
        forKey key: Key
    ) throws -> _UnsafelySerialized<Optional<T>> {
        try decodeIfPresent(
            type,
            forKey: key
        ) ?? .init(wrappedValue: nil)
    }
}

// MARK: - Supplementary

extension KeyedDecodingContainerProtocol {
    @_disfavoredOverload
    public func decode<T>(
        _ type: T.Type = T.self,
        forKey key: Key
    ) throws -> _UnsafelySerialized<T> {
        try decode(
            _UnsafelySerialized<T>.self,
            forKey: key
        )
    }
    
    @_disfavoredOverload
    public func decodeIfPresent<T>(
        _ type: T.Type = T.self,
        forKey key: Key
    ) throws -> _UnsafelySerialized<T?> {
        try _UnsafelySerialized(
            wrappedValue: decode(_UnsafelySerialized<T?>.self, forKey: key).wrappedValue
        )
    }
    
    @_disfavoredOverload
    public func decode<T>(
        _ type: T.Type = T.self,
        forKey key: Key,
        default defaultValue: @autoclosure () -> T
    ) throws -> _UnsafelySerialized<T> {
        try decodeIfPresent(
            _UnsafelySerialized<T>.self,
            forKey: key
        ) ?? _UnsafelySerialized(defaultValue())
    }
}
