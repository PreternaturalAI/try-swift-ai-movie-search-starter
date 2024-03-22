//
// Copyright (c) Vatsal Manot
//

import Foundation
import Merge
import POSIX
import Swallow

open class InputOutputResource {
    var descriptor: POSIXIOResourceDescriptor
    var descriptorIsOwned: Bool
    
    public init(
        descriptor: POSIXIOResourceDescriptor,
        transferOwnership: Bool = true
    ) throws {
        self.descriptor = descriptor
        self.descriptorIsOwned = transferOwnership
    }
    
    deinit {
        if descriptorIsOwned {
            do {
                try descriptor.close()
            } catch {
                assertionFailure()
            }
        }
    }
}

// MARK: - Conformances

extension InputOutputResource: CustomStringConvertible {
    public var description: String {
        return "I/O Resource"
    }
}
