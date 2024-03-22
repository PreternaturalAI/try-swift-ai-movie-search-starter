//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift
import System
import UniformTypeIdentifiers

extension URL {
    public static func filePath(_ path: String) -> URL {
        URL(path: FilePath(path))
    }
}
