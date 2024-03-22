//
// Copyright (c) Vatsal Manot
//

import Swallow

extension JSON {
    public static func _extractJSONStrings(
        fromMarkdown markdown: String
    ) throws -> [(substring: Substring, json: JSON)] {
        enum ExtractionError: Error {
            case malformedJSON
        }
        
        var possibleJSONStrings: [Substring] = []
        var depth = 0
        var startIndex: String.Index?
        
        for (index, char) in markdown._enumerated() {
            if char == "{" {
                if depth == 0 {
                    startIndex = index
                }
                depth += 1
            } else if char == "}" {
                depth -= 1
                
                if depth == 0, let start = startIndex {
                    let range = start...index
                    
                    possibleJSONStrings.append(markdown[range])
                    
                    startIndex = nil
                }
            }
        }
        
        if depth != 0 {
            throw _PlaceholderError()
        }
        
        return possibleJSONStrings.compactMap {
            try? ($0, JSON(jsonString: String($0)))
        }
    }
}

extension String {
    public func formattingJSON() throws -> (formatted: String, isAllJSON: Bool) {
        let replacements = try JSON._extractJSONStrings(fromMarkdown: self).map({ ($0.substring, $0.json.prettyPrintedDescription) })
        
        let isAllJSON = (replacements.count == 1 && replacements.first!.0.bounds == bounds)
        let formatted = replacingSubstrings(replacements.map(\.0), with: replacements.map({ "```json\n\($0.1)\n```" }))
        
        return (formatted, isAllJSON)
    }
}
