//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import TabularData

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension _TabularDataDecoder {
    final class SingleValueContainer {
        let codingPath: [CodingKey]
        let dataFrame: DataFrame
        
        init(codingPath: [CodingKey], dataFrame: DataFrame)  {
            self.codingPath = codingPath
            self.dataFrame = dataFrame
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension _TabularDataDecoder.SingleValueContainer: SingleValueDecodingContainer {
    func decodeNil() -> Bool {
        false
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        throw Never.Reason.unsupported
    }
    
    func decode(_ type: String.Type) throws -> String {
        throw Never.Reason.unsupported
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        throw Never.Reason.unsupported
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        throw Never.Reason.unsupported
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        throw Never.Reason.unsupported
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        throw Never.Reason.unsupported
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        throw Never.Reason.unsupported
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        throw Never.Reason.unsupported
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        throw Never.Reason.unsupported
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        throw Never.Reason.unsupported
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        throw Never.Reason.unsupported
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        throw Never.Reason.unsupported
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        throw Never.Reason.unsupported
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        throw Never.Reason.unsupported
    }
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let decoder = _TabularDataDecoder(
            owner: .container(.singleValue),
            dataFrame: dataFrame
        )
        
        return try T(from: decoder)
    }
}
