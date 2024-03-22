//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

public final class JSONObjectDecoder: Initiable, TopLevelDecoder {
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    
    public init() {
        
    }
    
    public func decode<T: Decodable>(_ type: T.Type = T.self, from data: Data) throws -> T {
        do {
            let topLevel = try JSONSerialization.jsonObject(with: data)
            var decoder = ObjectDecoder()
            decoder.decodingStrategies = decodingStrategies
            
            return try decoder.decode(type, from: topLevel, userInfo: userInfo)
        } catch {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "The given data was not valid JSON.", underlyingError: error))
        }
    }
    
    public var decodingStrategies: ObjectDecoder.DecodingStrategies = {
        var strategies = ObjectDecoder.DecodingStrategies()
        
        strategies[Decimal.self] = .compatibleWithJSONDecoder
        strategies[Double.self] = .deferredToDouble
        strategies[Float.self] = .deferredToFloat
        strategies[URL.self] = .compatibleWithJSONDecoder
        
        return strategies
    }()
    
    public typealias DataDecodingStrategy = ObjectDecoder.DataDecodingStrategy?
    
    public var dataDecodingStrategy: DataDecodingStrategy = .deferredToData {
        didSet {
            decodingStrategies[Data.self] = dataDecodingStrategy
        }
    }
    
    public typealias DateDecodingStrategy = ObjectDecoder.DateDecodingStrategy?
    
    public var dateDecodingStrategy: DateDecodingStrategy = .deferredToDate {
        didSet {
            decodingStrategies[Date.self] = dateDecodingStrategy
        }
    }
    
    /// The strategy to use for non-JSON-conforming floating-point values (IEEE 754 infinity and NaN).
    public enum NonConformingFloatDecodingStrategy {
        /// Throw upon encountering non-conforming values. This is the default strategy.
        case `throw`
        
        /// Decode the values from the given representation strings.
        case convertFromString(positiveInfinity: String, negativeInfinity: String, nan: String)
    }
    
    public var nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy = .throw {
        didSet {
            switch nonConformingFloatDecodingStrategy {
                case .throw:
                    decodingStrategies[Double.self] = .deferredToDouble
                    decodingStrategies[Float.self] = .deferredToFloat
                case let .convertFromString(posInf, negInf, nan):
                    decodingStrategies[Double.self] = .convertNonConformingFloatFromString(posInf, negInf, nan)
                    decodingStrategies[Float.self] = .convertNonConformingFloatFromString(posInf, negInf, nan)
            }
        }
    }
}
