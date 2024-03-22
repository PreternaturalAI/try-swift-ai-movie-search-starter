//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import FoundationX
import Swallow
import UniformTypeIdentifiers

public struct _JSONCodingDocument<Value: Codable>: _FileDocument {
    public static var readableContentTypes: [UTType] {
        [UTType.json]
    }
    
    public let value: Value
    
    public init(value: Value) {
        self.value = value
    }
    
    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        self.value = try JSONCoder().decode(Value.self, from: data)
    }
    
    public func fileWrapper(
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        let data = try JSONCoder().encode(value)
        
        return FileWrapper(regularFileWithContents: data)
    }
}
