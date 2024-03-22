//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public struct ProquintDecoder {
    public init() {
        
    }
    
    public func decode(from string: String) throws -> Data {
        let consonants: [Character: UInt16] = [
            "b": 0,  "d": 1,  "f": 2,  "g": 3,
            "h": 4,  "j": 5,  "k": 6,  "l": 7,
            "m": 8,  "n": 9,  "p": 10, "r": 11,
            "s": 12, "t": 13, "v": 14, "z": 15
        ]
        
        let vowels: [Character: UInt16] = ["a": 0, "i": 1, "o": 2, "u": 3]
        
        let quints = string.components(separatedBy: "-")
        
        let result = Data(
            quints
                .map({ [Character]($0) })
                .flatMap { quint -> [UInt8] in
                    let c1 = consonants[quint[0]]!
                    let v1 = vowels[quint[1]]! << 4
                    let c2 = consonants[quint[2]]! << 6
                    let v2 = vowels[quint[3]]! << 10
                    let c3 = consonants[quint[4]]! << 12
                    
                    var n: UInt16 = 0
                    
                    n += c1
                    n += v1
                    n += c2
                    n += v2
                    n += c3
                    
                    return UInt16(n).bytes
                }
        )
        
        return result
    }
    
    public func decode<T: Trivial>(_ type: T.Type, from data: String) throws -> T {
        try type.init(bytes: decode(from: data)).unwrap()
    }
}
