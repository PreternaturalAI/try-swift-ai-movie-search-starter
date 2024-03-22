//
// Copyright (c) Vatsal Manot
//

import Foundation
import System
import Swift

extension FileManager {
    /// Returns a Boolean value that indicates whether a file or directory exists at a specified URL.
    public func fileExists(
        at url: URL
    ) -> Bool {
        fileExists(atPath: url.path)
    }
    
    /// Returns a Boolean value that indicates whether a file or directory exists at a specified path.
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    public func fileExists(
        at path: FilePath
    ) -> Bool {
        fileExists(at: URL(_filePath: path)!)
    }
    
    public func regularFileExists(
        at url: URL
    ) -> Bool {
        var isDirectory: ObjCBool = false
        
        let exists = self.fileExists(atPath: url.path, isDirectory: &isDirectory)
        
        return exists && !isDirectory.boolValue
    }
    
    public func fileIsDirectory(
        atPath path: String
    ) -> Bool {
        var isDirectory: ObjCBool = false
        
        let exists = fileExists(atPath: path, isDirectory: &isDirectory)
        
        return isDirectory.boolValue && exists
    }
    
    /// Returns a Boolean value that indicates whether a directory exists at a specified URL.
    public func directoryExists(
        at url: URL
    ) -> Bool {
        var isFolder: ObjCBool = false
        
        fileExists(atPath: url.path, isDirectory: &isFolder)
        
        if isFolder.boolValue {
            return true
        } else {
            return false
        }
    }
    
    /// Returns a Boolean value that indicates whether a directory exists at a specified path.
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    public func directoryExists(
        at path: FilePath
    ) -> Bool {
#if os(visionOS)
        return directoryExists(at: URL(filePath: path)!)
#else
        return directoryExists(at: URL(_filePath: path)!)
#endif
    }
    
    public func isDirectory<T: URLRepresentable>(
        at location: T
    ) -> Bool {
        let url = location.url
        var isDirectory = ObjCBool(false)
        
        guard fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return false
        }
        
        return isDirectory.boolValue
    }
    
    public func fileExistsAndIsReadable<T: URLRepresentable>(
        at location: T
    ) -> Bool {
        var url = location.url
        
        if isDirectory(at: url) && !url.path.hasSuffix("/") {
            url = URL(fileURLWithPath: url.path.appending("/"))
        }
        
        return isReadableFile(atPath: url.path)
    }
    
    public func isReadable<T: URLRepresentable>(
        at location: T
    ) -> Bool {
        fileExistsAndIsReadable(at: location)
    }
    
    public func isReadableAndWritable<T: URLRepresentable>(
        at location: T
    ) -> Bool {
        var url = location.url
        
        // Check if the file/directory exists
        if !fileExists(atPath: url.path) {
            // If it doesn't exist, recursively check parent directories
            while url.pathComponents.count > 1 {
                url.deleteLastPathComponent()
                if isReadableFile(atPath: url.path) && isWritableFile(atPath: url.path) {
                    return true
                }
            }
            return false
        }
        
        // If it exists, check its readability and writability
        if isDirectory(at: url) && !url.path.hasSuffix("/") {
            url = URL(fileURLWithPath: url.path.appending("/"))
        }
        
        return isReadableFile(atPath: url.path) && isWritableFile(atPath: url.path)
    }

    public func isReadableAndWritable<T: URLRepresentable>(
        atOrAncestorOf location: T
    ) -> Bool {
        let url = location.url._fromFileURLToURL()
        
        if isReadableAndWritable(at: url) {
            return true
        } else {
            let parentURL = url.resolvingSymlinksInPath().deletingLastPathComponent()
            
            guard parentURL != url, !parentURL.path.isEmpty else{
                return false
            }
            
            return isReadableAndWritable(atOrAncestorOf: parentURL)
        }
    }
    
    public func nearestAccessibleSecurityScopedAncestor<T: URLRepresentable>(
        for location: T
    ) -> URL? {
        let url = location.url._fromFileURLToURL()
        
        if let result = try? URL._BookmarksCache.cachedURL(for: location.url._fromFileURLToURL()) {
            return result
        } else if let result = try? URL._BookmarksCache.bookmark(location.url) {
            return result
        } else {
            let parentURL = url.resolvingSymlinksInPath().deletingLastPathComponent()
            
            guard parentURL != url, !parentURL._isRootPath, !parentURL.path.isEmpty else {
                return nil
            }
            
            return nearestAccessibleSecurityScopedAncestor(for: parentURL)
        }
    }
    
    public func isSecurityScopedAccessible<T: URLRepresentable>(
        at location: T
    ) -> Bool {
        let url = location.url._fromFileURLToURL()
        
        if ((try? URL._BookmarksCache.cachedURL(for: location.url._fromFileURLToURL())) as URL?) != nil {
            return true
        }
        
        if isReadableAndWritable(at: url) {
            return true
        } else {
            let parentURL = url.deletingLastPathComponent()
            
            guard parentURL != url, !parentURL._isRootPath, !parentURL.path.isEmpty else {
                return false
            }
            
            return isSecurityScopedAccessible(at: parentURL)
        }
    }
    
}

extension FileManager {
    public func suburls<T: URLRepresentable>(
        at location: T
    ) throws -> [T] {
        try contentsOfDirectory(atPath: location.url.path)
            .lazy
            .map({ location.url.appendingPathComponent($0) })
            .map({ try T(url: $0).unwrap() })
    }
    
