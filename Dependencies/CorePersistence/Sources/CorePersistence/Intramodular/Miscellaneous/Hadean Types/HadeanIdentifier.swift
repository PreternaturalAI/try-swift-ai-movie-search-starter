//
// Copyright (c) Vatsal Manot
//

import Proquint
import Swallow

/// An internal persistent identifier.
///
/// Don’t use this type directly in your code.
public struct HadeanIdentifier: RawRepresentable, Sendable {
    public typealias RawValue = ProquintEncodedInteger<Int>
    
    public let rawValue: RawValue
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    internal init(_unchecked string: String) {
        self.rawValue = try! RawValue(string).unwrap()
    }
}

// MARK: - Conformances

extension HadeanIdentifier: HadeanIdentifiable {
    public static var hadeanIdentifier: HadeanIdentifier {
        "gujof-fuvom-nodon-johul"
    }
}

extension HadeanIdentifier: PersistentTypeIdentifier {    
    public var body: some IdentityRepresentation {
        rawValue.body
    }
}

// MARK: - Conformances

extension HadeanIdentifier: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(_unchecked: value)
    }
}

extension HadeanIdentifier: CustomStringConvertible {
    public var description: String {
        rawValue.description
    }
}

extension HadeanIdentifier: Codable {
    public init(from decoder: Decoder) throws {
        self.init(rawValue: try RawValue(from: decoder))
    }
    
    public func encode(to encoder: Encoder) throws {
        try rawValue.encode(to: encoder)
    }
}

extension HadeanIdentifier: LosslessStringConvertible {
    public init?(_ description: String) {
        guard let rawValue = RawValue(description) else {
            return nil
        }
        
        self.init(rawValue: rawValue)
    }
}

extension HadeanIdentifier: Randomnable {
    public static func random() -> Self {
        let result = HadeanIdentifier(rawValue: .random())
        
        /*if Self.allCases.contains(result) {
            assertionFailure("Unexpected collision: \(result)")
        }*/
        
        return result
    }
}
