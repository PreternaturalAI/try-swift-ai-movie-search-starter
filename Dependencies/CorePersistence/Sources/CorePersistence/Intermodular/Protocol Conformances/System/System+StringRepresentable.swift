//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import System

extension FilePath: StringRepresentable {
    public var stringValue: String {
        withCString(String.init(cString:))
    }
    
    public init(stringValue: String) {
        self.init(stringValue)
    }
}
