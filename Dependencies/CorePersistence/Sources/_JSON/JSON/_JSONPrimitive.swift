//
// Copyright (c) Vatsal Manot
//

#if canImport(Foundation)
import Foundation
#endif

import Swallow

/// One of the four primitive types that JSON can represent.
///
/// https://www.rfc-editor.org/rfc/rfc7159.txt
/// "JSON can represent four primitive types (strings, numbers, booleans, and null) and two structured types (objects and arrays)."
public protocol _JSONPrimitive {
    static func _getJSONPrimitiveType() -> _JSONPrimitiveType
}

public enum _JSONPrimitiveType: String, Codable, Hashable {
    case null
    case boolean
    case number
    case string

    var _swiftType: any _JSONPrimitive.Type {
        switch self {
            case .null:
                #if canImport(Foundation)
                return NSNull.self
                #else
                fatalError(.unsupported)
                #endif
            case .boolean:
                return Bool.self
            case .number:
                return AnyNumber.self
            case .string:
                return String.self
        }
    }
}

extension Bool: _JSONPrimitive {
    public static func _getJSONPrimitiveType() -> _JSONPrimitiveType {
        .boolean
    }
}

extension String: _JSONPrimitive {
    public static func _getJSONPrimitiveType() -> _JSONPrimitiveType {
        .string
    }
}

extension AnyNumber: _JSONPrimitive {
    public static func _getJSONPrimitiveType() -> _JSONPrimitiveType {
        .number
    }
}

#if canImport(Foundation)
extension NSNull: _JSONPrimitive {
    public static func _getJSONPrimitiveType() -> _JSONPrimitiveType {
        .null
    }
}
#endif
