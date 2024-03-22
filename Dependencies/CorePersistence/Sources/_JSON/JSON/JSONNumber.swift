//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension JSONNumber {
    private enum Storage: Codable, Hashable {
        case int(Int)
        case double(Double)
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            
            if let value = try? container.decode(Int.self) {
                self = .int(value)
            } else if let value = try? container.decode(Double.self) {
                self = .double(value)
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Could not decode a JSON number from the given container.")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            
            switch self {
                case .int(let value):
                    try container.encode(value)
                case .double(let value):
                    try container.encode(value)
            }
        }
    }
}

public struct JSONNumber: Codable, Sendable {
    private var storage: Storage
    
    private init(storage: Storage) {
        self.storage = storage
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.storage = try container.decode(Storage.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(storage)
    }
    
    public var rawValue: Any {
        return integerValue ?? approximateDoubleValue
    }
    
    public var integerValue: Int? {
        get {
            if case let .int(result) = storage {
                return result
            } else {
                return approximateDoubleValue.isInteger ? .init(approximateDoubleValue) : nil
            }
        }
        
        set {
            self = newValue.map({ JSONNumber($0) }) ?? JSONNumber(Double.signalingNaN)
        }
    }
    
    public var approximateDoubleValue: Double {
        get {
            if case let .double(result) = storage {
                return result
            } else {
                return integerValue.map(Double.init) ?? Double.signalingNaN
            }
        }
        
        set {
            self = .init(newValue)
        }
    }
    
    public init(_ value: Int) {
        self.storage = .int(value)
    }
    
    public init(_ value: Double) {
        self.storage = .double(value)
    }
}

// MARK: - Initializers

extension JSONNumber {
    public init(_ value: Int8) {
        self.init(Int(value))
    }
    
    public init(_ value: Int16) {
        self.init(Int(value))
    }
    
    public init(_ value: Int32) {
        self.init(Int(value))
    }
    
    public init(_ value: Int64) {
        self.init(Int(value))
    }
    
    public init(_ value: Float) {
        self.init(Double(value))
    }
    
    public init(_ number: NSNumber) {
        let numberType = CFNumberGetType(number)
        
        switch numberType {
            case .charType:
                self.init(number.boolValue ? 1 : 0)
            case .sInt8Type, .sInt16Type, .sInt32Type, .sInt64Type, .shortType, .intType, .longType, .longLongType, .cfIndexType, .nsIntegerType:
                self.init(number.intValue)
            case .float32Type, .float64Type, .floatType, .doubleType, .cgFloatType:
                self.init(number.doubleValue)
            default:
                fatalError(.unimplemented)
        }
    }
}

extension JSONNumber {
    private func map<T>(with other: JSONNumber, using f: ((Int, Int) -> T), _ g: ((Double, Double) -> T)) -> T {
        if let lhs = integerValue, let rhs = other.integerValue {
            return f(lhs, rhs)
        } else {
            return g(approximateDoubleValue, other.approximateDoubleValue)
        }
    }
    
    private func map(with other: JSONNumber, using f: ((Int, Int) -> Int), _ g: ((Double, Double) -> Double)) -> JSONNumber {
        if let lhs = integerValue, let rhs = other.integerValue {
            return .init(f(lhs, rhs))
        } else {
            return .init(g(approximateDoubleValue, other.approximateDoubleValue))
        }
    }
    
    private mutating func mutate<T>(with other: JSONNumber, using f: ((inout Int, Int) -> T), _ g: ((inout Double, Double) -> T)) -> T {
        if let _ = integerValue, let rhs = other.integerValue {
            return f(&integerValue!, rhs)
        } else {
            return g(&approximateDoubleValue, other.approximateDoubleValue)
        }
    }
}

// MARK: - Conformances

extension JSONNumber: Comparable {
    public static func < (lhs: JSONNumber, rhs: JSONNumber) -> Bool {
        return lhs.map(with: rhs, using: <, <)
    }
    
    public static func <= (lhs: JSONNumber, rhs: JSONNumber) -> Bool {
        return lhs.map(with: rhs, using: <=, <=)
    }
    
    public static func > (lhs: JSONNumber, rhs: JSONNumber) -> Bool {
        return lhs.map(with: rhs, using: >, >)
    }
    
    public static func >= (lhs: JSONNumber, rhs: JSONNumber) -> Bool {
        return lhs.map(with: rhs, using: >=, >=)
    }
}

extension JSONNumber: CustomStringConvertible {
    public var description: String {
        return String(describing: rawValue)
    }
}

extension JSONNumber: Equatable {
    public static func == (lhs: JSONNumber, rhs: JSONNumber) -> Bool {
        return lhs.map(with: rhs, using: ==, ==)
    }
}

extension JSONNumber: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.init(value)
    }
}

extension JSONNumber: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension JSONNumber: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage)
    }
}

extension JSONNumber: LosslessStringConvertible {
    public init?(_ description: String) {
        let storage = nil
            ?? Int(description).map(JSONNumber.Storage.int)
            ?? Double(description).map(JSONNumber.Storage.double)
        
        guard let _storage = storage else {
            return nil
        }
        
        self.init(storage: _storage)
    }
}

extension JSONNumber: Numeric {
    public var magnitude: Double {
        return approximateDoubleValue.magnitude
    }
    
    public init?<T: BinaryInteger>(exactly source: T) {
        if let value = Int(exactly: source) {
            self.init(value)
        } else if let value = Double(exactly: source) {
            self.init(value)
        } else {
            return nil
        }
    }
    
    public static func + (lhs: JSONNumber, rhs: JSONNumber) -> JSONNumber {
        return lhs.map(with: rhs, using: +, +)
    }
    
    public static func += (lhs: inout JSONNumber, rhs: JSONNumber) {
        return lhs.mutate(with: rhs, using: +=, +=)
    }
    
    public static func - (lhs: JSONNumber, rhs: JSONNumber) -> JSONNumber {
        return lhs.map(with: rhs, using: -, -)
    }
    
    public static func -= (lhs: inout JSONNumber, rhs: JSONNumber) {
        return lhs.mutate(with: rhs, using: -=, -=)
    }
    
    public static func * (lhs: JSONNumber, rhs: JSONNumber) -> JSONNumber {
        return lhs.map(with: rhs, using: *, *)
    }
    
    public static func *= (lhs: inout JSONNumber, rhs: JSONNumber) {
        return lhs.mutate(with: rhs, using: *=, *=)
    }
}
