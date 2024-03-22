//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

/// A file reference URL.
public struct FileReference: FileLocationResolvable, URLRepresentable {
    private var rawValue: NSURL // `NSURL` because `URL` cannot store file references.
    
    public var url: URL {
        rawValue as URL
    }
    
    public init?(url: URL) {
        do {
            rawValue = try ((url as NSURL).perform(#selector(NSURL.fileReferenceURL))?.takeUnretainedValue() as? NSURL).unwrapOrThrow(FileSystemError.fileNotFound(url))
        } catch {
            return nil
        }
    }
    
    public func resolveFileLocation() throws -> BookmarkedURL {
        return .init(_unsafe: rawValue as URL)
    }
}

// MARK: - Conformances

extension FileReference: CustomStringConvertible {
    public var description: String {
        return rawValue.description
    }
}
