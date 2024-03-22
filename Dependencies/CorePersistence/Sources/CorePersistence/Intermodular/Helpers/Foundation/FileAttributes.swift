//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import System

public struct FileAttributes: Initiable {
    public typealias DictionaryKey = Value.DictionaryKey
    public typealias DictionaryValue = Value.DictionaryValue
    public typealias Element = Value.Element
    public typealias Index = Value.Index
    public typealias Iterator = Value.Iterator
    public typealias SubSequence = Value.SubSequence
    public typealias Value = [FileAttributeKey: Any]
    
    public var value: Value
    
    public init(_ value: Value) {
        self.value = value
    }
    
    public init() {
        self.init(Value())
    }
}

extension FileAttributes {
    public subscript(_ key: FileAttributeKey) -> Any? {
        get {
            return value[key]
        } set {
            value[key] = newValue
        }
    }
}

// MARK: - Extensions

extension FileAttributes {
    public var fileSize: UInt64? {
        self[.size] as? UInt64
    }
    
    public var dateModified: Date? {
        self[.modificationDate] as? Date
    }
    
    public var fileReferenceCount: UInt? {
        self[.referenceCount] as? UInt
    }
    
    public var ownerAccountName: String? {
        self[.ownerAccountName] as? String
    }
    
    public var groupOwnerAccountName: String? {
        self[.groupOwnerAccountName] as? String
    }
    
    public var posixFilePermissions: FilePermissions? {
        get {
            self[.posixPermissions].flatMap({ $0 as? FilePermissions.RawValue }).flatMap({ FilePermissions(rawValue: $0) })
        } set {
            self[.posixPermissions] = newValue?.rawValue
        }
    }
    
    public var systemFileNumber: UInt? {
        self[.systemFileNumber] as? UInt
    }
    
    public var extensionIsHidden: Bool? {
        self[.extensionHidden] as? Bool
    }
    
    public var dateCreated: Date? {
        self[.creationDate] as? Date
    }
    
    public var ownerAccountID: UInt? {
        self[.ownerAccountID] as? UInt
    }
    
    public var groupOwnerAccountID: UInt? {
        self[.groupOwnerAccountID] as? UInt
    }
}

// MARK: - Helpers

extension FilePath {
    public func resolveFileAttributes() throws -> FileAttributes {
        return FileAttributes(try FileManager.default.attributesOfItem(atPath: stringValue))
    }
    
    public func resolveFilePermissions() throws -> FilePermissions? {
        try resolveFileAttributes().posixFilePermissions
    }
}
