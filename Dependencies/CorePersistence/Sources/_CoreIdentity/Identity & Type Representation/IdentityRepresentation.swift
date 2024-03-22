//
// Copyright (c) Vatsal Manot
//

import Swallow
import UniformTypeIdentifiers

/// A declarative description of the identity of something.
public protocol IdentityRepresentation {
    associatedtype Body: IdentityRepresentation
    
    @IdentityRepresentationBuilder
    var body: Body { get }
}

// MARK: - Extensions

extension IdentityRepresentation where Self: RawRepresentable, RawValue == String {
    public var body: some IdentityRepresentation {
        _StringIdentityRepresentation(self.rawValue)
    }
}

extension IdentityRepresentation where Self == _StringIdentityRepresentation {
    public static func string(_ string: String) -> Self {
        .init(string)
    }
}

extension IdentityRepresentation where Self == UTType {
    public static func uniformTypeIdentifier(_ type: UTType) -> Self {
        type
    }
}

// MARK: - Implemented Conformances

extension _TypeAssociatedID: IdentityRepresentation where RawValue: IdentityRepresentation {
    public var body: some IdentityRepresentation {
        rawValue.body
    }
}

public struct _StringIdentityRepresentation: Codable, Hashable, IdentityRepresentation {
    public let value: String
    
    public var body: some IdentityRepresentation {
        fatalError()
    }
    
    public init(_ value: String) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        self.init(try .init(from: decoder))
    }
    
    public func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

extension UTType: IdentityRepresentation {
    public var body: some IdentityRepresentation {
        identifier
    }
}

extension Never: IdentityRepresentation {
    
}

#if !os(visionOS)
extension Never {
    public var body: Never {
        return fatalError()
    }
}
#endif
