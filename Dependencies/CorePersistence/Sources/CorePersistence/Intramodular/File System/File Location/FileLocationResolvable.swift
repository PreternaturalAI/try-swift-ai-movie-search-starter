//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swift
import System

public protocol FileLocationResolvable {
    func resolveFileLocation() throws -> BookmarkedURL
}

// MARK: - Implementation

extension FileLocationResolvable where Self: URLRepresentable {
    public func resolveFileLocation() throws -> BookmarkedURL {
        let url = self.url
        
        guard url.isFileURL else {
            throw FileSystemError.isNotFileURL(url)
        }
        
        return .init(_unsafe: url.standardizedFileURL)
    }
}

// MARK: - Extensions

extension FileLocationResolvable {
    public var isReachable: Bool {
        do {
            return try resolveFileLocation().url.checkResourceIsReachable()
        } catch {
            return false
        }
    }
}

extension FileLocationResolvable {
    public func resolveFilePath() throws -> FilePath {
        return .init(fileURL: try resolveFileURL())
    }
    
    public func resolveFileURL() throws -> URL {
        return try resolveFileLocation().url
    }
}

// MARK: - Conformances

extension BookmarkedURL: FileLocationResolvable {
    
}

extension FilePath: FileLocationResolvable {
    public func resolveFileLocation() throws -> BookmarkedURL {
        try .init(_unsafe: URL(_filePath: self).unwrap())
    }
}

extension String: FileLocationResolvable {
    public func resolveFileLocation() throws -> BookmarkedURL {
        return try FilePath(NSString(string: self).expandingTildeInPath).resolveFileLocation()
    }
}

extension URL: FileLocationResolvable {
    
}
