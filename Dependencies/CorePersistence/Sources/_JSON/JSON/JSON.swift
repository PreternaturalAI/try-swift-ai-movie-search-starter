//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
#if canImport(SwiftUI)
import SwiftUI
#endif
import UniformTypeIdentifiers

/// A type that represents JSON data.
public enum JSON: Hashable, Initiable, Sendable {
    case null
    case bool(Bool)
    case date(Date)
    case number(JSONNumber)
    case string(String)
    case array([JSON])
    case dictionary([String: JSON])
    
    public init() {
        self = .null
    }
}

// MARK: - Extensions

extension JSON {
    /// A Boolean value indicating whether the JSON is empty.
    public var isEmpty: Bool {
        switch self {
            case .null:
                return true
            case .bool(_):
                return false
            case .date(_):
                return false
            case .number(_):
                return false
            case .string(let value):
                return value.isEmpty
            case .array(let value):
                return value.isEmpty
            case .dictionary(let value):
                return value.isEmpty
        }
    }
    
    public var rawValue: Any? {
        switch self {
            case .null:
                return nil
            case .bool(let value):
                return value
            case .date(let value):
                return value
            case .number(let value):
                return value.rawValue
            case .string(let value):
                return value
            case .array(let value):
                return value.compactMap({ $0.rawValue })
            case .dictionary(let value): do {
                let keysWithValues: [(String, Any)] = value.compactMap {
                    if let rawValue = $0.value.rawValue {
                        return ($0.key, rawValue)
                    } else {
                        return nil
                    }
                }
                return Dictionary(uniqueKeysWithValues: keysWithValues)
            }
        }
    }
    
    public var unorderedHashValue: Int {
        // Use a set so that the resulting hash is independent of order.
        var set: Set<AnyHashable> = []
        
        switch self {
            case .null:
                break
            case .bool(let value):
                _ = set.insert(value)
            case .date(let value):
                _ = set.insert(value)
            case .number(let value):
                _ = set.insert(value)
            case .string(let value):
                _ = set.insert(value)
            case .array(let value): do {
                value.lazy
                    .filter { $0 != .null }
                    .forEach { _ = set.insert($0.unorderedHashValue) }
            }
            case .dictionary(let value): do {
                value.lazy
                    .filter { $0.value != .null }
                    .forEach({
                        _ = set.insert($0.key)
                        _ = set.insert($0.value.unorderedHashValue)
                    })
            }
        }
        
        return set.hashValue
    }
}

// MARK: - Conformances

extension JSON: Codable {
    public func encode(to encoder: Encoder) throws {
        switch self {
            case .null:
                var container = encoder.singleValueContainer()
                try container.encodeNil()
            case .bool(let value):
                var container = encoder.singleValueContainer()
                try container.encode(value)
            case .date(let value):
                var container = encoder.singleValueContainer()
                try container.encode(value)
            case .number(let value):
                var container = encoder.singleValueContainer()
                try container.encode(value)
            case .string(let value):
                var container = encoder.singleValueContainer()
                try container.encode(value)
            case .array(let value):
                var container = encoder.unkeyedContainer()
                try value.forEach({ try container.encode($0) })
            case .dictionary(let value):
                var container = encoder.container(keyedBy: JSONCodingKey.self)
                try value.forEach({ try container.encode($0.value, forKey: .init(stringValue: $0.key)) })
        }
    }
    
