//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

public final class CSVDecoder: TopLevelDecoder {
    public typealias Input = CSV
    
    public init() {
        
    }
    
    private enum DecodingError: Swift.Error {
        case missingHeaders
        case invalidRowValuesCount
    }
    
    public func decode<T: Decodable>(_ type: T.Type, from data: CSV) throws -> T {
        let decoder = try _Decoder(
            headers: data.headers,
            rows: data.rows.map { row in
                if row.count != data.headers.count {
                    throw DecodingError.invalidRowValuesCount
                }
                
                return row
            }
        )
        
        return try T(from: decoder)
    }
}

// MARK: - Underlying Implementation -

extension CSVDecoder {
    final class _Decoder: Decoder {
        public var codingPath = [CodingKey]()
        public var userInfo = [CodingUserInfoKey : Any]()
        
        private let headers: [CSVColumnHeader]
        private let rows: [[String]]
        
        required init(headers: [CSVColumnHeader], rows: [[String]]) {
            self.headers = headers
            self.rows = rows
        }
        
        func container<Key: CodingKey>(
            keyedBy type: Key.Type
        ) throws -> KeyedDecodingContainer<Key>  {
            KeyedDecodingContainer(
                KeyedContainer<Key>(
                    headers: headers,
                    values: rows.first ?? [],
                    codingPath: codingPath
                )
            )
        }
        
        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            UnkeyedContainer(
                headers: self.headers,
                rows: self.rows,
                codingPath: self.codingPath
            )
        }
        
        func singleValueContainer() throws -> SingleValueDecodingContainer {
            SingleValueContainer(
                headers: self.headers,
                rows: self.rows,
                codingPath: self.codingPath
            )
        }
    }
}
