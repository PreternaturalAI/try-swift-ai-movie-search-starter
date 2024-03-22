//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public struct ProquintEncodedInteger<T: Codable & BinaryInteger & Randomnable & Sendable & Trivial>: Hashable, @unchecked Sendable {
    private static var decoder: ProquintDecoder {
        ProquintDecoder()
    }
    
    private static var encoder: ProquintEncoder {
        ProquintEncoder()
    }
    
    private let rawValue: T
    
    fileprivate init(rawValue: T) {
        self.rawValue = rawValue
    }
}

// MARK: - Conformances

extension ProquintEncodedInteger: Codable {
    public init(from decoder: Decoder) throws {
        let _rawValue = try String(from: decoder)
        
        self.init(rawValue: try Self.decoder.decode(T.self, from: _rawValue))
    }
    
    public func encode(to encoder: Encoder) throws {
        let _rawValue = try Self.encoder.encode(rawValue)
        
        try _rawValue.encode(to: encoder)
        
    }
}

extension ProquintEncodedInteger: CustomStringConvertible {
    public var description: String {
        try! Self.encoder.encode(rawValue)
    }
}

extension ProquintEncodedInteger: LosslessStringConvertible {
    public init?(_ description: String) {
        guard let rawValue = try? ProquintDecoder().decode(T.self, from: description) else {
            return nil
        }
        
        self.init(rawValue: rawValue)
    }
}

extension ProquintEncodedInteger: Randomnable {
    public static func random() -> ProquintEncodedInteger<T> {
        .init(rawValue: .random())
    }
}
