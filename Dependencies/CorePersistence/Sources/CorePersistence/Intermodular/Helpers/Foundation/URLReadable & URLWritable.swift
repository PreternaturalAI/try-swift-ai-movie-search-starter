//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import System

public protocol URLReadable {
    static func read(from _: URL) throws -> Self
}

public protocol URLWritable {
    func write(to _: URL, atomically: Bool) throws
}

public typealias URLReadableWritable = URLReadable & URLWritable

// MARK: - Extensions

extension URLReadable {
    public static func read(from path: FilePath) throws -> Self {
        try read(from: path.resolveFileURL())
    }
}

extension URLWritable {
    public func write(to path: FilePath, atomically: Bool) throws {
        try write(to: path.resolveFileURL(), atomically: atomically)
    }
}

// MARK: - Conformances

extension Array: URLReadable, URLWritable where Element == AnyObject {
    public static func read(from url: URL) throws -> Array {
        return try NSArray.read(from: url) as [AnyObject]
    }
    
    public func write(to url: URL, atomically: Bool) throws {
        try (self as NSArray).write(to: url, atomically: atomically) as Void
    }
}

extension Data: URLReadable, URLWritable {
    public static func read(from url: URL) throws -> Data {
        return try .init(contentsOf: url)
    }
    
    public func write(to url: URL, atomically: Bool) throws {
        try write(to: url, options: .atomic)
    }
}

extension Dictionary: URLReadable, URLWritable where Key == NSObject, Value == AnyObject {
    public static func read(from url: URL) throws -> Dictionary {
        return try NSDictionary.read(from: url) as Dictionary
    }
    
    public func write(to url: URL, atomically: Bool) throws {
        try (self as NSDictionary).write(to: url, atomically: atomically) as Void
    }
}

extension NSArray: URLReadable, URLWritable {
    public static func read(from url: URL) throws -> Self {
        return try self.init(contentsOf: url).unwrap()
    }
    
    public func write(to url: URL, atomically: Bool) throws {
        try write(to: url, atomically: atomically).orThrow(CocoaError.error(.fileWriteUnknown, url: url))
    }
}

extension NSDictionary: URLReadable, URLWritable {
    public static func read(from url: URL) throws -> Self {
        return try self.init(contentsOf: url).unwrap()
    }
    
    public func write(to url: URL, atomically: Bool) throws {
        try write(to: url, atomically: atomically).orThrow(CocoaError.error(.fileWriteUnknown, url: url))
    }
}

extension NSString: URLReadable, URLWritable {
    public static func read(from url: URL) throws -> Self {
        return try self.init(contentsOf: url, encoding: String.Encoding.utf8.rawValue)
    }
    
    public func write(to url: URL, atomically: Bool) throws {
        try write(to: url, atomically: atomically, encoding: String.Encoding.utf8.rawValue)
    }
}

extension String: URLReadable, URLWritable {
    public static func read(from url: URL) throws -> String {
        return try NSString.read(from: url) as String
    }
    
    public func write(to url: URL, atomically: Bool) throws {
        #if os(tvOS) || os(visionOS)
        try write(toFile: url.path, atomically: atomically, encoding: .utf8)
        #else
        try (self as NSString).write(to: url, atomically: atomically)
        #endif
    }
}
