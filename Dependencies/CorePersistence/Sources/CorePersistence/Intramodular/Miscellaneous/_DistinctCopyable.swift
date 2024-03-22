//
// Copyright (c) Vatsal Manot
//

import Swift

/// A type that can generate distinct copies of itself.
public protocol _DistinctCopyable {
    func distinctCopy() throws -> Self
}

// MARK: - Implementation

extension _DistinctCopyable where Self: Identifiable {
    public func distinctCopy() throws -> Self {
        throw Never.Reason.unimplemented
    }
}
