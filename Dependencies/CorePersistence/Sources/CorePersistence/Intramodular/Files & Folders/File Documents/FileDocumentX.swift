//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow
import SwiftUI
import UniformTypeIdentifiers

public struct _FileDocumentReadConfiguration {
    public let contentType: UTType?
    public let file: FileWrapper
    
    public init(
        contentType: UTType?,
        file: FileWrapper
    ) {
        self.contentType = contentType
        self.file = file
    }
    
    public init(
        contentType: UTType?,
        file: _AsyncFileWrapper
    ) {
        self.init(contentType: contentType, file: file.base)
    }
}

public struct ReferenceFileDocumentSnapshotConfiguration {
    public let contentType: UTType?
    
    public init(
        contentType: UTType?
    ) {
        self.contentType = contentType
    }
}

public struct _FileDocumentWriteConfiguration {
    public let contentType: UTType?
    public let existingFile: FileWrapper?
    
    public init(
        contentType: UTType?,
        existingFile: FileWrapper?
    ) {
        self.contentType = contentType
        self.existingFile = existingFile
    }
}

extension _FileDocumentReadConfiguration {
    public init(file: FileWrapper, url: URL?) {
        self.init(
            contentType: url.flatMap({ UTType(from: $0) }),
            file: file
        )
    }
    
    public init(file: _AsyncFileWrapper, url: URL?) {
        self.init(
            contentType: url.flatMap({ UTType(from: $0) }),
            file: file
        )
    }
    
    public init(url: URL) throws {
        try self.init(file: FileWrapper(url: url), url: url)
    }
}

extension _FileDocumentWriteConfiguration {
    public init(
        existingFile: FileWrapper?,
        url: URL?
    ) throws {
        var _existingFile = existingFile
        
        if _existingFile == nil, let url = url, FileManager.default.fileExists(at: url) {
            _existingFile = try FileWrapper(url: url)
        }
        
        self.init(
            contentType: url.flatMap({ UTType(from: $0) }),
            existingFile: _existingFile
        )
    }
    
    @_disfavoredOverload
    public init(
        existingFile: _AsyncFileWrapper?,
        url: URL?
    ) throws {
        try self.init(existingFile: existingFile?.base, url: url)
    }
    
    public init(url: URL?) throws {
        try self.init(existingFile: nil, url: url)
    }
}

public protocol _FileDocument: _FileDocumentProtocol {
    typealias ReadConfiguration = _FileDocumentReadConfiguration
    typealias WriteConfiguration = _FileDocumentWriteConfiguration
    
    static var readableContentTypes: [UTType] { get }
    static var writableContentTypes: [UTType] { get }
    
    init(configuration: ReadConfiguration) throws
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper
}

public protocol _ReferenceFileDocument: _FileDocumentProtocol {
    associatedtype Snapshot
    
    typealias ReadConfiguration = _FileDocumentReadConfiguration
    typealias SnapshotConfiguration = ReferenceFileDocumentSnapshotConfiguration
    typealias WriteConfiguration = _FileDocumentWriteConfiguration
    
    static var readableContentTypes: [UTType] { get }
    static var writableContentTypes: [UTType] { get }
    
    init(configuration: ReadConfiguration) throws
    
    func snapshot(
        configuration: SnapshotConfiguration
    ) throws -> Snapshot
    
    func fileWrapper(
        snapshot: Snapshot,
        configuration: WriteConfiguration
    ) throws -> FileWrapper
}

extension _FileDocument {
    public func _fileWrapper(
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        try fileWrapper(configuration: configuration)
    }
}

extension _ReferenceFileDocument {
    public func _fileWrapper(
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        let contentType = Self.writableContentTypes.first // FIXME!
        let snapshot = try snapshot(
            configuration: SnapshotConfiguration(contentType: contentType)
        )
        
        return try fileWrapper(snapshot: snapshot, configuration: configuration)
    }
}

extension _FileDocumentProtocol {
    static func _opaque_fileWrapper(
        for value: Any,
        configuration: _FileDocumentWriteConfiguration
    ) throws -> FileWrapper {
        try cast(value, to: Self.self)._fileWrapper(configuration: configuration)
    }
}

extension _ReferenceFileDocument {
    func _opaque_fileWrapper(
        snapshot: Any,
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        let snapshot = try cast(snapshot, to: Snapshot.self)
        
        return try fileWrapper(snapshot: snapshot, configuration: configuration)
    }
}

extension _FileDocument {
    public static var readableContentTypes: [UTType] {
        []
    }
    
    public static var writableContentTypes: [UTType] {
        readableContentTypes
    }
}

extension _ReferenceFileDocument {
    public static var readableContentTypes: [UTType] {
        []
    }
    
    public static var writableContentTypes: [UTType] {
        readableContentTypes
    }
}

public struct _FileDocumentConfiguration<Document>: DynamicProperty {
    @Binding public var document: Document
    
    public var fileURL: URL?
    public var isEditable: Bool
    
    public init(
        document: Binding<Document>,
        fileURL: URL? = nil,
        isEditable: Bool
    ) {
        self._document = document
        self.fileURL = fileURL
        self.isEditable = isEditable
    }
}

public struct _ReferenceFileDocumentConfiguration<Document: ObservableObject>: DynamicProperty {
    @ObservedObject public var document: Document
    
    public var fileURL: URL?
    public var isEditable: Bool
    
    public init(
        document: ObservedObject<Document>,
        fileURL: URL? = nil,
        isEditable: Bool
    ) {
        self._document = document
        self.fileURL = fileURL
        self.isEditable = isEditable
    }
}
