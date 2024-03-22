//
// Copyright (c) Vatsal Manot
//

import UniformTypeIdentifiers

public protocol _FileDocumentProtocol {
    static var readableContentTypes: [UTType] { get }
    static var writableContentTypes: [UTType] { get }
    
    init(configuration: _FileDocumentReadConfiguration) throws
    
    func _fileWrapper(configuration: _FileDocumentWriteConfiguration) throws -> FileWrapper
}
