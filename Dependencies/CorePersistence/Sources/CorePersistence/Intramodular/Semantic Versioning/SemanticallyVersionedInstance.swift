//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swift

/// A type whose instances are semantically versioned.
public protocol SemanticallyVersionedInstance {
    associatedtype InstanceVersion: SemanticVersionProtocol = Optional<FoundationX.Version>
    
    var instanceVersion: InstanceVersion? { get }
}

// MARK: - Implementation -

extension SemanticallyVersionedInstance where InstanceVersion == Optional<FoundationX.Version> {
    var instanceVersion: InstanceVersion? {
        nil
    }
}
