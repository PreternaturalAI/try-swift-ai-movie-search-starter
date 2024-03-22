//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import FoundationX
import Swallow
import Runtime

public struct _ModularTopLevelDecoder<Input>: TopLevelDecoder, @unchecked Sendable {
    private let base: AnyTopLevelDecoder<Input>
    private var configuration: _ModularDecoder.Configuration
    
    public var plugins: [any _ModularCodingPlugin] {
        get {
            configuration.plugins
        } set {
            configuration.plugins = newValue
        }
    }
    
    public init<Decoder: TopLevelDecoder>(from decoder: Decoder) where Decoder.Input == Input {
        self.base = .init(erasing: decoder)
        self.configuration = .init()
    }
    
    public func decode<T>(
        _ type: T.Type,
        from input: Input
    ) throws -> T {
        try _ModularDecoder.TaskLocalValues.$configuration.withValue(configuration) {
            if let type = type as? _ModularTopLevelProxyDecodableType.Type {
                return try cast(
                    base.decode(
                        type,
                        from: input
                    ),
                    to: T.self
                )
            } else {
                return try base.decode(
                    _ModularDecoder.TopLevelProxyDecodable<T>.self,
                    from: input
                ).value
            }
        }
    }
}

fileprivate protocol _ModularDecodableProxyType: Decodable {
    
}

fileprivate protocol _ModularTopLevelProxyDecodableType: _ModularDecodableProxyType {
    
}

extension _ModularDecoder {
    /// A proxy for `Decodable` that forces our custom decoder to be used.
    fileprivate struct TopLevelProxyDecodable<T>: _ModularTopLevelProxyDecodableType {
        var value: T
    }
}

extension _ModularDecoder.TopLevelProxyDecodable {
    init(from _decoder: Decoder) throws {
        let type = T.self
        
        guard !(type is _ModularDecodableProxyType.Type) else {
            fatalError()
        }
        
        assert(!(_decoder is _ModularDecoder))
        
        let decoder = _ModularDecoder(
            base: _decoder,
            configuration: try _ModularDecoder.TaskLocalValues.configuration.unwrap(),
            context: .init(type: T.self)
        )
        
        try self.init(from: decoder)
    }
    
    private init(from decoder: _ModularDecoder) throws {
        func sanityCheckFunction() throws {
            guard let type = decoder.context.type, type == T.self else {
                assertionFailure()
                
                throw Never.Reason.illegal
            }
        }
        
        try sanityCheckFunction()
        
        if let type = (decoder.context.type as? any _UnsafelySerializedType.Type), TypeMetadata(type._opaque_WrappedValue).kind == .existentialMetatype {
            let plugin = try decoder.configuration.plugins
                .first(byUnwrapping: { $0 as? (any _MetatypeCodingPlugin) })
                .unwrap()
            
            let wrappedValue = try plugin._decode(Any.Type.self, from: decoder, context: .init())
            
            value = try cast(type.init(_opaque_wrappedValue: wrappedValue))
        } else if let type = decoder.context.type as? any _UnsafeSerializationRepresentable.Type, !(type is Decodable.Type) {
            value = try Self._decodeNonDecodableUnsafeSerializationRepresentable(
                type,
                from: decoder
            )
        } else if let type = decoder.context.type as? any (_UnsafelySerializedType & _UnsafeSerializationRepresentable).Type {
            value = try Self._decodeUnsafelySerializationPropertyWrappedUnsafeSerializationRepresentable(
                type,
                from: decoder
            )
        } else if let type = decoder.context.type as? (any Decodable.Type) {
            let discriminatedType: (any Decodable.Type)? = try Self.decodeDiscriminatedDecodableTypeIfAny(from: decoder)
            
            try Self._validatePluginSupportForConcreteType(type, decoder: decoder)
            
            if let discriminatedType {
                if let concreteType = type as? (any _UnsafelySerializedType.Type) {
                    value = try Self.decodeDiscriminatedType(
                        discriminatedType,
                        wrappingIn: concreteType,
                        from: decoder
                    )
                } else if type is _TypeSerializingAnyCodable.Type {
                    value = try Self.decodeDiscriminatedTypeAsTypeSerializedAnyCodable(
                        discriminatedType,
                        from: decoder
                    )
                } else {
                    value = try Self._naivelyDecode(discriminatedType, from: decoder)
                }
            } else if let type = type as? any _UnsafelySerializedType.Type {
                value = try Self._decodeUnsafelySerialized(type, from: decoder)
            } else {
                value = try Self._naivelyDecode(type, from: decoder)
            }
        } else {
            assertionFailure("Decoding failed: \(decoder.context)")
            
            throw Never.Reason.unexpected
        }
    }
    
