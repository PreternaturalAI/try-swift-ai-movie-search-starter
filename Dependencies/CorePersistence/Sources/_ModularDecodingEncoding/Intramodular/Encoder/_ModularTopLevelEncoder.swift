//
// Copyright (c) Vatsal Manot
//

import _CoreIdentity
import Combine
import FoundationX
import Swallow

public struct _ModularTopLevelEncoder<Output>: TopLevelEncoder, @unchecked Sendable {
    private let base: AnyTopLevelEncoder<Output>
    private var configuration: _ModularEncoder.Configuration
    
    public var plugins: [any _ModularCodingPlugin] {
        get {
            configuration.plugins
        } set {
            configuration.plugins = newValue
        }
    }
    
    public init<Encoder: TopLevelEncoder>(
        from encoder: Encoder
    ) where Encoder.Output == Output {
        self.base = AnyTopLevelEncoder(erasing: encoder)
        self.configuration = .init()
    }
    
    public func encode<T>(_ value: T) throws -> Output  {
        if let value = value as? _ModularTopLevelProxyEncodableType {
            return try base.encode(value)
        } else {
            return try base.encode(
                _ModularEncoder.TopLevelProxyEncodable<T>(
                    base: value,
                    encoderConfiguration: configuration
                )
            )
        }
    }
}

protocol _ModularTopLevelProxyEncodableType: Encodable {
    
}

extension _ModularEncoder {
    final class TopLevelProxyEncodable<Value>: _ModularTopLevelProxyEncodableType {
        private let base: Value
        private let isBaseUnwrapped: Bool?
        private let encoderConfiguration: _ModularEncoder.Configuration
        
        private var _requiresUnsafeSerialization: Bool? {
            if let wrappedType = Value.self as? any _UnsafelySerializedType.Type, !(wrappedType._opaque_WrappedValue.self is any Encodable.Type) {
                return true
            }
            
            return nil
        }
        
        private var _isKnownNil: Bool? {
            if _isValueNil(base) {
                return true
            }
            
            if let base = (base as? any _UnsafelySerializedType)?.wrappedValue {
                return _isValueNil(base)
            }
            
            return nil
        }
        
        init(
            base: Value,
            isBaseUnwrapped: Bool? = nil,
            encoderConfiguration: _ModularEncoder.Configuration
        ) {
            self.base = base
            self.isBaseUnwrapped = isBaseUnwrapped
            self.encoderConfiguration = encoderConfiguration
        }
        
        func encode(to encoder: Encoder) throws {
            do {
                assert(!(base is _ModularTopLevelProxyEncodableType))
                assert(!(encoder is _ModularEncoder))
                
                let wrappedEncoder = _ModularEncoder(
                    base: encoder,
                    configuration: encoderConfiguration,
                    context: .init(type: Value.self)
                )

                try encode(to: wrappedEncoder)
            } catch {
                throw error
            }
        }
        
