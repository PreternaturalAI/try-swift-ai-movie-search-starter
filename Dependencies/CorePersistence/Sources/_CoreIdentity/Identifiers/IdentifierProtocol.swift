//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public protocol IdentifierProtocol: Hashable, IdentityRepresentation {
    
}

public protocol UniversallyUniqueIdentifier: IdentifierProtocol, Sendable {
    
}

// MARK: - Implemented Conformances

extension _TypeAssociatedID: IdentifierProtocol where RawValue: IdentifierProtocol {
    
}

extension _TypeAssociatedID: UniversallyUniqueIdentifier where RawValue: UniversallyUniqueIdentifier {
    
}

extension UUID: UniversallyUniqueIdentifier {
    
}
