//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import SwiftUI
import UniformTypeIdentifiers

public struct JSONL {
    public let storage: [JSON]
    
    public init(storage: [JSON]) {
        self.storage = storage
    }
    
    private static func parseJSONL(
        from jsonlString: String
    ) -> [JSON] {
        var parsedObjects: [JSON] = []
        var currentObject = ""
        var braceDepth = 0
        var isInString = false
        var isEscape = false
        
        for character in jsonlString {
            if character == "\"" && !isEscape {
                isInString.toggle()
            }
            
            if isInString {
                if character == "\\" && !isEscape {
                    isEscape = true
                } else {
                    isEscape = false
                }
            }
            
            if !isInString {
                if character == "{" {
                    braceDepth += 1
                } else if character == "}" {
                    braceDepth -= 1
                }
            }
            
            if braceDepth == 0 && character == "\n" && !isInString {
                // End of a top-level JSON object
                if let data = currentObject.data(using: .utf8) {
                    do {
                        let parsed = try JSON(data: data)
                        parsedObjects.append(parsed)
                    } catch {
                        print("Error parsing JSON: \(error)")
                    }
                }
                currentObject = ""
            } else {
                currentObject.append(character)
            }
        }
        
        // Parse any remaining JSON object
        if !currentObject.isEmpty {
            if let data = currentObject.data(using: .utf8) {
                do {
                    let parsed = try JSON(data: data)
                    parsedObjects.append(parsed)
                } catch {
                    print("Error parsing JSON: \(error)")
                }
            }
        }
        
        return parsedObjects
    }
}

extension JSONL {
    public init(data: Data) throws {
        let string = try String(data: data, encoding: .utf8).unwrap()
        
        self.init(storage: Self.parseJSONL(from: string))
    }
    
    public func data() throws -> Data {
        var jsonlString = ""
        
        for json in self.storage {
            let lineData = try json.data()
            
            if var lineString = String(data: lineData, encoding: .utf8) {
                lineString = lineString
                    .replacingOccurrences(of: "\\", with: "\\\\") // Double escape backslashes first
                    .replacingOccurrences(of: "\"", with: "\\\"") // Then escape quotes
                jsonlString += lineString + "\n"
            }
        }
        
        return try jsonlString.data(using: .utf8).unwrap()
    }
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension JSONL: FileDocument {
    public static var readableContentTypes: [UTType] {
        [.text, .utf8PlainText]
    }
    
    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        try self.init(data: data)
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        do {
            return try FileWrapper(regularFileWithContents: data())
        } catch {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
}
