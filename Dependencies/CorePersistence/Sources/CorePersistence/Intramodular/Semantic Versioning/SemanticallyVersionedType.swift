//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

/// A semantically versioned _type_ (this is not to be confused with a semantically versioned _instance_).
public protocol SemanticallyVersionedType {
    associatedtype TypeVersion: SemanticVersionProtocol = Optional<FoundationX.Version>
    
    static var typeVersion: TypeVersion { get }
}

// MARK: - Implementation

extension SemanticallyVersionedType where TypeVersion == Optional<FoundationX.Version> {
    public static var typeVersion: TypeVersion {
        nil
    }
}
