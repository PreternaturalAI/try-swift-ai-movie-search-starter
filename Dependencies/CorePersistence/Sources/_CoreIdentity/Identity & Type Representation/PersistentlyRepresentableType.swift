//
// Copyright (c) Vatsal Manot
//

import Swift

/// Defines a type representation that offers unique and persistent identities for a type.
///
/// It's similar to `AppIntents.PersistentlyIdentifiable`, but much more powerful.
///
/// This is useful for maintaining the identity of a type, even when its type name is changed.
public protocol PersistentlyRepresentableType {
    associatedtype PersistentTypeRepresentation: IdentityRepresentation
    
    /// An identifier that uniquely identifies this type.
    @IdentityRepresentationBuilder
    static var persistentTypeRepresentation: PersistentTypeRepresentation { get }
}