    public init(from decoder: Decoder) throws {
        // JSON can roughly be either of three things: a primitive, an array or a dictionary.
        // Single value containers encode primitives.
        // Unkeyed containers encode sequences (i.e. arrays).
        // Keyed containers encode dictionaries.
        // If it is neither of these three things, it is null.
        if let singleValueContainer = try? decoder.singleValueContainer() {
            if singleValueContainer.decodeNil() {
                self = .null
            } else if let value = try? singleValueContainer.decode(Bool.self) {
                self = .bool(value)
            } else if let value = try? singleValueContainer.decode(JSONNumber.self) {
                self = .number(value)
            } else if let value = try? singleValueContainer.decode(String.self) {
                self = .string(value)
            } else if let value = try? singleValueContainer.decode([JSON].self) {
                self = .array(value)
            } else if let value = try? singleValueContainer.decode([String: JSON].self) {
                self = .dictionary(value)
            } else {
                throw DecodingError.dataCorruptedError(in: singleValueContainer, debugDescription: "Could not decode JSON from the given container.")
            }
        } else if var unkeyedContainer = try? decoder.unkeyedContainer() {
            var value: [JSON] = []
            
            unkeyedContainer.count.map({ value.reserveCapacity($0) })
            
            while !unkeyedContainer.isAtEnd {
                value.append(try unkeyedContainer.decode(JSON.self))
            }
            
            self = .array(value)
            
        } else if let keyedContainer = try? decoder.container(keyedBy: JSONCodingKey.self) {
            var value: [String: JSON] = [:]
            
            value.reserveCapacity(keyedContainer.allKeys.count)
            
            for key in keyedContainer.allKeys {
                value[key.stringValue] = try keyedContainer.decode(JSON.self, forKey: key)
            }
            
            self = .dictionary(value)
        } else {
            self = .null // you ain't got nothin' ¯\_(ツ)_/¯
        }
    }
}

extension JSON: CustomStringConvertible {
    public var description: String {
        switch self {
            case .null:
                return "(null)"
            case .bool(let value):
                return value.description
            case .date(let value):
                return value.description
            case .number(let value):
                return value.description
            case .string(let value):
                return value.description
            case .array(let value):
                return value.description
            case .dictionary(let value):
                return value.description
        }
    }
    
    public var prettyPrintedDescription: String {
        do {
            return try toString(prettyPrint: true)
        } catch {
            assertionFailure()
            
            return description
        }
    }
}

extension JSON: DataDecodableWithDefaultStrategy {
    public struct DataDecodingStrategy {
        public let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?
        public let dataDecodingStrategy: JSONDecoder.DataDecodingStrategy?
        public let keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy?
        public let nonComformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy?
        
        public init(
            dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil,
            dataDecodingStrategy: JSONDecoder.DataDecodingStrategy? = nil,
            keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy? = nil,
            nonComformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy? = nil
        ) {
            self.dateDecodingStrategy = dateDecodingStrategy
            self.dataDecodingStrategy = dataDecodingStrategy
            self.keyDecodingStrategy = keyDecodingStrategy
            self.nonComformingFloatDecodingStrategy = nonComformingFloatDecodingStrategy
        }
    }
    
    public static var defaultDataDecodingStrategy: DataDecodingStrategy {
        return DataDecodingStrategy()
    }
    
    public init(data: Data, using strategy: DataDecodingStrategy) throws {
        guard !data.isEmpty else {
            self = .null
            
            return
        }
        
        let decoder = JSONDecoder()
        
        decoder.dateDecodingStrategy =?? strategy.dateDecodingStrategy
        decoder.dataDecodingStrategy =?? strategy.dataDecodingStrategy
        decoder.keyDecodingStrategy =?? strategy.keyDecodingStrategy
        decoder.nonConformingFloatDecodingStrategy =?? strategy.nonComformingFloatDecodingStrategy
        
        self = try decoder.decode(JSON.self, from: data, allowFragments: true)
    }
}

extension JSON: DataEncodableWithDefaultStrategy {
    public struct DataEncodingStrategy {
        public let dateEncodingStrategy: JSONEncoder.DateEncodingStrategy?
        public let dataEncodingStrategy: JSONEncoder.DataEncodingStrategy?
        public let keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy?
        public let nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy?
        
        public init(
            dateEncodingStrategy: JSONEncoder.DateEncodingStrategy? = nil,
            dataEncodingStrategy: JSONEncoder.DataEncodingStrategy? = nil,
            keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy? = nil,
            nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy? = nil
        ) {
            self.dataEncodingStrategy = dataEncodingStrategy
            self.dateEncodingStrategy = dateEncodingStrategy
            self.keyEncodingStrategy = keyEncodingStrategy
            self.nonConformingFloatEncodingStrategy = nonConformingFloatEncodingStrategy
        }
    }
    
    public static var defaultDataEncodingStrategy: DataEncodingStrategy {
        return DataEncodingStrategy()
    }
    
