//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

/// Broad description of the JSON schema. It is agnostic and independent of any programming language.
///
/// Based on: https://json-schema.org/draft/2019-09/json-schema-core.html it implements
/// only concepts used in the `rum-events-format` schemas.
public struct JSONSchema: Codable, Hashable, Sendable {
    public enum CodingKeys: String, CodingKey {
        case id = "$id"
        case title = "title"
        case description = "description"
        case properties = "properties"
        case additionalProperties = "additionalProperties"
        case required = "required"
        case type = "type"
        case `enum` = "enum"
        case const = "const"
        case items = "items"
        case readOnly = "readOnly"
        case ref = "$ref"
        case oneOf = "oneOf"
        case anyOf = "anyOf"
        case allOf = "allOf"
    }
    
    public enum SchemaType: String, Codable, Hashable, Sendable {
        case boolean
        case object
        case array
        case number
        case string
        case integer
    }
    
    public struct SchemaConstant: Codable, Hashable, Sendable {
        public enum Value: Hashable, Sendable {
            case integer(value: Int)
            case string(value: String)
        }
        
        public let value: Value
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            
            switch value {
                case .integer(let intValue):
                    try container.encode(intValue)
                case .string(let stringValue):
                    try container.encode(stringValue)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            
            if let int = try? container.decode(Int.self) {
                value = .integer(value: int)
            } else if let string = try? container.decode(String.self) {
                value = .string(value: string)
            } else {
                let prettyKeyPath = container.codingPath.map({ $0.stringValue }).joined(separator: " → ")
                throw Exception.unimplemented(
                    "The value on key path: `\(prettyKeyPath)` is not supported by `JSONSchemaDefinition.ConstantValue`."
                )
            }
        }
    }
    
    public init(from decoder: Decoder) throws {
        do {
            // First try decoding with keyed container
            let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try keyedContainer.decodeIfPresent(String.self, forKey: .id)
            self.title = try keyedContainer.decodeIfPresent(String.self, forKey: .title)
            self.description = try keyedContainer.decodeIfPresent(String.self, forKey: .description)
            self.properties = try keyedContainer.decodeIfPresent([String: JSONSchema].self, forKey: .properties)
            self.additionalProperties = try keyedContainer.decodeIfPresent(JSONSchema.self, forKey: .additionalProperties)
            self.required = try keyedContainer.decodeIfPresent([String].self, forKey: .required)
            self.type = try keyedContainer.decodeIfPresent(SchemaType.self, forKey: .type)
            self.enum = try keyedContainer.decodeIfPresent([EnumValue].self, forKey: .enum)
            self.const = try keyedContainer.decodeIfPresent(SchemaConstant.self, forKey: .const)
            self.items = try keyedContainer.decodeIfPresent(JSONSchema.self, forKey: .items)
            self.readOnly = try keyedContainer.decodeIfPresent(Bool.self, forKey: .readOnly)
            self.ref = try keyedContainer.decodeIfPresent(String.self, forKey: .ref)
            self.allOf = try keyedContainer.decodeIfPresent([JSONSchema].self, forKey: .allOf)
            self.oneOf = try keyedContainer.decodeIfPresent([JSONSchema].self, forKey: .oneOf)
            self.anyOf = try keyedContainer.decodeIfPresent([JSONSchema].self, forKey: .anyOf)
            
            // RUMM-2266 Patch:
            // If schema doesn't define `type`, but defines `properties`, it is safe to assume
            // that its `.object` schema:
            if self.type == nil && self.properties != nil {
                self.type = .object
            }
        } catch let keyedContainerError as DecodingError {
            // If data in this `decoder` cannot be represented as keyed container, perhaps it encodes
            // a single value. Check known schema values:
            do {
                if decoder.codingPath.last as? JSONSchema.CodingKeys == .additionalProperties {
                    // Handle `additionalProperties: true | false`
                    let singleValueContainer = try decoder.singleValueContainer()
                    let hasAdditionalProperties = try singleValueContainer.decode(Bool.self)
                    
                    if hasAdditionalProperties {
                        self.type = .object
                    } else {
                        throw Exception.moreContext(
                            "Decoding `additionalProperties: false` is not supported in `JSONSchema.init(from:)`.",
                            for: keyedContainerError
                        )
                    }
                } else {
                    throw Exception.moreContext(
                        "Decoding \(decoder.codingPath) is not supported in `JSONSchema.init(from:)`.",
                        for: keyedContainerError
                    )
                }
            } catch let singleValueContainerError {
                throw Exception.moreContext(
                    "Unhandled parsing exception in `JSONSchema.init(from:)`.",
                    for: singleValueContainerError
                )
            }
        }
    }
    
