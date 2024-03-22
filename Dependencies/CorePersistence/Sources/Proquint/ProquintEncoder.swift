//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public struct ProquintEncoder {
    public init() {
        
    }
    
    public func encode<Bytes: Sequence>(
        _ bytes: Bytes
    ) throws -> String where Bytes.Element == UInt8 {
        let consonants: [Character] = Array("bdfghjklmnprstvz")
        let vowels: [Character] = Array("aiou")
        
        var result: [String] = []
        
        let data = Data(bytes)
        
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            let elements = UnsafeBufferPointer<UInt16>(start: .init(OpaquePointer(bytes.baseAddress!)), count: data.count / 2)
            
            for n in elements {
                let c1 = n & 0x0f
                let v1 = (n >> 4)  & 0x03
                let c2 = (n >> 6)  & 0x0f
                let v2 = (n >> 10) & 0x03
                let c3 = (n >> 12) & 0x0f
                
                let characters: [Character] = [
                    consonants[Int(c1)],
                    vowels[Int(v1)],
                    consonants[Int(c2)],
                    vowels[Int(v2)],
                    consonants[Int(c3)],
                ]
                
                result.append(characters.map({ String($0) }).joined())
            }
        }
        
        return result.joined(separator: "-")
    }
    
    public func encode<T: Trivial>(_ value: T) throws -> String {
        try encode(value.bytes)
    }
}
