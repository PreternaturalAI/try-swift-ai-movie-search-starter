//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension _ModularDecoder {
    struct SingleValueContainer: SingleValueDecodingContainer {
        private var parent: Decoder
        private var base: SingleValueDecodingContainer
        
        init(_ base: SingleValueDecodingContainer, parent: Decoder) {
            self.parent = parent
            self.base = base
        }
        
        var codingPath: [CodingKey] {
            base.codingPath
        }
        
        func decodeNil() -> Bool {
            base.decodeNil()
        }
        
        mutating func decode<T: CoderPrimitive>(_ type: T.Type) throws -> T {
            try base._decodePrimitive(type)
        }
        
        func decode<T: Decodable>(_ type: T.Type) throws -> T {
            if let type = type as? any CoderPrimitive.Type {
                return try cast(base._decodePrimitive(type), to: T.self)
            } else {
                do {
                    return try base.decode(SingleValueContainerProxyDecodable<T>.self).value
                } catch let error as _ModularDecodingError {
                    switch error {
                        case .typeMismatch:
                            throw error
                        default:
                            throw error
                    }
                } catch let error as DecodingError {
                    switch error {
                        case .typeMismatch:
                            throw error
                        default:
                            throw error
                    }
                }
            }
        }
    }
}
