//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension _ModularEncoder {
    struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        private var base: KeyedEncodingContainer<Key>
        private var parent: _ModularEncoder
        
        init(
            base: KeyedEncodingContainer<Key>,
            parent: _ModularEncoder
        ) {
            self.parent = parent
            self.base = base
        }
        
        var codingPath: [CodingKey] {
            base.codingPath
        }
        
        mutating func encodeNil(forKey key: Key) throws {
            try base.encodeNil(forKey: key)
        }
        
        mutating func encode<T: CoderPrimitive>(
            _ value: T,
            forKey key: Key
        ) throws {
            try base._encode(primitive: value, forKey: key)
        }
        
        mutating func encode<T: Encodable>(
            _ value: T,
            forKey key: Key
        ) throws {
            if let value = value as? (any CoderPrimitive) {
                try base._encode(primitive: value, forKey: key)
            } else {
                let _value = _ModularEncoder.TopLevelProxyEncodable(
                    base: value,
                    encoderConfiguration: parent.configuration
                )
                
                try base.encode(_value, forKey: key)
            }
        }
        
        mutating func nestedContainer<NestedKey: CodingKey>(
            keyedBy keyType: NestedKey.Type,
            forKey key: Key
        ) -> KeyedEncodingContainer<NestedKey> {
            .init(
                KeyedContainer<NestedKey>(
                    base: base.nestedContainer(keyedBy: keyType, forKey: key),
                    parent: parent
                )
            )
        }
        
        mutating func nestedUnkeyedContainer(
            forKey key: Key
        ) -> UnkeyedEncodingContainer {
            UnkeyedContainer(
                base: base.nestedUnkeyedContainer(forKey: key),
                parent: parent
            )
        }
        
        mutating func superEncoder() -> Encoder {
            _ModularEncoder(
                base: base.superEncoder(),
                configuration: parent.configuration,
                context: parent.context // FIXME
            )
        }
        
        mutating func superEncoder(forKey key: Key) -> Encoder {
            _ModularEncoder(
                base: base.superEncoder(forKey: key),
                configuration: parent.configuration,
                context: parent.context // FIXME
            )
        }
    }
}
