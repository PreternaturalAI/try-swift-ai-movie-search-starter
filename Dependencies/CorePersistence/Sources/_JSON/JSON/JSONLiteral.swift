//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

/// A property wrapper that encodes its value as stringified JSON.
@propertyWrapper
public struct JSONStringified<Value: Decodable> {
    private static var decoder: JSONDecoder {
        .init()
    }
    
    private static var encoder: JSONEncoder {
        .init()
    }
    
    public let wrappedValue: Value
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}

// MARK: - Conformances

extension JSONStringified: Codable where Value: Codable {
    public init(from decoder: Decoder) throws {
        let string = try String(from: decoder)
        let data = try string.data(using: .utf8).unwrap()
        
        self.init(wrappedValue: try Self.decoder.decode(Value.self, from: data))
    }
    
    public func encode(to encoder: Encoder) throws {
        let data = try Self.encoder.encode(wrappedValue)
        
        let string = try String(data: data, encoding: .utf8).unwrap()
        
        var container = encoder.singleValueContainer()
        
        try container.encode(string)
    }
}

extension JSONStringified: Equatable where Value: Equatable {
    
}

extension JSONStringified: Hashable where Value: Hashable {
    
}
