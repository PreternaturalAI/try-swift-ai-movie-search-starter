//
// Copyright (c) Vatsal Manot
//

import _CoreIdentity
import Foundation
import Diagnostics
import Swallow

public struct _DotNetTypeIdentifierCodingPlugin<ID: Codable & PersistentIdentifier>: _TypeDiscriminatorCodingPlugin, @unchecked Sendable {
    private enum CodingKeys: String, CodingKey {
        case type = "$type"
    }
    
    public typealias Discriminator = ID
    
    public let id: AnyHashable = UUID()
    
    private let _resolveTypeForDiscriminator: @Sendable (ID) throws -> Any.Type?
    private let _resolveDiscriminatorForType: @Sendable (Any.Type) throws -> ID?
    private let _decodeDiscriminator: @Sendable (Decoder) throws -> ID?
    private let _encodeDiscriminator: @Sendable (ID, Encoder) throws -> Void
    
    public func resolveType(
        for discriminator: ID
    ) throws -> Any.Type? {
        try _resolveTypeForDiscriminator(discriminator)
    }
    
    public func resolveDiscriminator(
        for type: Any.Type
    ) throws -> ID? {
        try _resolveDiscriminatorForType(type)
    }
    
    public func decode(
        from decoder: Decoder,
        context: Context
    ) throws -> ID? {
        try _decodeDiscriminator(decoder)
    }
    
    public func encode(
        _ discriminator: ID,
        to encoder: Encoder,
        context: Context
    ) throws  {
        try _encodeDiscriminator(discriminator, encoder)
    }
    
    public init<
        R0: _StaticSwiftTypeToPersistentIdentifierResolver,
        R1: _PersistentIdentifierToSwiftTypeResolver
    >(
        idResolver: R0,
        typeResolver: R1
    ) where R0.Output == ID, R1.Input == ID {
        self._resolveTypeForDiscriminator = { discriminator in
            _expectNoThrow {
                let type = try typeResolver.resolve(from: discriminator).unwrap().value
                
                return try cast(type, to: Decodable.Type.self)
            }
        }
        
        self._resolveDiscriminatorForType = { type in
            if let type = type as? R0.Input._Metatype {
                return try idResolver.resolve(from: R0.Input(type))
            } else {
                return nil
            }
        }
        
        self._decodeDiscriminator = { decoder in
            do {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                return try container.decodeIfPresent(Discriminator.self, forKey: .type)
            } catch let decodingError as Swift.DecodingError {
                switch decodingError {
                    case .typeMismatch:
                        return nil
                    default:
                        if (try? decoder.decodeNil()) == true {
                            return nil
                        }
                        
                        throw decodingError
                }
            }
        }
        
        self._encodeDiscriminator = { discriminator, encoder in
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(discriminator, forKey:.type)
        }
    }
}