    private static func _naivelyDecode(
        _ type: Decodable.Type,
        from decoder: _ModularDecoder
    ) throws -> T {
        do {
            let value = try type.init(from: decoder)
            
            return try cast(value, to: T.self)
        } catch let decodingError as Swift.DecodingError {
            throw _ModularDecodingError(
                from: decodingError,
                type: type,
                value: try? AnyCodable(from: decoder.base)
            )
        }
    }
    
    private static func _validatePluginSupportForConcreteType(
        _ concreteType: Any.Type,
        decoder: _ModularDecoder
    ) throws {
        if concreteType is (any _UnsafelySerializedType.Type) {
            let hasUnsafeSerializationPlugin = decoder.configuration.plugins.contains(where: {
                $0 is _UnsafeSerializationPlugin
            })
            
            let hasTypeDiscriminatorCodingPlugin = decoder.configuration.plugins.contains(where: {
                $0 is (any _TypeDiscriminatorCodingPlugin)
            })
            
            guard hasUnsafeSerializationPlugin || hasTypeDiscriminatorCodingPlugin else {
                throw _ModularDecodingError.unsafeSerializationUnsupported(concreteType)
            }
        }
    }
    
    private static func _decodeNonDecodableUnsafeSerializationRepresentable(
        _ type: any _UnsafeSerializationRepresentable.Type,
        from decoder: _ModularDecoder
    ) throws -> T {
        let _value: Any
        
        do {
            _value = try type._opaque_decodeThroughUnsafeSerializationRepresentation(
                from: decoder
            )
        } catch let decodingError as Swift.DecodingError {
            throw _ModularDecodingError(
                from: decodingError,
                type: type._opaque_UnsafeSerializationRepresentation,
                value: try? AnyCodable(from: decoder.base)
            )
        }
        
        return try cast(_value, to: T.self)
    }
    
    private static func _decodeUnsafelySerializationPropertyWrappedUnsafeSerializationRepresentable(
        _ type: any (_UnsafelySerializedType & _UnsafeSerializationRepresentable).Type,
        from decoder: _ModularDecoder
    ) throws -> T {
        let _value: Any
        
        do {
            do {
                _value = try type._opaque_decodeThroughUnsafeSerializationRepresentation(
                    from: decoder
                )
            } catch {
                if (try? decoder.singleValueContainer()._decodeUnsafelySerializedNil()) == true {
                    runtimeIssue("Attempting recovery from corruped `nil` value for \(type._opaque_WrappedValue).")
                    
                    _value = try _opaque_generatePlaceholder(ofType: type)
                } else {
                    throw error
                }
            }
        } catch let decodingError as Swift.DecodingError {
            throw _ModularDecodingError(
                from: decodingError,
                type: type._opaque_UnsafeSerializationRepresentation,
                value: try? AnyCodable(from: decoder.base)
            )
        }
        
        return try cast(_value, to: T.self)
    }
    
    private static func _decodeUnsafelySerialized(
        _ type: any _UnsafelySerializedType.Type,
        from decoder: _ModularDecoder
    ) throws -> T {
        if decoder.configuration.allowsUnsafeSerialization {
            do {
                return try cast(try type.init(from: decoder), to: T.self)
            } catch let decodingError as Swift.DecodingError {
                throw _ModularDecodingError(
                    from: decodingError,
                    type: type,
                    value: try? AnyCodable(from: decoder.base)
                )
            }
        } else {
            if let value = try? decoder.base.singleValueContainer()._decodeUnsafelySerializedNil(T.self) {
                return try cast(value, to: T.self)
            } else if let value = try? type.init(from: decoder) {                
                if let result = value as? T {
                    return result
                } else if let result = value.wrappedValue as? T {
                    runtimeIssue("This should never happen!")
                    
                    return result
                } else {
                    throw Never.Reason.unexpected
                }
            } else {
                throw _ModularDecodingError.unsafeSerializationUnsupported(type)
            }
        }
    }
    
    private static func decodeDiscriminatedType(
        _ discriminatedType: any Decodable.Type,
        wrappingIn concreteType: any _UnsafelySerializedType.Type,
        from decoder: _ModularDecoder
    ) throws -> T {
        let unwrappedValue: Decodable
        
        do {
            unwrappedValue = try discriminatedType.init(from: decoder)
        } catch let decodingError as Swift.DecodingError {
            throw _ModularDecodingError(
                from: decodingError,
                type: discriminatedType,
                value: try? AnyCodable(from: decoder.base)
            )
        }
        
        return try cast(concreteType.init(_opaque_wrappedValue: unwrappedValue), to: T.self)
    }
    
