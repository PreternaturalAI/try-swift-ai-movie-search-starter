//
// Copyright (c) Vatsal Manot
//

import Combine
import FoundationX
import Swallow

public struct TOMLCoder: TopLevelDataCoder {
    public init() {
        
    }
    
    public func encode<T: Encodable>(
        _ value: T
    ) throws -> Data  {
        let data: [String: AnyCodable] = try AnyCodable(destructuring: value)
            ._dictionaryValue
            .unwrap()
            .mapKeys({ $0.stringValue })
        
        let rawString: String = try _RawTOMLDecoderEncoder().encode(data)
        
        return try rawString.data(using: .utf8).unwrap()
    }
    
    public func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data
    ) throws -> T  {
        let rawToml: String = try String(data: data, encoding: .utf8).unwrap()
        
        let data: [String: AnyCodable] = try _RawTOMLDecoderEncoder().decode(rawToml)
        
        return try T(from: AnyCodable.dictionary(data))
    }
}

public class _RawTOMLDecoderEncoder {
    public init() {
        
    }
}

extension _RawTOMLDecoderEncoder {
    public func decode(
        _ tomlString: String
    ) throws -> [String: AnyCodable] {
        var result: [String: AnyCodable] = [:]
        let lines = tomlString.components(separatedBy: .newlines)
        
        var currentDictionary: [String: AnyCodable] = [:] // Represents the current section or top-level
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.isEmpty || trimmedLine.starts(with: "#") {
                continue
            }
            
            if trimmedLine.starts(with: "[") && trimmedLine.hasSuffix("]") {
                if !currentDictionary.isEmpty {
                    // Assuming currentKey is not nil as the currentDictionary is not empty
                    // and was filled in a section before
                    result[currentDictionary.keys.first!] = .dictionary(try currentDictionary.values.first.unwrap()._dictionaryValue.unwrap())
                    
                    currentDictionary.removeAll()
                }
                let currentKey = trimmedLine.trimmingCharacters(in: .init(charactersIn: "[]"))
                
                // Initialize a new dictionary for the new section
                currentDictionary[currentKey] = .dictionary([:])
            } else {
                let parts = trimmedLine.components(separatedBy: "=")
                if parts.count == 2 {
                    let keyName = parts[0].trimmingCharacters(in: .whitespaces)
                    let value = parseValue(parts[1].trimmingCharacters(in: .whitespaces))
                    
                    // If we are within a section
                    if let sectionKey = currentDictionary.keys.first,
                       case .dictionary(var dict) = currentDictionary[sectionKey] {
                        dict[AnyCodingKey(stringValue: keyName)] = value
                        currentDictionary[sectionKey] = .dictionary(dict)
                    } else {
                        // Top-level key-value pair
                        result[keyName] = value
                    }
                }
            }
        }
        
        // Handle the last section or top-level dictionary if not already added
        if !currentDictionary.isEmpty {
            result[currentDictionary.keys.first!] = .dictionary(try currentDictionary.values.first.unwrap()._dictionaryValue.unwrap())
        }
        
        return result
    }
    
    private func parseValue(_ valueString: String) -> AnyCodable {
        if let intValue = Int(valueString) {
            return .number(intValue)
        } else if let doubleValue = Double(valueString) {
            return .number(doubleValue)
        } else if let boolValue = parseBool(valueString) {
            return .bool(boolValue)
        } else if let arrayValue = parseArray(valueString) {
            return .array(arrayValue)
        } else {
            return .string(valueString)
        }
    }
    
    private func parseBool(_ valueString: String) -> Bool? {
        if valueString.lowercased() == "true" {
            return true
        } else if valueString.lowercased() == "false" {
            return false
        }
        return nil
    }
    
    private func parseArray(_ valueString: String) -> [AnyCodable]? {
        if valueString.starts(with: "[") && valueString.hasSuffix("]") {
            let arrayString = valueString.trimmingCharacters(in: .init(charactersIn: "[]"))
            let elements = arrayString.components(separatedBy: ",")
            
            return elements.map {
                parseValue($0.trimmingCharacters(in: .whitespaces))
            }
        }
        
        return nil
    }
}

extension _RawTOMLDecoderEncoder {
    public func encode(_ dict: [String: AnyCodable]) throws -> String {
        var result = ""
        
        for (key, value) in dict {
            result += encodeKeyValue(key: key, value: value)
        }
        
        return result
    }
    
    private func encodeKeyValue(key: String, value: AnyCodable) -> String {
        var result = ""
        
        switch value {
            case .string(let stringValue):
                result += "\(key) = \"\(stringValue)\"\n"
            case .number(let numberValue):
                result += "\(key) = \(numberValue)\n"
            case .bool(let boolValue):
                result += "\(key) = \(boolValue)\n"
            case .array(let arrayValue):
                result += "\(key) = \(encodeArray(arrayValue))\n"
            case .dictionary(let dictValue):
                result += "[\(key)]\n"
                for (subKey, subValue) in dictValue {
                    result += encodeKeyValue(key: subKey.stringValue, value: subValue)
                }
                result += "\n"
            case .none:
                result += "\(key) = null\n"
            default:
                fatalError()
        }
        
        return result
    }
    
    private func encodeArray(_ array: [AnyCodable]) -> String {
        let elements = array.map { encodeValue($0) }.joined(separator: ", ")
        return "[\(elements)]"
    }
    
    private func encodeValue(_ value: AnyCodable) -> String {
        switch value {
            case .string(let stringValue):
                return "\"\(stringValue)\""
            case .number(let numberValue):
                return "\(numberValue)"
            case .bool(let boolValue):
                return "\(boolValue)"
            case .array(let arrayValue):
                return encodeArray(arrayValue)
            case .dictionary(let dictValue):
                let elements = dictValue.map { "\($0.key.stringValue) = \(encodeValue($0.value))" }.joined(separator: ", ")
                return "{\(elements)}"
            case .none:
                return "null"
            default:
                fatalError()
        }
    }
}
