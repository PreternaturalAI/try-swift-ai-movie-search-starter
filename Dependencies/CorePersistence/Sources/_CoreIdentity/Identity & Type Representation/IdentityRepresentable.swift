//
// Copyright (c) Vatsal Manot
//

import Swift

/// A class of types whose instances hold the value of an entity with one or more stable identities.
public protocol IdentityRepresentable {
    associatedtype IdentityRepresentation: _CoreIdentity.IdentityRepresentation
    
    /// The representation used to identify the value.
    ///
    /// A ``identityRepresentation`` can contain multiple representations.
    @IdentityRepresentationBuilder
    var identityRepresentation: IdentityRepresentation { get }
}
