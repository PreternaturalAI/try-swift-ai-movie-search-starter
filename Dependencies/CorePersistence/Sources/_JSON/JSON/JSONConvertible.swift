//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

protocol JSONConvertible {
    func json() throws -> JSON
}

// MARK: - Conformances

extension Array: JSONConvertible {
    @usableFromInline
    func json() throws -> JSON {
        return try .array(map({ try JSON(unknown: $0) }))
    }
}

extension Bool: JSONConvertible {
    @usableFromInline
    func json() -> JSON {
        return .bool(self)
    }
}

extension ContiguousArray: JSONConvertible {
    @usableFromInline
    func json() throws -> JSON {
        return try .array(map({ try JSON(unknown: $0) }))
    }
}

extension Dictionary: JSONConvertible {
    @usableFromInline
    func json() throws -> JSON {
        return try .dictionary(
            .init(uniqueKeysWithValues: map {
                (try cast($0.0) as String, try JSON(unknown: $0.1))
            })
        )
    }
}

extension Double: JSONConvertible {
    @usableFromInline
    func json() -> JSON {
        return .number(.init(self))
    }
}

extension Float: JSONConvertible {
    @usableFromInline
    func json() -> JSON {
        return .number(.init(Double(self)))
    }
}

extension Int: JSONConvertible {
    @usableFromInline
    func json() -> JSON {
        return .number(.init(self))
    }
}

extension Int16: JSONConvertible {
    @usableFromInline
    func json() -> JSON {
        return .number(.init(self))
    }
}

extension Int32: JSONConvertible {
    @usableFromInline
    func json() -> JSON {
        return .number(.init(self))
    }
}

extension Int64: JSONConvertible {
    @usableFromInline
    func json() -> JSON {
        return .number(.init(self))
    }
}

extension JSON: JSONConvertible {
    @usableFromInline
    func json() -> JSON {
        return self
    }
}

extension Set: JSONConvertible {
    @usableFromInline
    func json() throws -> JSON {
        return try Array(self).json()
    }
}

extension String: JSONConvertible {
    @usableFromInline
    func json() -> JSON {
        return .string(self)
    }
}

extension NSArray: JSONConvertible {
    @usableFromInline
    func json() throws -> JSON {
        return try (self as [AnyObject]).json()
    }
}

extension NSDictionary: JSONConvertible {
    @usableFromInline
    func json() throws -> JSON {
        return try (self as Dictionary).json()
    }
}

extension NSNull: JSONConvertible {
    @usableFromInline
    func json() -> JSON {
        return .null
    }
}

import Runtime

extension NSNumber: JSONConvertible {
    private func toSwiftNumber() throws -> Any {
        if let value = self as? Bool {
            return value
        } else if let value = self as? Double {
            return value
        } else if let value = self as? Float {
            return value
        } else if let value = self as? Int {
            return value
        } else if let value = self as? Int8 {
            return value
        } else if let value = self as? Int16 {
            return value
        } else if let value = self as? Int32 {
            return value
        } else if let value = self as? Int64 {
            return value
        } else if let value = self as? UInt {
            return value
        } else if let value = self as? UInt8 {
            return value
        } else if let value = self as? UInt16 {
            return value
        } else if let value = self as? UInt32 {
            return value
        } else if let value = self as? UInt64 {
            return value
        } else {
            throw JSON.RuntimeError.irrepresentableNumber(self)
        }
    }
    
    @usableFromInline
    func json() throws -> JSON {
        return try JSON(unknown: try toSwiftNumber())
    }
}

extension NSSet: JSONConvertible {
    @usableFromInline
    func json() throws -> JSON {
        return try (self as Set).json()
    }
}

extension NSString: JSONConvertible {
    @usableFromInline
    func json() -> JSON {
        return (self as String).json()
    }
}

extension UInt: JSONConvertible {
    @usableFromInline
    func json() throws -> JSON {
        return .number(try JSONNumber(exactly: self).unwrap())
    }
}

extension UInt16: JSONConvertible {
    @usableFromInline
    func json() throws -> JSON {
        return .number(try JSONNumber(exactly: self).unwrap())
    }
}

extension UInt32: JSONConvertible {
    @usableFromInline
    func json() throws -> JSON {
        return .number(try JSONNumber(exactly: self).unwrap())
    }
}

extension UInt64: JSONConvertible {
    @usableFromInline
    func json() throws -> JSON {
        return .number(try JSONNumber(exactly: self).unwrap())
    }
}

// MARK: - Helpers

extension JSON {
    @usableFromInline
    init(unknown value: Any) throws {
        self = try (try cast(value) as JSONConvertible).json()
    }
}