    public func data(using strategy: DataEncodingStrategy) throws -> Data {
        let encoder = JSONEncoder()
        
        encoder.dateEncodingStrategy =?? strategy.dateEncodingStrategy
        encoder.dataEncodingStrategy =?? strategy.dataEncodingStrategy
        encoder.keyEncodingStrategy =?? strategy.keyEncodingStrategy
        encoder.nonConformingFloatEncodingStrategy =?? strategy.nonConformingFloatEncodingStrategy
        
        return try encoder.encode(self)
    }
}

extension JSON: Equatable {
    public static func == (lhs: JSON, rhs: JSON) -> Bool {
        switch (lhs, rhs) {
            case (.null, .null):
                return true
            case (.bool(let x), .bool(let y)):
                return x == y
            case (.number(let x), .number(let y)):
                return x == y
            case (.string(let x), .string(let y)):
                return x == y
            case (.array(let x), .array(let y)):
                return x == y
            case (.dictionary(let x), .dictionary(let y)):
                return x == y
                
            default:
                return false
        }
    }
}

extension JSON: ExpressibleByArrayLiteral {
    public init(_ elements: some Collection<Self>) {
        self = .array(.init(elements))
    }

    public init(arrayLiteral elements: Self...) {
        self = .array(elements)
    }
}

extension JSON: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension JSON: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSON)...) {
        self = .dictionary(Dictionary(elements))
    }
}

extension JSON: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(.init(value))
    }
}

extension JSON: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(.init(value))
    }
}

extension JSON: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension JSON: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

