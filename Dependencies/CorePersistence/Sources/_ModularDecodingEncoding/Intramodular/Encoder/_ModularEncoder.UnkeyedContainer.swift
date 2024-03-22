//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension _ModularEncoder {
    struct UnkeyedContainer: UnkeyedEncodingContainer {
        private var parent: _ModularEncoder
        private var base: any UnkeyedEncodingContainer
        
        init(base: any UnkeyedEncodingContainer, parent: _ModularEncoder) {
            self.parent = parent
            self.base = base
        }
        
        var codingPath: [CodingKey] {
            base.codingPath
        }
        
        var count: Int {
            base.count
        }
        
        mutating func encodeNil() throws {
            try base.encodeNil()
        }
        
        mutating func encode<T: CoderPrimitive>(_ value: T) throws {
            try base._encode(primitive: value)
        }
                
        mutating func encode<T: Encodable>(_ value: T) throws  {
            if let value = value as? any CoderPrimitive {
                try value._encode(to: &base)
            } else {
                try base.encode(TopLevelProxyEncodable(base: value, encoderConfiguration: parent.configuration))
            }
        }
        
        mutating func nestedContainer<NestedKey: CodingKey>(
            keyedBy keyType: NestedKey.Type
        ) -> KeyedEncodingContainer<NestedKey>  {
            .init(
                KeyedContainer(
                    base: base.nestedContainer(keyedBy: keyType),
                    parent: parent
                )
            )
        }
        
        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            UnkeyedContainer(base: base.nestedUnkeyedContainer(), parent: parent)
        }
        
        mutating func superEncoder() -> Encoder {
            _ModularEncoder(
                base: base.superEncoder(),
                configuration: parent.configuration,
                context: parent.context // FIXME
            )
        }
    }
}
