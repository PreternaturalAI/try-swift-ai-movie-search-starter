//
// Copyright (c) Vatsal Manot
//

import Swallow
import System


/// A type that can be converted to and from a `FilePath`.
public protocol FilePathRepresentable {
    /// The corresponding path of the type.
    var path: FilePath { get }
    
    /// Creates a new instance with the specified file path.
    init?(path: FilePath)
}

// MARK: - Conformances

extension FilePath: FilePathRepresentable {
    public var path: FilePath {
        self
    }
    
    public init(path: FilePath) {
        self = path
    }
}