    init() {}
    
    // MARK: - Schema attributes
    
    public enum EnumValue: Codable, Hashable, Sendable {
        case string(String)
        case integer(Int)
        
        public init(from decoder: Decoder) throws {
            let singleValueContainer = try decoder.singleValueContainer()
            if let string = try? singleValueContainer.decode(String.self) {
                self = .string(string)
            } else if let integer = try? singleValueContainer.decode(Int.self) {
                self = .integer(integer)
            } else {
                throw Exception.unimplemented("Trying to decode `EnumValue` but its none of supported values.")
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            
            switch self {
                case .string(let stringValue):
                    try container.encode(stringValue)
                case .integer(let intValue):
                    try container.encode(intValue)
            }
        }
    }
    
    public var id: String?
    public var title: String?
    public var description: String?
    public var properties: [String: JSONSchema]?
    @Indirect
    public var additionalProperties: JSONSchema?
    public var required: [String]?
    public var type: SchemaType?
    public var `enum`: [EnumValue]?
    public var const: SchemaConstant?
    @Indirect
    public var items: JSONSchema?
    public var readOnly: Bool?
    
    /// Reference to another schema.
    /// https://json-schema.org/draft/2019-09/json-schema-core.html#ref
    private var ref: String?
    
    /// Subschemas to be resolved.
    /// https://json-schema.org/draft/2019-09/json-schema-core.html#rfc.section.9.2.1.1
    var allOf: [JSONSchema]?
    
    /// Subschemas to be resolved.
    /// https://json-schema.org/draft/2019-09/json-schema-core.html#rfc.section.9.2.1.2
    var anyOf: [JSONSchema]?
    
    /// Subschemas to be resolved.
    /// https://json-schema.org/draft/2019-09/json-schema-core.html#rfc.section.9.2.1.3
    var oneOf: [JSONSchema]?
    
    
    // MARK: - Schemas Merging
    
    /// Merges all attributes of `otherSchema` into this schema.
    private mutating func merge(with otherSchema: JSONSchema?) {
        guard let otherSchema = otherSchema else {
            return
        }
        
        // Title can be overwritten
        self.title = self.title ?? otherSchema.title
        
        // Description can be overwritten
        self.description = self.description ?? otherSchema.description
        
        // Type can be inferred
        self.type = self.type ?? otherSchema.type
        
        // Properties are accumulated and if both schemas have a property with the same name, property
        // schemas are merged.
        if let selfProperties = self.properties, let otherProperties = otherSchema.properties {
            self.properties = selfProperties.merging(otherProperties) { selfProperty, otherProperty in
                var selfProperty = selfProperty
                selfProperty.merge(with: otherProperty)
                return selfProperty
            }
        } else {
            self.properties = self.properties ?? otherSchema.properties
        }
        
        self.additionalProperties = self.additionalProperties ?? otherSchema.additionalProperties
        
        // Required properties are accumulated.
        if let selfRequired = self.required, let otherRequired = otherSchema.required {
            self.required = selfRequired + otherRequired
        } else {
            self.required = self.required ?? otherSchema.required
        }
        
        // Enumeration values are accumulated.
        if let selfEnum = self.enum, let otherEnum = otherSchema.enum {
            self.enum = selfEnum + otherEnum
        } else {
            self.enum = self.enum ?? otherSchema.enum
        }
        
        // Constant value can be overwritten.
        self.const = self.const ?? otherSchema.const
        
        // If both schemas have Items, their schemas are merged.
        // Otherwise, any non-nil Items schema is taken.
        if var selfItems = self.items, let otherItems = otherSchema.items {
            selfItems.merge(with: otherItems)
            
            self.items = selfItems
        } else {
            self.items = self.items ?? otherSchema.items
        }
        
        // If both schemas define read-only value, the most strict is taken.
        if let selfReadOnly = self.readOnly, let otherReadOnly = otherSchema.readOnly {
            self.readOnly = selfReadOnly || otherReadOnly
        } else {
            self.readOnly = self.readOnly ?? otherSchema.readOnly
        }
        
        // Accumulate `oneOf` schemas
        if let selfOneOf = oneOf, let otherOneOf = otherSchema.oneOf {
            self.oneOf = selfOneOf + otherOneOf
        } else if let otherOneOf = otherSchema.oneOf {
            self.oneOf = otherOneOf
        }
        
        // Accumulate `anyOf` schemas
        if let selfAnyOf = anyOf, let otherAnyOf = otherSchema.anyOf {
            self.anyOf = selfAnyOf + otherAnyOf
        } else if let otherAnyOf = otherSchema.anyOf {
            self.anyOf = otherAnyOf
        }
    }
}

extension Array where Element == JSONSchema.EnumValue {
    func inferrSchemaType() -> JSONSchema.SchemaType? {
        let hasOnlyStrings = allSatisfy { element in
            if case .string = element {
                return true
            }
            return false
        }
        if hasOnlyStrings {
            return .string
        }
        
        let hasOnlyIntegers = allSatisfy { element in
            if case .integer = element {
                return true
            }
            return false
        }
        if hasOnlyIntegers {
            return .number
        }
        
        return nil
    }
}

extension JSONSchema {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode simple properties directly
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(properties, forKey: .properties)
        try container.encodeIfPresent(required, forKey: .required)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(readOnly, forKey: .readOnly)
        try container.encodeIfPresent(ref, forKey: .ref)
        try container.encodeIfPresent(allOf, forKey: .allOf)
        try container.encodeIfPresent(anyOf, forKey: .anyOf)
        try container.encodeIfPresent(oneOf, forKey: .oneOf)
        
