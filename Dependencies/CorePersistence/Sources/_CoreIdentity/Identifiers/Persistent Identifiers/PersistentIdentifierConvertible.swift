//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

/// A type that has a persistent identifier.
///
/// This is useful for maintaining the identity of a type (even when its type name is changed).
public protocol PersistentIdentifierConvertible {
    associatedtype PersistentID: Codable, Hashable, Sendable
    
    var persistentID: PersistentID { get }
}

// MARK: - Implementation

extension PersistentIdentifierConvertible where Self: Identifiable, ID: PersistentIdentifier {
    public var persistentID: Self.ID {
        id
    }
}
