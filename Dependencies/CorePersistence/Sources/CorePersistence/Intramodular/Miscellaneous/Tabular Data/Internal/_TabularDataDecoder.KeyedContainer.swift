//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import TabularData

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension _TabularDataDecoder {
    final class KeyedContainer<Key: CodingKey>  {
        let codingPath: [CodingKey]
        
        private let dataFrame: DataFrame
        private let row: DataFrame.Row
        
        required init(
            codingPath: [CodingKey],
            dataFrame: DataFrame,
            row: DataFrame.Row
        ) {
            self.codingPath = codingPath
            self.dataFrame = dataFrame
            self.row = row
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension _TabularDataDecoder.KeyedContainer: KeyedDecodingContainerProtocol {
    var allKeys: [Key] {
        dataFrame.columns.compactMap({ Key(stringValue: $0.name) })
    }
    
    func contains(_ key: Key) -> Bool {
        allKeys.contains(where: { $0.stringValue == key.stringValue })
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        !contains(key)
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String  {
        guard contains(key) else {
            throw DecodingError.keyNotFound(key, .init(codingPath: codingPath))
        }
        
        let value = try row[key.stringValue].unwrap()
        
        if let value = value as? String {
            return value
        } else {
            return String(describing: value)
        }
    }
    
    func decode<T: Decodable & LosslessStringConvertible>(
        _ type: T.Type,
        forKey key: Key
    ) throws -> T {
        let string = try self.decode(String.self, forKey: key)
        
        guard let value = T(string) else  {
            let context = DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Failed to decode \(type) for key: \(key)"
            )
            
            throw DecodingError.typeMismatch(type, context)
        }
        
        return value
    }
    
    func decode<T: Decodable>(
        _ type: T.Type,
        forKey key: Key
    ) throws -> T {
        let stringValue = try decode(String.self, forKey: key)
        
        return try ObjectDecoder().decode(
            type,
            from: try ObjectEncoder().encode(stringValue)
        ) // TODO: Optimize
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        throw Never.Reason.unavailable
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        throw Never.Reason.unavailable
    }
    
    func superDecoder() throws -> Decoder  {
        throw Never.Reason.unavailable
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        throw Never.Reason.unavailable
    }
}
