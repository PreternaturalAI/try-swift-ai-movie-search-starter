//
// Copyright (c) Vatsal Manot
//

import Swift
import System

extension String {
    public init(path: FilePath) {
        self = path.stringValue
    }
}
