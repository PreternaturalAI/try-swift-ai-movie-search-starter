//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Combine
import Foundation
import Swallow

extension Decodable {
    public typealias TypeDiscriminated<D: TypeDiscriminator> = _TypeDiscriminatedCoding<D>
}

@propertyWrapper
public struct _TypeDiscriminatedCoding<Discriminator: TypeDiscriminator>: PropertyWrapper {
    public typealias WrappedValue = Discriminator._DiscriminatedSwiftType._Type
    
    public var wrappedValue: WrappedValue
    
    public init(wrappedValue: WrappedValue) {
        self.wrappedValue = wrappedValue
    }
    
    public init(
        wrappedValue: WrappedValue,
        by _: Discriminator.Type
    ) {
        self.wrappedValue = wrappedValue
    }
    
    struct _EncodeDecodeImpl {
        let encode: (WrappedValue, Encoder) throws -> Void
        let decode: (Decoder) throws -> WrappedValue
    }
    
    static func _makeEncodeDecodeImpl() throws -> _EncodeDecodeImpl {
        if let type = WrappedValue.self as? any (Codable & PolymorphicDecodable).Type {
            return _EncodeDecodeImpl(
                encode: { value, encoder in
                    try cast(value, to: Encodable.self).encode(to: encoder)
                },
                decode: { decoder in
                    try cast(type._opaque_polymorphicDecodingProxy().init(from: decoder).value, to: WrappedValue.self.self)
                }
            )
        } else if Discriminator.self is Codable.Type {
            if let discriminatorType = Discriminator.self as? any CaseIterable.Type {
                let allCases = try (discriminatorType.allCases as any Collection).map({ try cast($0, to: Discriminator.self) })
                
                try allCases.forEach({ try _tryAssert(try $0.resolveType() is Codable.Type) })
            }
            
            return _EncodeDecodeImpl(
                encode: { value, encoder in
                    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                        try _TypeDiscriminatedContainerForCodableDiscriminatorCodableValue(
                            type: try cast(value, to: (any TypeDiscriminable<Discriminator>).self).typeDiscriminator,
                            data: value
                        )
                        .encode(to: encoder)
                    } else {
                        throw _PlaceholderError()
                    }
                },
                decode: { decoder in
                    try _TypeDiscriminatedContainerForCodableDiscriminatorCodableValue(from: decoder).data
                }
            )
        } else {
            throw _PlaceholderError()
        }
    }
}

// MARK: - Conformances

extension _TypeDiscriminatedCoding: Codable {
    public init(from decoder: Decoder) throws {
        self.init(wrappedValue: try Self._makeEncodeDecodeImpl().decode(decoder))
    }
    
    public func encode(to encoder: Encoder) throws {
        try Self._makeEncodeDecodeImpl().encode(wrappedValue, encoder)
    }
}

extension _TypeDiscriminatedCoding: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        _HashableExistential(wrappedValue: lhs.wrappedValue) == _HashableExistential(wrappedValue: rhs.wrappedValue)
    }
}

extension _TypeDiscriminatedCoding: Hashable  {
    public func hash(into hasher: inout Hasher) {
        _HashableExistential(wrappedValue: wrappedValue).hash(into: &hasher)
    }
}

extension _TypeDiscriminatedCoding: @unchecked Sendable {
    
}

// MARK: - Auxiliary

extension _TypeDiscriminatedCoding {
    public struct _TypeDiscriminatedContainerForCodableDiscriminatorCodableValue: Codable {
        public enum CodingKeys: String, CodingKey {
            case type = "type"
            case data = "data"
        }
        
        public let type: Discriminator
        public let data: Discriminator._DiscriminatedSwiftType._Type
        
        public init(
            type: Discriminator,
            data: Discriminator._DiscriminatedSwiftType._Type
        ) {
            self.type = type
            self.data = data
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.type = try container._attemptToDecode(opaque: Discriminator.self, forKey: .type)
            self.data = try cast(container._attemptToDecode(opaque: type.resolveType() as! Any.Type, forKey: .data))
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container._attemptToEncode(opaque: type, forKey: .type)
            try container._attemptToEncode(opaque: data, forKey: .data)
        }
    }
}