        // Encode `enum`
        if let enums = self.enum {
            try container.encode(enums, forKey: .enum)
        }
        
        // Encode `const` using the custom encoding logic of `SchemaConstant`
        try container.encodeIfPresent(const, forKey: .const)
        
        // Explicitly handle `additionalProperties`. Encoding true/false directly or the schema if available.
        if let additionalProperties = self.additionalProperties {
            try container.encode(additionalProperties, forKey: .additionalProperties)
        } else {
            // Since `additionalProperties` was not specified, it's omitted to avoid assuming a default behavior.
            // The behavior here is adjusted to not explicitly encode a default value,
            // adhering to JSON Schema's interpretation norms.
        }
        
        // Encode `items` using the custom encoding logic if present
        try container.encodeIfPresent(items, forKey: .items)
    }
}

extension JSONSchema {
    /// Initializes a JSONSchema with a Swift type, mapping it to the corresponding JSON schema type.
    public init(type: Any.Type) {
        switch type {
            case is Bool.Type:
                self.init(type: .boolean)
            case is String.Type:
                self.init(type: .string)
            case is Int8.Type, is Int16.Type, is Int32.Type, is Int64.Type, is Int.Type:
                self.init(type: .integer)
            case is UInt8.Type, is UInt16.Type, is UInt32.Type, is UInt64.Type, is UInt.Type:
                // Assuming that UInt types are also mapped to 'integer' in JSON schema for simplicity.
                // Adjust based on your requirements.
                self.init(type: .integer)
            case is Float.Type, is Double.Type:
                self.init(type: .number)
            default:
                // Fallback for types that don't have a direct mapping or are complex objects/arrays
                fatalError("Unsupported type for JSONSchema initialization")
        }
    }
    
    /// Basic initializer for setting a schema type directly.
    public init(
        type: SchemaType?,
        description: String? = nil,
        properties: [String: JSONSchema]? = nil,
        required: [String]? = nil,
        additionalProperties: JSONSchema? = nil,
        items: JSONSchema? = nil
    ) {
        self.id = nil
        self.title = nil
        self.description = description
        self.properties = properties
        self.additionalProperties = additionalProperties
        self.required = required
        self.type = type
        self.enum = nil
        self.const = nil
        self.items = items
        self.readOnly = nil
        self.ref = nil
        self.allOf = nil
        self.anyOf = nil
        self.oneOf = nil
    }
}

/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import Foundation

public struct Exception: Error, CustomStringConvertible {
    public let description: String
    
    init(
        _ reason: String,
        file: StaticString,
        line: UInt
    ) {
        // `file` includes slash-separated path, take only the last component:
        let fileName = "\(file)".split(separator: "/").last ?? "\(file)"
        let sourceReference = "🧭 Thrown in \(fileName):\(line)"
        
        self.description = "\(reason)\n\n\(sourceReference)"
    }
    