    public func enumerateRecursively(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]? = nil,
        options mask: FileManager.DirectoryEnumerationOptions = [],
        body: (URL) throws -> Void
    ) throws {
        if !isDirectory(at: url) {
            return try body(url)
        }
        
        var errorEncountered: Error? = nil
        
        guard let enumerator = enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: mask,
            errorHandler: { url, error in
                errorEncountered = error
                
                return false
            }
        ) else {
            return
        }
        
        var urls: [URL] = []
        
        for case let fileURL as URL in enumerator {
            if let keys = keys {
                let _ = try fileURL.resourceValues(forKeys: .init(keys))
            }
            
            urls.append(fileURL)
        }
        
        try urls.forEach(body)
        
        if let error = errorEncountered {
            throw error
        }
    }
}

extension FileManager {
    public func createDirectoryIfNecessary(
        at url: URL,
        withIntermediateDirectories: Bool = false
    ) throws {
        guard !fileExists(at: url) else {
            return
        }
        
        try createDirectory(
            at: url,
            withIntermediateDirectories: withIntermediateDirectories,
            attributes: nil
        )
    }
    
    public func copyItemIfNecessary(
        at sourceURL: URL,
        to destinationURL: URL
    ) throws {
        guard !FileManager.default.fileExists(at: destinationURL) else {
            // FIXME: Validate via file hashes
            
            return
        }
        
        try copyItem(at: sourceURL, to: destinationURL)
    }
    
    public func withTemporaryCopy<Result>(
        of url: URL,
        perform body: (URL) throws -> Result
    ) throws -> Result {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectoryURL.appendingPathComponent(url.lastPathComponent)
        
        try copyItemIfNecessary(at: url, to: tempFileURL)
        
        do {
            let result = try body(tempFileURL)
            
            try removeItemIfNecessary(at: tempFileURL)
            
            return result
        } catch {
            try removeItemIfNecessary(at: tempFileURL)
            
            throw error
        }
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    public func removeItem(
        at path: FilePath
    ) throws {
        try removeItem(at: URL(_filePath: path).unwrap())
    }
    
    public func removeItemIfNecessary(
        at url: URL
    ) throws {
        guard fileExists(at: url) else {
            return
        }
        
        try removeItem(at: url)
    }
    
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    public func removeItemIfNecessary(
        at url: FilePath
    ) throws {
        guard fileExists(at: url) else {
            return
        }
        
        try removeItem(at: url)
    }
}

extension FileManager {
    public func parentDirectory(
        for url: URL
    ) -> URL {
        let result = url.deletingLastPathComponent()
        
        assert(result.hasDirectoryPath)
        
        return result
    }
    
    public func createFile(
        at url: URL,
        contents: Data,
        attributes: [FileAttributeKey: Any]? = nil,
        withIntermediateDirectories: Bool = true
    ) throws {
        if withIntermediateDirectories {
            try createDirectoryIfNecessary(at: parentDirectory(for: url))
        }
        
        try contents.write(to: url, options: .atomic)
        
        if let attributes {
            try setAttributes(attributes, ofItemAtPath: url.path)
        }
    }
    
    public func contents(
        of url: URL
    ) throws -> Data {
        try contents(atPath: url.path).unwrap()
    }
    
    public func contentsIfFileExists(
        of url: URL
    ) throws -> Data? {
        guard fileExists(at: url) else {
            return nil
        }
        
        return try contents(of: url)
    }
    
    public func contentsOfDirectory(
        at url: URL
    ) throws -> [URL] {
        func alternateResult() throws -> [URL] {
            return try contentsOfDirectory(atPath: url.path).map { path in
                let itemURL = url.appending(URL.PathComponent(rawValue: path, isDirectory: nil))
                
                assert(url.path != itemURL.path)
                
                return itemURL
            }
        }
        
        do {
            return try contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])
        } catch(let error) {
            do {
                return try alternateResult()
            } catch(_) {
                throw error
            }
        }
    }
    
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    public func contentsOfDirectory(
        at path: FilePath
    ) throws -> [URL] {
        try contentsOfDirectory(at: URL(_filePath: path).unwrap(), includingPropertiesForKeys: [])
    }
    
    public func setContents(
        of url: URL,
        to data: Data,
        createDirectoriesIfNecessary: Bool = true
    ) throws {
        if createDirectoriesIfNecessary {
            if directoryExists(at: url.deletingLastPathComponent()) {
                try data.write(to: url)
            } else {
                try createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [:])
                
                try data.write(to: url)
            }
        } else {
            try data.write(to: url)
        }
    }
}

extension FileManager {
    public func url(
        for directory: SearchPathDirectory,
        in domainMask: SearchPathDomainMask
    ) throws -> URL {
        enum ResolutionError: Error {
            case noURLFound
            case foundMultipleURLs
        }
        
        let urls = urls(for: directory, in: domainMask)
        
        guard let result = urls.first else {
            throw ResolutionError.noURLFound
        }
        
        guard urls.count == 1 else {
            throw ResolutionError.foundMultipleURLs
        }
        
        return result
    }
    
    public func documentsDirectoryURL(forUbiquityContainerIdentifier: String?) throws -> URL? {
        guard let url = url(forUbiquityContainerIdentifier: forUbiquityContainerIdentifier)?.appendingPathComponent("Documents") else {
            return nil
        }
        
        guard !FileManager.default.fileExists(atPath: url.path, isDirectory: nil) else {
            return url
        }
        
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        
        return url
    }
}
