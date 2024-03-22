//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import TabularData

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension _TabularDataDecoder {
    final class UnkeyedContainer {
        let codingPath: [CodingKey]
        
        private let dataFrame: DataFrame
        
        var currentIndex = 0
        
        required init(
            codingPath: [CodingKey],
            dataFrame: DataFrame
        )  {
            self.codingPath = codingPath
            self.dataFrame = dataFrame
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension _TabularDataDecoder.UnkeyedContainer: UnkeyedDecodingContainer {
    var count: Int? {
        dataFrame.rows.count
    }
    
    var isAtEnd: Bool {
        currentIndex >= (count ?? 0)
    }
    
    func decodeNil() throws -> Bool {
        return !self.isAtEnd
    }
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T  {
        guard !isAtEnd else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "no more values")
        }
        
        defer {
            self.currentIndex += 1
        }
        
        let row = self.dataFrame.rows[atDistance: currentIndex]
        
        let decoder = _TabularDataDecoder(
            owner: .container(.unkeyed),
            row: row,
            in: dataFrame,
            at: AnyCodingKey(intValue: currentIndex)
        )
        
        return try T(from: decoder)
    }
    
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer  {
        throw Never.Reason.unsupported
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        throw Never.Reason.unsupported
    }
    
    func superDecoder() throws -> Decoder {
        throw Never.Reason.unsupported
    }
}