    public static func inconsistency(_ reason: String, file: StaticString = #fileID, line: UInt = #line) -> Exception {
        Exception("🐞 Inconsistency: \"\(reason)\".", file: file, line: line)
    }
    
    public static func illegal(_ operation: String, file: StaticString = #fileID, line: UInt = #line) -> Exception {
        Exception("⛔️ Illegal operation: \"\(operation)\".", file: file, line: line)
    }
    
    public static func unimplemented(_ operation: String, file: StaticString = #fileID, line: UInt = #line) -> Exception {
        Exception("🚧 Unimplemented: \"\(operation)\".", file: file, line: line)
    }
    
    static func moreContext(_ moreContext: String, for error: Error, file: StaticString = #fileID, line: UInt = #line) -> Exception {
        if let decodingError = error as? DecodingError {
            return Exception(
                """
                ⬇️
                🛑 \(moreContext)
                
                🔎 Pretty error: \(pretty(error: decodingError))
                
                ⚙️ Original error: \(decodingError)
                """,
                file: file,
                line: line
            )
        } else {
            return Exception(
                """
                ⬇️
                🛑 \(moreContext)
                
                ⚙️ Original error: \(error)
                """,
                file: file,
                line: line
            )
        }
    }
}

public extension Optional {
    func unwrapOrThrow(_ exception: Exception) throws -> Wrapped {
        switch self {
            case .some(let unwrappedValue):
                return unwrappedValue
            case .none:
                throw exception
        }
    }
    
    func ifNotNil<T>(_ closure: (Wrapped) throws -> T) rethrows -> T? {
        if case .some(let unwrappedValue) = self {
            return try closure(unwrappedValue)
        } else {
            return nil
        }
    }
}

extension Array where Element: Hashable {
    func asSet() -> Set<Element> {
        return Set(self)
    }
}

internal func withErrorContext<T>(context: String, block: () throws -> T) throws -> T {
    do {
        return try block()
    } catch let error {
        throw Exception.moreContext(context, for: error)
    }
}

// MARK: - `Swift.DecodingError` pretty formatting

/// Returns pretty description of given `DecodingError`.
private func pretty(error: DecodingError) -> String {
    var description = "✋ description is unavailable"
    var context: DecodingError.Context?
    
    switch error {
        case .typeMismatch(let type, let moreContext):
            description = "Type \(type) could not be decoded because it did not match the type of what was found in the encoded payload."
            context = moreContext
        case .valueNotFound(let type, let moreContext):
            description = "Non-optional value of type \(type) was expected, but a null value was found."
            context = moreContext
        case .keyNotFound(let key, let moreContext):
            description = "A keyed decoding container was asked for an entry for key \(key), but did not contain one."
            context = moreContext
        case .dataCorrupted(let moreContext):
            context = moreContext
        @unknown default:
            break
    }
    
    return "\n→ \(description)" + (context.flatMap { pretty(context: $0) } ?? "")
}

/// Returns pretty description of given `DecodingError.Context`.
private func pretty(context: DecodingError.Context) -> String {
    let codingPath: [String] = context.codingPath.map { codingKey in
        if let intValue = codingKey.intValue {
            return String(intValue)
        } else {
            return codingKey.stringValue
        }
    }
    return """
    
    → In Context:
        → coding path: \(codingPath.joined(separator: " → "))
        → underlyingError: \(String(describing: context.underlyingError))
    """
}

// MARK: - String formatting

public extension String {
    var camelCased: String {
        guard !isEmpty else {
            return ""
        }
        
        let words = components(separatedBy: CharacterSet.alphanumerics.inverted)
        let first = words.first! // swiftlint:disable:this force_unwrapping
        let rest = words.dropFirst().map { $0.uppercasingFirst }
        return ([first] + rest).joined(separator: "")
    }
    
    /// Uppercases the first character.
    var uppercasingFirst: String {
        prefix(1).uppercased() + String(self.dropFirst())
    }
    /// Lowercases the first character.
    var lowercasingFirst: String {
        prefix(1).lowercased() + String(self.dropFirst())
    }
    
    /// "lowerCamelCased" notation.
    var lowerCamelCased: String { camelCased.lowercasingFirst }
    /// "UpperCamelCased" notation.
    var upperCamelCased: String { camelCased.uppercasingFirst }
}

