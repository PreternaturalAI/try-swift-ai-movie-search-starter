//
// Copyright (c) Vatsal Manot
//

import Swallow

/// An identifier in the reverse domain name notation form.
///
/// See more here - https://en.wikipedia.org/wiki/Reverse_domain_name_notation.
public struct ReverseDomainIdentifier: Hashable {
    private let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ name: String, domain: Domain) {
        self.rawValue = "\(domain.rawValue).\(name)"
    }
}

// MARK: - Conformances

extension ReverseDomainIdentifier: Codable {
    public init(from decoder: Decoder) throws {
        try self.init(rawValue: String(from: decoder))
    }
    
    public func encode(to encoder: Encoder) throws {
        try rawValue.encode(to: encoder)
    }
}

extension ReverseDomainIdentifier: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value) // TODO: Add validation
    }
}

extension ReverseDomainIdentifier: PersistentIdentifier {
    public var body: some IdentityRepresentation {
        _StringIdentityRepresentation(rawValue)
    }
}

// MARK: - Auxiliary

extension ReverseDomainIdentifier {
    public struct Domain: RawRepresentable {
        public let rawValue: String
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}
