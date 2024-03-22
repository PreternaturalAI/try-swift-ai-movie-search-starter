//
// Copyright (c) Vatsal Manot
//

import Foundation
import Proquint
import Swallow

/// A persistent identifier.
public protocol PersistentIdentifier: Codable, Hashable, IdentifierProtocol, Sendable {
    associatedtype IdentifierSpace: _PersistentIdentifierSpace = _DefaultPersistentIdentifierSpace<Self> where IdentifierSpace.Identifier == Self
}

/// A persistent identifier that is primarily used to identify the type of a thing.
public protocol PersistentTypeIdentifier: PersistentIdentifier {
    
}

/// A type that represents an identifier space.
///
/// Do not use this type directly in your code. It is still in development.
public protocol _PersistentIdentifierSpace {
    associatedtype Identifier: PersistentIdentifier
    
    typealias ValidateMethod = (any ValidatePersistentIdentifierMethod<Identifier>)
    
    static var validate: ValidateMethod? { get }
}

public protocol ValidatePersistentIdentifierMethod<Identifier> {
    associatedtype Identifier: PersistentIdentifier
    
    func callAsFunction(_ identifier: Identifier) throws
}

public protocol _OpenPersistentIdentifierSpace: _PersistentIdentifierSpace {
    
}

public struct _DefaultPersistentIdentifierSpace<Identifier: PersistentIdentifier>: _OpenPersistentIdentifierSpace {
    public typealias Identifier = Identifier
    
    public static var validate: ValidateMethod? {
        nil
    }
}

// MARK: - Implemented Conformances

public struct CSSearchableItemID: PersistentIdentifier, Sendable {
    public let uniqueIdentifier: String
    public let domainIdentifier: String?
    
    public var body: some IdentityRepresentation {
        _StringIdentityRepresentation((domainIdentifier.map({ $0 + "." }) ?? "") + uniqueIdentifier)
    }
}

extension ProquintEncodedInteger: PersistentIdentifier {
    public var body: some IdentityRepresentation {
        _StringIdentityRepresentation(description)
    }
}

extension _TypeAssociatedID: PersistentIdentifier where RawValue: PersistentIdentifier {
    
}

extension UUID: PersistentIdentifier {
    public var body: some IdentityRepresentation {
        _StringIdentityRepresentation(uuidString)
    }
}
