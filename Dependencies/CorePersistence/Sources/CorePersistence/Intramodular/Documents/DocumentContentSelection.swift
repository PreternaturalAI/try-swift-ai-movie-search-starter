//
// Copyright (c) Vatsal Manot
//

import Swallow
import UniformTypeIdentifiers

public protocol DocumentContentSelection: Codable, Hashable, Sendable {
    associatedtype Document: _FileDocumentProtocol
}

public enum DefaultDocumentContentSelection<Document: _FileDocumentProtocol>: DocumentContentSelection {
    case wholeDocument
}

public struct _ContentSelectionSpecified<Base: _FileDocumentProtocol, ContentSelection: DocumentContentSelection>: ContentSelectingDocument, _FileDocumentProtocol where ContentSelection.Document == Base {
    public static var readableContentTypes: [UTType] {
        Base.readableContentTypes
    }
    
    public static var writableContentTypes: [UTType] {
        Base.writableContentTypes
    }
    
    public let base: Base
    
    public init(base: Base) {
        self.base = base
    }
    
    public init(configuration: _FileDocumentReadConfiguration) throws {
        try self.init(base: .init(configuration: configuration))
    }
    
    public func _fileWrapper(configuration: _FileDocumentWriteConfiguration) throws -> FileWrapper {
        try base._fileWrapper(configuration: configuration)
    }
}

extension _ContentSelectionSpecified: _FileDocument where Base: _FileDocument {
    public init(configuration: Base.ReadConfiguration) throws {
        try self.init(base: .init(configuration: configuration))
    }
    
    public func fileWrapper(configuration: Base.WriteConfiguration) throws -> FileWrapper {
        try base.fileWrapper(configuration: configuration)
    }
}
