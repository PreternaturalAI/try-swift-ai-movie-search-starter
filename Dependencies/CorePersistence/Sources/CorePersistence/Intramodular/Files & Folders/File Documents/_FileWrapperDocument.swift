//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import FoundationX
import Swallow
import UniformTypeIdentifiers

public struct _FileWrapperDocument: _FileDocument {
    public static var readableContentTypes: [UTType] {
        []
    }
    
    public let fileWrapper: FileWrapper
    public let contentType: UTType?
    
    public init(fileWrapper: FileWrapper, contentType: UTType? = nil) {
        self.fileWrapper = fileWrapper
        self.contentType = contentType
    }
    
    public init(configuration: ReadConfiguration) throws {
        self.fileWrapper = configuration.file
        self.contentType = configuration.contentType
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        fileWrapper
    }
}

extension _FileWrapperDocument {
    public var regularFileContents: Data {
        get throws {
            try _tryAssert(!fileWrapper.isDirectory)
            
            return try fileWrapper.regularFileContents.unwrap()
        }
    }
}
