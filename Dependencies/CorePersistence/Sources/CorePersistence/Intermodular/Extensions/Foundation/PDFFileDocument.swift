//
// Copyright (c) Vatsal Manot
//

#if canImport(PDFKit)

import PDFKit
import Swallow
import SwiftUI
import UniformTypeIdentifiers

public struct PDFFileDocument: Hashable, Initiable {
    public let pdf: PDFDocument
    
    public init(pdf: PDFDocument) {
        self.pdf = pdf
    }
    
    public init() {
        self.init(pdf: PDFDocument())
    }
}

extension PDFFileDocument: _FileDocument {
    public static var readableContentTypes = [UTType.pdf]
    
    public init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            pdf = try PDFDocument(data: data).unwrap()
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try pdf.dataRepresentation().unwrap())
    }
}

#endif
