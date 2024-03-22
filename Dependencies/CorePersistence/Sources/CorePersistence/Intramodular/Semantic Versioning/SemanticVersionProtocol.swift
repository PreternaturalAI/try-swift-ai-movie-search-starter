//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swift

/// A type that represents a semantic version.
public protocol SemanticVersionProtocol: Codable, Hashable {
    
}

// MARK: - Conditional Conformances

extension Optional: SemanticVersionProtocol where Wrapped: SemanticVersionProtocol {
    
}

// MARK: - Conformances

extension FoundationX.Version: SemanticVersionProtocol {
    
}
