//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension _ModularEncoder {
    struct SingleValueContainer: SingleValueEncodingContainer {
        private var parent: _ModularEncoder
        private var base: SingleValueEncodingContainer
        
        init(base: SingleValueEncodingContainer, parent: _ModularEncoder) {
            self.parent = parent
            self.base = base
        }
        
        var codingPath: [CodingKey] {
            base.codingPath
        }
        
        mutating func encodeNil() throws {
            try base.encodeNil()
        }
        
        mutating func encode<T: CoderPrimitive>(_ value: T) throws {
            try base._encode(primitive: value)
        }
        
        mutating func encode<T: Encodable>(_ value: T) throws  {
            if let value = value as? (any CoderPrimitive) {
                try self.encode(value)
            } else {
                try base.encode(TopLevelProxyEncodable(base: value, encoderConfiguration: parent.configuration))
            }
        }
    }
}