    private static func decodeDiscriminatedTypeAsTypeSerializedAnyCodable(
        _ type: Decodable.Type,
        from decoder: _ModularDecoder
    ) throws -> T {
        let value: Decodable
        
        do {
            value = try type.init(from: decoder)
        } catch let decodingError as Swift.DecodingError {
            throw _ModularDecodingError(
                from: decodingError,
                type: type,
                value: try? AnyCodable(from: decoder.base)
            )
        }
        
        guard !(value is _TypeSerializingAnyCodable) else {
            throw _AssertionFailure() // _TypeSerializingAnyCodable cannot be a discriminated type
        }
        
        return try cast(_TypeSerializingAnyCodable(value))
    }
    
    private static func decodeDiscriminatedDecodableTypeIfAny(
        from decoder: _ModularDecoder
    ) throws -> (any Decodable.Type)? {
        let pluginContext = _ModularCodingPluginContext() // FIXME: !!!
        
        guard let plugin = decoder.configuration.plugins.first(ofType: (any _TypeDiscriminatorCodingPlugin).self) else {
            return nil
        }
        
        guard let discriminator = try plugin.decode(from: decoder, context: pluginContext) else {
            return nil
        }
        
        guard let type = try plugin._opaque_resolveType(for: discriminator) else {
            return nil
        }
        
        guard let type = type as? Decodable.Type else {
            throw _AssertionFailure()
        }
        
        return type
    }
}

extension _ModularDecoder {
    struct SingleValueContainerProxyDecodable<T>: _ModularDecodableProxyType {
        let value: T
        
        init(from decoder: Decoder) throws {
            do {
                if let type = T.self as? any CoderPrimitive.Type {
                    self.value = try type.init(from: decoder) as! T
                    
                    return
                }
                
                let cycleDetected = _ModularDecoder.TaskLocalValues.isDecodingFromSingleValueContainer == true
                
                if cycleDetected {
                    let concreteType = try cast(T.self, to: (any Decodable.Type).self)
                    
                    self.value = try cast(try concreteType.init(from: decoder), to: T.self)
                } else {
                    self.value = try TaskLocalValues.$isDecodingFromSingleValueContainer.withValue(true) {
                        try _ModularDecoder.TopLevelProxyDecodable<T>(from: decoder).value
                    }
                }
            } catch let decodingError as Swift.DecodingError {
                throw decodingError
            }
        }
    }
}

extension _ModularDecoder {
    struct UnkeyedContainerProxyDecodable<T>: _ModularDecodableProxyType {
        let value: T
        
        init(from decoder: Decoder) throws {
            self.value = try TaskLocalValues.$isDecodingFromSingleValueContainer.withValue(nil) {
                do {
                    if let type = T.self as? any CoderPrimitive.Type {
                        return try type.init(from: decoder) as! T
                    }
                    
                    return try _ModularDecoder.TopLevelProxyDecodable<T>(from: decoder).value
                } catch let decodingError as Swift.DecodingError {
                    throw decodingError
                }
            }
        }
    }
}

extension _ModularDecoder {
    struct KeyedContainerProxyDecodable<T>: _ModularDecodableProxyType {
        let value: T
        
        init(from decoder: Decoder) throws {
            self.value = try TaskLocalValues.$isDecodingFromSingleValueContainer.withValue(nil) {
                do {
                    return try _ModularDecoder.TopLevelProxyDecodable<T>(from: decoder).value
                } catch let decodingError as Swift.DecodingError {
                    throw decodingError
                }
            }
        }
    }
}

// MARK: - Auxiliary

extension _ModularDecoder {
    fileprivate enum TaskLocalValues {
        @TaskLocal static var isDecodingFromSingleValueContainer: Bool?
        @TaskLocal static var configuration: _ModularDecoder.Configuration?
    }
}

// MARK: - Helpers

extension _TypeDiscriminatorCodingPlugin {
    public func _opaque_resolveType(for discriminator: Any) throws -> Any.Type? {
        try resolveType(for: try cast(discriminator, to: Discriminator.self))
    }
}

extension SingleValueDecodingContainer {
    public func _decodeUnsafelySerializedNil() throws -> Bool {
        if decodeNil() {
            return true
        }
        
        do {
            return try decode(_TypeSerializingAnyCodable.self).decodeNil()
        } catch {
            return try decode(AnyCodable.self)._dictionaryValue == [:]
        }
    }
    
    public func _decodeUnsafelySerializedNil<T>(
        _ type: T.Type
    ) throws -> T {
        guard try _decodeUnsafelySerializedNil() else {
            throw DecodingError.dataCorrupted(.init(codingPath: []))
        }
        
        let nilValue = try cast(type, to: ExpressibleByNilLiteral.Type.self).init(nilLiteral: ())
        
        return try cast(nilValue, to: type)
    }
}
