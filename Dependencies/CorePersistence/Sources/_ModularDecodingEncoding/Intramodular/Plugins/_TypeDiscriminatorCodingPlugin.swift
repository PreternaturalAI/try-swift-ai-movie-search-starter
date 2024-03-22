//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol _MetatypeCodingPlugin: _ModularCodingPlugin {
    associatedtype CodableRepresentation: Codable
    
    func codableRepresentation(
        for type: Any.Type,
        context: Context
    ) throws -> CodableRepresentation
    
    func type(
        from codableRepresentation: CodableRepresentation,
        context: Context
    ) throws -> Any.Type
}

public protocol _TypeDiscriminatorCodingPlugin: _ModularCodingPlugin {
    associatedtype Discriminator: Hashable
    
    func resolveType(for discriminator: Discriminator) throws -> Any.Type?
    func resolveDiscriminator(for type: Any.Type) throws -> Discriminator?
    
    func decode(
        from _: Decoder,
        context: Context
    ) throws -> Discriminator?
    
    func encode(
        _ discriminator: Discriminator,
        to encoder: Encoder,
        context: Context
    ) throws
}

extension _TypeDiscriminatorCodingPlugin {
    func _opaque_encode(
        _ discriminator: Any,
        to encoder: Encoder,
        context: Context
    ) throws {
        try encode(
            cast(discriminator, to: Discriminator.self),
            to: encoder,
            context: context
        )
    }
}

extension _MetatypeCodingPlugin {
    func _decode<T>(
        _ type: T.Type,
        from decoder: _ModularDecoder,
        context: _ModularCodingPluginContext
    ) throws -> T {
        try cast(self.type(from: try CodableRepresentation(from: decoder), context: context), to: T.self)
    }
}