#if canImport(SwiftUI)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension JSON: FileDocument {
    public static var readableContentTypes: [UTType] {
        [.json]
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
#endif

// MARK: - Auxiliary Extensions

extension JSON {
    public var isTopLevelFragment: Bool {
        switch self {
            case .null:
                return true
            case .bool:
                return true
            case .date:
                return true
            case .number:
                return true
            case .string:
                return true
            case .array:
                return false
            case .dictionary:
                return false
        }
    }
    
    public var topLevelFragmentData: Data? {
        if isTopLevelFragment {
            let text: String?
            switch self {
                case .null:
                    text = "null"
                case .bool(let value):
                    text = value ? "true" : "false"
                case .date(let value):
                    text = value.timeIntervalSinceReferenceDate.description
                case .number(let value):
                    text = value.description
                case .string(let value):
                    text = "\"\(value)\""
                case .array:
                    text = nil
                case .dictionary:
                    text = nil
            }
            return try! text?.data(using: .utf8).unwrap()
        } else {
            return nil
        }
    }
}

extension JSON {    
    public var boolValue: Bool? {
        get {
            guard case let .bool(result) = self else {
                return nil
            }
            return result
        } set {
            if let newValue = newValue {
                self = .bool(newValue)
            } else {
                self = boolValue != nil ? .null : self
            }
        }
    }
    
    public var numberValue: JSONNumber? {
        get {
            guard case let .number(result) = self else {
                return nil
            }
            return result
        } set {
            if let newValue = newValue {
                self = .number(newValue)
            } else {
                self = numberValue != nil ? .null : self
            }
        }
    }
    
    public var integerValue: Int? {
        if let integerValue = numberValue?.integerValue {
            return integerValue
        } else {
            switch self {
                case .bool(let value):
                    return value.toInt()
                default:
                    return nil
            }
        }
    }
    
    public var stringValue: String? {
        get {
            guard case let .string(result) = self else {
                return nil
            }
            return result
        } set {
            if let newValue = newValue {
                self = .string(newValue)
            } else {
                self = stringValue != nil ? .null : self
            }
        }
    }
    
    public var arrayValue: [JSON]? {
        get {
            guard case let .array(result) = self else {
                return nil
            }
            return result
        } set {
            if let newValue = newValue {
                self = .array(newValue)
            } else {
                self = arrayValue != nil ? .null : self
            }
        }
    }
    
    public var dictionaryValue: [String: JSON]? {
        get {
            guard case let .dictionary(result) = self else {
                return nil
            }
            return result
        } set {
            if let newValue = newValue {
                self = .dictionary(newValue)
            } else {
                self = dictionaryValue != nil ? .null : self
            }
        }
    }
    
    public var arrayOrDictionaryValue: Either<[JSON], [String: JSON]>? {
        if case .array(let value) = self {
            return .left(value)
        } else if case .dictionary(let value) = self {
            return .right(value)
        } else {
            return nil
        }
    }
}

extension JSON {
    public static func encode<T: Encodable>(_ value: T) throws -> JSON {
        let data =  try JSONEncoder().encode(value, allowFragments: true)
        
        do {
            return try JSONDecoder().decode(JSON.self, from: data, allowFragments: true)
        } catch {
            if let _ = try? JSONDecoder().decode(JSON.Empty.self, from: data) {
                return .null
            } else {
                throw error
            }
        }
    }
    
    public func decode<T: Decodable>(
        _ type: T.Type = T.self,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil,
        dataDecodingStrategy: JSONDecoder.DataDecodingStrategy? = nil,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy? = nil,
        nonConformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy? = nil
    ) throws -> T {
        if case .string(let string) = self, type == String.self {
            return string as! T
        }
        
        if self == .null {
            if let type = type as? ExpressibleByNilLiteral.Type {
                return type.init(nilLiteral: ()) as! T
            }
        }
        
        let decoder = JSONDecoder(
            dateDecodingStrategy: dateDecodingStrategy,
            dataDecodingStrategy: dataDecodingStrategy,
            keyDecodingStrategy: keyDecodingStrategy,
            nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
        )
        
        return try decoder.decode(T.self, from: try Data(json: self), allowFragments: true)
    }
    
    public init(jsonString string: String) throws {
        try self.init(data: try string.data(using: .utf8).unwrap())
    }
}

extension JSON {
    public subscript(_ index: Int) -> JSON? {
        arrayValue?[index]
    }
            
    public subscript(_ key: String) -> JSON? {
        get {
            return dictionaryValue?[key]
        } set {
            dictionaryValue?[key] = newValue
        }
    }
    
    public subscript(unsafelyUnwrapped index: Int) -> JSON {
        get {
            return arrayValue.unsafelyUnwrapped[index]
        } set {
            var arrayValue = self.arrayValue.unsafelyUnwrapped
            arrayValue[index] = newValue
            self = .array(arrayValue)
        }
    }
    
    public subscript(unsafelyUnwrapped key: String) -> JSON? {
        get {
            return dictionaryValue.unsafelyUnwrapped[key]
        } set {
            var dictionaryValue = self.dictionaryValue.unsafelyUnwrapped
            dictionaryValue[key] = newValue
            self = .dictionary(dictionaryValue)
        }
    }
}

extension Optional where Wrapped == JSON {
    public subscript(_ index: Int) -> Self {
        self?[index]
    }
    
    public subscript(_ key: String) -> Self {
        get {
            self?[key]
        } set {
            self?[key] = newValue
        }
    }
    
    public func decode<T: Decodable>(
        _ type: T.Type = T.self,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil,
        dataDecodingStrategy: JSONDecoder.DataDecodingStrategy? = nil,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy? = nil,
        nonConformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy? = nil
    ) throws -> T {
        try unwrap().decode(
            type,
            dateDecodingStrategy: dateDecodingStrategy,
            dataDecodingStrategy: dataDecodingStrategy,
            keyDecodingStrategy: keyDecodingStrategy,
            nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
        )
    }
}

extension JSON {
    public func toData(
        prettyPrint: Bool = false,
        sortKeys: Bool = false
    ) throws -> Data {
        let encoder = JSONEncoder()
        
        encoder.outputFormatting.formUnion(prettyPrint ? [.prettyPrinted] : [])
        encoder.outputFormatting.formUnion(sortKeys ? [.sortedKeys] : [])

        return try encoder.encode(self, allowFragments: true)
    }
    
    public func toString(
        prettyPrint: Bool = false,
        sortKeys: Bool = false
    ) throws -> String {
        try String(data: toData(prettyPrint: prettyPrint, sortKeys: sortKeys), encoding: .utf8)!
    }
}
