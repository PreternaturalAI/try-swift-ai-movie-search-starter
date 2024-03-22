//
// Copyright (c) Vatsal Manot
//

import Swift

@propertyWrapper
public struct _HashableExistential<Value>: PropertyWrapper {
    private var base: Value
    
    public var wrappedValue: Value {
        get {
            if base is _HashablePlaceholderNil {
                do {
                    return try _initializeNilLiteral(ofType: Value.self)
                } catch {
                    assertionFailure(error)
                    
                    return base
                }
            } else {
                return self.base
            }
        } set {
            self.base = newValue
        }
    }
    
    public var projectedValue: Self {
        self
    }
    
    public init(wrappedValue: Value) {
        try! self.init(_erasing: wrappedValue)
    }
    
    private static func _validate(_ value: Value) {
        guard !(value is _HashablePlaceholderNil) else {
            return
        }
        
        switch value {
            case is any Hashable:
                break
            case is Any.Type:
                break
            case is Void:
                break
            case is _HashablePlaceholderNil:
                break
            default:
                guard _isValueNil(value) else {
                    return
                }
                
                assertionFailure()
        }
    }
}

extension _HashableExistential {
    fileprivate enum InitializationError: Error {
        case unsupportedValue(Any)
    }
    
    fileprivate init(
        _wrappedValue: WrappedValue
    ) {
        self.base = _wrappedValue
    }
    
    @inline(never)
    fileprivate init(
        _erasing value: Any
    ) throws {
        switch value {
            case let value as any Hashable:
                self.init(_wrappedValue: value as! WrappedValue)
            case let value as Any.Type:
                self.init(_wrappedValue: value as! WrappedValue)
            case is Void:
                self.init(_wrappedValue: None() as! WrappedValue)
            default:
                if _isValueNil(value) {
                    switch Value.self {
                        case Any.self:
                            fatalError()
                        case Optional<Any>.self:
                            assert(!(value is Any.Type))
                            
                            self.init(_wrappedValue: _HashablePlaceholderNil() as! WrappedValue)
                        case Optional<Any.Type>.self:
                            assert(value is Optional<Any.Type>)
                            
                            self.init(_wrappedValue: value as! WrappedValue)
                        case Optional<Any.Protocol>.self:
                            assert(value is Optional<Any.Protocol>)
                            
                            self.init(_wrappedValue: value as! WrappedValue)
                        default:
                            if let _wrappedValue = _HashablePlaceholderNil() as? WrappedValue {
                                self.init(_wrappedValue: _wrappedValue)
                            } else {
                                self.init(_wrappedValue: value as! WrappedValue)
                            }
                    }
                    
                    if let placeholder = _HashablePlaceholderNil() as? WrappedValue {
                        self.init(_wrappedValue: placeholder)
                    } else {
                        self.init(_wrappedValue: value as! WrappedValue)
                    }
                } else {
                    throw InitializationError.unsupportedValue(value)
                }
        }
    }

    @_disfavoredOverload
    public init(
        erasing value: Any
    ) throws where Value == any Hashable {
        try self.init(_erasing: value)
    }
}

// MARK: - Conformances

extension _HashableExistential: CustomStringConvertible {
    public var description: String {
        String(describing: wrappedValue)
    }
}

extension _HashableExistential: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard type(of: lhs.base) == type(of: rhs.base) else {
            assert(!AnyEquatable.equate(lhs.base, rhs.base))
            
            return false
        }
        
        return AnyEquatable.equate(lhs.base, rhs.base)
    }
}

extension _HashableExistential: Hashable {
    public func hash(into hasher: inout Hasher) {
        if WrappedValue.self == Optional<Any.Type>.self {
            hasher.combine((base as! Optional<Any.Type>).map({ Metatype<Any.Type>($0) }))
        } else if let base = base as? None {
            hasher.combine(base)
        } else if let base = base as? _HashablePlaceholderNil {
            hasher.combine(base)
        } else if let base = base as? Any.Type {
            ObjectIdentifier(base).hash(into: &hasher)
        } else if let base = base as? (any Hashable) {
            hasher.combine(ObjectIdentifier(type(of: base)))
            hasher.combine(base)
        } else if swift_isClassType(type(of: base)), let base = try? cast(base, to: AnyObject.self) {
            hasher.combine(ObjectIdentifier(type(of: base)))
            hasher.combine(ObjectIdentifier(base))
        } else {
            if _isValueNil(base) {
                _HashablePlaceholderNil().hash(into: &hasher)
            } else if base is Void {
                hasher.combine(None())
            } else {
                assertionFailure("unsupported type \(type(of: base))")
            }
        }
    }
}

extension _HashableExistential: @unchecked Sendable {
    
}

// MARK: - Auxiliary

public protocol _UnsafeHashable {
    func _unsafelyHash(into hasher: inout Hasher) throws
}

extension HeterogeneousDictionary: _UnsafeHashable {
    public func _unsafelyHash(into hasher: inout Hasher) throws {
        try storage.mapValues({ try _HashableExistential(erasing: $0) }).hash(into: &hasher)
    }
}

extension _HashableExistential {
    fileprivate struct _HashablePlaceholderNil: ExpressibleByNilLiteral, Hashable, Sendable {
        init() {
            
        }
        
        init(nilLiteral: ()) {
            self.init()
        }
    }
}

public struct _TypeHashingAnyHashable: Hashable, _UnwrappableHashableTypeEraser {
    private let _base: AnyHashable
    
    public var base: any Hashable {
        _base.base as! (any Hashable)
    }
    
    public init<H: Hashable>(_ base: H) {
        self._base = AnyHashable(base)
    }
    
    public init(_erasing base: any Hashable) {
        self = base._eraseToTypeHashingAnyHashable()
    }
    
    public func _unwrapBase() -> _UnwrappedBaseType {
        base
    }
        
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(type(of: _base.base)))
        hasher.combine(_base)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard type(of: lhs._base.base) == type(of: rhs._base.base) else {
            return false
        }
        
        return rhs._base == lhs._base
    }
}

extension Hashable {
    public func _eraseToTypeHashingAnyHashable() -> _TypeHashingAnyHashable {
        _TypeHashingAnyHashable(self)
    }
}
