//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import System

extension Bundle {
    public convenience init?(path: FilePath) {
        self.init(path: path.stringValue)
    }
}

extension InputStream {
    public convenience init?(path: FilePath) {
        self.init(fileAtPath: path.stringValue)
    }
}

extension OutputStream {
    public convenience init?(path: FilePath) {
        self.init(path: path, append: false)
    }
    
    public convenience init?(path: FilePath, append shouldAppend: Bool) {
        self.init(toFileAtPath: path.stringValue, append: shouldAppend)
    }
}

extension URL {
    public init(path: FilePath) {
        self.init(fileURLWithPath: path.standardized.stringValue)
    }
}
