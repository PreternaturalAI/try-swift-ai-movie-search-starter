//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

public struct _RelativeFolderConfiguration<Value>: _PartiallyEquatable {
    public var path: String?
    public var initialValue: Value?
    
    public func isEqual(
        to other: Self
    ) -> Bool? {
        if (path != other.path) {
            return false
        } else {
            return nil
        }
    }
}
