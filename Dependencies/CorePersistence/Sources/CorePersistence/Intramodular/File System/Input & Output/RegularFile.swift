//
// Copyright (c) Vatsal Manot
//

import FoundationX
import POSIX
import Swallow
import System

public protocol AnyRegularFile<FileAccessMode> {
    associatedtype FileAccessMode: FileAccessModeType
}

public class RegularFile<DataType, AccessMode: FileAccessModeType>: InputOutputResource, AnyRegularFile {
    public typealias FileAccessMode = AccessMode
    
    var reference: FileReference
    var handle: FileHandle
    
    public var location: FileLocationResolvable {
        reference
    }
    
    public var path: FilePath {
        FilePath(reference.url.path)
    }
    
    public required init(
        at location: FileLocationResolvable
    ) throws {
        let url = try location.resolveFileLocation().url
        
        self.reference = try FileReference(url: url).unwrap()
        
        switch AccessMode.value {
            case .read:
                self.handle = try .init(forReadingFrom: url)
            case .write:
                self.handle = try .init(forWritingTo: url)
            case .update:
                self.handle = try .init(forUpdating: url)
        }
        
        try super.init(
            descriptor: .init(rawValue: handle.fileDescriptor),
            transferOwnership: false
        )
    }
}

extension RegularFile where AccessMode == FileAccessModes.UpdateAccess {
    @_disfavoredOverload
    public convenience init(at location: FileLocationResolvable) throws {
        try self.init(at: location)
    }
}

// MARK: - Extensions

extension RegularFile where AccessMode: FileAccessModeTypeForReading {
    public func getRawData() -> Data {
        return handle.seekingToStartOfFile().readDataToEndOfFile()
    }
}

extension RegularFile where AccessMode: FileAccessModeTypeForWriting {
    public func set(rawData data: Data) {
        handle.seekingToStartOfFile().write(truncatingTo: data)
    }
    
    public func flushToDisk() {
        handle.synchronizeFile()
    }
}

extension RegularFile where AccessMode: FileAccessModeTypeForUpdating {
    public var rawData: Data {
        get {
            return getRawData()
        } set {
            set(rawData: newValue)
        }
    }
}

extension RegularFile {
    public static func create<Location: FileLocationResolvable>(at location: Location) throws -> Self {
        let url = try location.resolveFileLocation()
        
        try FileManager.default.createFile(atPath: url.path.stringValue, contents: nil, attributes: nil).orThrow(CocoaError(.fileWriteUnknown))
        
        return try self.init(at: url)
    }
    
    public static func createIfNecessary<Location: FileLocationResolvable>(at location: Location) throws -> Self {
        return try FileManager.default.fileExists(atPath: location.resolveFileLocation().path.stringValue) ? .init(at: location) : create(at: location)
    }
    
    public func move(to other: BookmarkedURL) throws {
        try FileManager.default.moveItem(at: resolveFileLocation().url, to: other.url)
    }
}

// MARK: - Conformances

extension RegularFile: FileLocationResolvable {
    public func resolveFileLocation() throws -> BookmarkedURL {
        return try reference.resolveFileLocation()
    }
}

// MARK: - Auxiliary

extension RegularFile where AccessMode: FileAccessModeTypeForReading, DataType: DataDecodable {
    public func data(using strategy: DataType.DataDecodingStrategy) throws -> DataType {
        return try DataType.init(data: getRawData(), using: strategy)
    }
}

extension RegularFile where AccessMode: FileAccessModeTypeForReading, DataType: DataDecodableWithDefaultStrategy {
    public func data(using strategy: DataType.DataDecodingStrategy = DataType.defaultDataDecodingStrategy) throws -> DataType {
        return try DataType.init(data: getRawData(), using: strategy)
    }
}

extension RegularFile where AccessMode: FileAccessModeTypeForWriting, DataType: DataEncodable {
    public func write(_ data: DataType, using strategy: DataType.DataEncodingStrategy) throws {
        try set(rawData: data.data(using: strategy))
    }
}

extension RegularFile where AccessMode: FileAccessModeTypeForWriting, DataType: DataEncodableWithDefaultStrategy {
    public func write(_ data: DataType, using strategy: DataType.DataEncodingStrategy = DataType.defaultDataEncodingStrategy) throws {
        try set(rawData: data.data(using: strategy))
    }
}

// MARK: - Helpers

extension RegularFile where AccessMode: FileAccessModeTypeForReading, DataType == String {
    public var utf8Data: String {
        try! data(using: .init(encoding: .utf8))
    }
}

extension RegularFile where AccessMode: FileAccessModeTypeForUpdating, DataType == String {
    public var utf8Data: String {
        get {
            try! data(using: .init(encoding: .utf8))
        } set {
            try! set(rawData: newValue.data(using: .init(encoding: .utf8, allowLossyConversion: false)))
        }
    }
    
    public var utf16Data: String {
        get {
            try! data(using: .init(encoding: .utf16))
        } set {
            try! set(rawData: newValue.data(using: .init(encoding: .utf16, allowLossyConversion: false)))
        }
    }
}
