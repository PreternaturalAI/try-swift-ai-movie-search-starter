//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

public final class JSONObjectEncoder: Initiable, TopLevelEncoder {
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    
    public init() {
        
    }
    
    public func encode<T: Encodable>(_ value: T) throws -> Data  {
        var encoder = ObjectEncoder()
        encoder.encodingStrategies = encodingStrategies
        let encoded = try encoder.encode(value, userInfo: userInfo)
        let writingOptions = JSONSerialization.WritingOptions(rawValue: self.outputFormatting.rawValue)
        guard JSONSerialization.isValidJSONObject(encoded) else {
            throw _invalidValue(value)
        }
        do {
            return try JSONSerialization.data(withJSONObject: encoded, options: writingOptions)
        } catch {
            throw _invalidValue(value, with: error)
        }
    }
    
    /// The output format to produce. Defaults to `[]`.
    public typealias OutputFormatting = JSONEncoder.OutputFormatting
    public var outputFormatting: OutputFormatting = []
    
    /// The strategies to use for encoding values.
    public var encodingStrategies: ObjectEncoder.EncodingStrategies = {
        var strategies = ObjectEncoder.EncodingStrategies()
        strategies[Decimal.self] = .compatibleWithJSONEncoder
        strategies[Double.self] = .throwOnNonConformingFloat
        strategies[Float.self] = .throwOnNonConformingFloat
        strategies[URL.self] = .compatibleWithJSONEncoder
        return strategies
    }()
    
    public typealias DataEncodingStrategy = ObjectEncoder.DataEncodingStrategy?
    public var dataEncodingStrategy: DataEncodingStrategy = .deferredToData {
        didSet { encodingStrategies[Data.self] = dataEncodingStrategy }
    }
    
    public typealias DateEncodingStrategy = ObjectEncoder.DateEncodingStrategy?
    public var dateEncodingStrategy: DateEncodingStrategy = .deferredToDate {
        didSet { encodingStrategies[Date.self] = dateEncodingStrategy }
    }
    
    /// The strategy to use for non-JSON-conforming floating-point values (IEEE 754 infinity and NaN).
    public enum NonConformingFloatEncodingStrategy {
        /// Throw upon encountering non-conforming values. This is the default strategy.
        case `throw`
        
        /// Encode the values using the given representation strings.
        case convertToString(positiveInfinity: String, negativeInfinity: String, nan: String)
    }
    
    public var nonConformingFloatEncodingStrategy: NonConformingFloatEncodingStrategy = .throw {
        didSet {
            switch nonConformingFloatEncodingStrategy {
                case .throw:
                    encodingStrategies[Double.self] = .throwOnNonConformingFloat
                    encodingStrategies[Float.self] = .throwOnNonConformingFloat
                case let .convertToString(posInf, negInf, nan):
                    encodingStrategies[Double.self] = .convertNonConformingFloatToString(posInf, negInf, nan)
                    encodingStrategies[Float.self] = .convertNonConformingFloatToString(posInf, negInf, nan)
            }
        }
    }
    
    private func _invalidValue(_ value: Any, with error: Error? = nil) -> EncodingError {
        let debugDescription = "Unable to encode the given top-level value to JSON."
        return .invalidValue(value, .init(codingPath: [], debugDescription: debugDescription, underlyingError: error))
    }
}