        private func encode(
            to encoder: _ModularEncoder
        ) throws {
            let encoded: Bool
            let valueType: Any.Type = Swift.type(of: base)
            
            if !(base is Encodable), let base = base as? (any _UnsafeSerializationRepresentable) {
                try base._unsafeSerializationRepresentation.encode(to: encoder)
                
                encoded = true
            } else if let base = base as? (any _UnsafelySerializedType), base.wrappedValue is (any _UnsafeSerializationRepresentable)  {
                try base._opaque_encodeUnsafeSerializationRepresentable(
                    to: encoder.base,
                    encoderConfiguration: encoderConfiguration
                )
                
                encoded = true
            } else {
                if !(isBaseUnwrapped == true) && !(_requiresUnsafeSerialization == true) {
                    let unwrappedBase = _unwrapPossiblyTypeErasedValue(base)
                    
                    if let unwrappedBase, !(Value.self is any Encodable.Type) {
                        func _reifiedProxy<T>(for x: T) -> Encodable {
                            TopLevelProxyEncodable<T>(
                                base: x,
                                isBaseUnwrapped: true,
                                encoderConfiguration: encoderConfiguration
                            )
                        }
                        
                        let baseUnwrappedProxy = _openExistential(unwrappedBase, do: _reifiedProxy)
                        
                        try baseUnwrappedProxy.encode(to: encoder)
                        
                        encoded = true
                    } else {
                        try cast(base, to: (any Encodable).self).encode(to: encoder)
                        
                        encoded = true
                    }
                } else if _requiresUnsafeSerialization == true && _isKnownNil == true {
                    var container = encoder.singleValueContainer()
                    
                    try container.encodeNil()
                    
                    encoded = true
                } else {
                    if
                        let base = base as? (any _UnsafelySerializedType),
                        let unwrappedBase = base.wrappedValue as? Encodable
                    {
                        let encodedDiscriminator = (try? Self._encodeDiscriminator(for: __fixed_type(of: unwrappedBase), to: encoder)).compact() != nil
                        
                        if !encodedDiscriminator {
                            guard encoder.configuration.plugins.contains(where: { $0 is _UnsafeSerializationPlugin }) else {
                                throw _ModularDecodingError.unsafeSerializationUnsupported(valueType)
                            }
                        }
                        
                        try unwrappedBase.encode(to: encoder)
                        
                        encoded = true
                    } else if
                        let base = base as? (any _UnsafelySerializedType),
                        let unwrappedBase = base.wrappedValue as? Any.Type
                    {
                        let metatypePlugin = try encoder.configuration.plugins
                            .first(byUnwrapping: { $0 as? (any _MetatypeCodingPlugin) })
                            .unwrap()
                        
                        let encodedMetatype = try metatypePlugin.codableRepresentation(
                            for: unwrappedBase,
                            context: .init()
                        )
                        
                        try encodedMetatype.encode(to: encoder)
                        
                        encoded = true
                    } else if
                        let base = base as? _TypeSerializingAnyCodable,
                        let baseUnwrapped = try base.decode(),
                        try Self._encodeDiscriminator(for: __fixed_type(of: baseUnwrapped), to: encoder) != nil
                    {
                        try baseUnwrapped.encode(to: encoder)
                        
                        encoded = true
                    } else {
                        let _base = try cast(base, to: (any Encodable).self)
                        
                        try Self._encodeDiscriminator(
                            for: __fixed_type(of: _base),
                            to: encoder
                        )
                        
                        try _base.encode(to: encoder)
                        
                        encoded = true
                    }
                }
            }
            
            assert(encoded)
        }
        
        @discardableResult
        private static func _encodeDiscriminator(
            for type: Any.Type,
            to encoder: _ModularEncoder
        ) throws -> Any? {
            let pluginContext = _ModularCodingPluginContext()
            
            let concreteType = try ((try? cast(type, to: (any Encodable.Type).self)) ?? (type as? Encodable.Type)).unwrap()
            
            guard let typeDiscriminatorPlugin = encoder.configuration.plugins.first(ofType: (any _TypeDiscriminatorCodingPlugin).self) else {
                return nil
            }
            
            if let discriminator = try typeDiscriminatorPlugin.resolveDiscriminator(for: concreteType) {
                try typeDiscriminatorPlugin._opaque_encode(
                    discriminator,
                    to: encoder.disabling(typeDiscriminatorPlugin),
                    context: pluginContext
                )
                
                return discriminator
            } else {
                return nil
            }
        }
    }
}

extension _UnsafelySerializedType {
    fileprivate func _opaque_encodeUnsafeSerializationRepresentable(
        to encoder: Encoder,
        encoderConfiguration: _ModularEncoder.Configuration
    ) throws {
        assert(wrappedValue is (any _UnsafeSerializationRepresentable))
        
        try _ModularEncoder.TopLevelProxyEncodable(
            base: wrappedValue,
            encoderConfiguration: encoderConfiguration
        )
        .encode(to: encoder)
    }
}
