//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension _ModularDecoder {
    struct UnkeyedContainer: UnkeyedDecodingContainer {
        private var parent: _ModularDecoder
        private var base: UnkeyedDecodingContainer
        
        init(
            base: UnkeyedDecodingContainer,
            parent: _ModularDecoder
        ) {
            self.parent = parent
            self.base = base
        }
        
        var codingPath: [CodingKey] {
            base.codingPath
        }
        
        var count: Int? {
            base.count
        }
        
        var isAtEnd: Bool {
            base.isAtEnd
        }
        
        var currentIndex: Int {
            base.currentIndex
        }
        
        mutating func decodeNil() throws -> Bool {
            try base.decodeNil()
        }
        
        mutating func decode<T: CoderPrimitive>(_ type: T.Type) throws -> T {
            try base._decodePrimitive(type)
        }
        
        mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
            if let type = type as? any CoderPrimitive.Type {
                return try cast(base._decodePrimitive(type), to: T.self)
            } else {
                do {
                    return try base.decode(UnkeyedContainerProxyDecodable<T>.self).value
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
        
        mutating func decodeIfPresent<T: Decodable>(_ type: T.Type) throws -> T? {
            try base.decodeIfPresent(UnkeyedContainerProxyDecodable<T>.self)?.value
        }
        
        mutating func nestedContainer<NestedKey: CodingKey>(
            keyedBy type: NestedKey.Type
        ) throws -> KeyedDecodingContainer<NestedKey> {
            .init(
                KeyedContainer(
                    base: try base.nestedContainer(keyedBy: type),
                    parent: parent
                )
            )
        }
        
        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            UnkeyedContainer(
                base: try base.nestedUnkeyedContainer(),
                parent: parent
            )
        }
        
        mutating func superDecoder() throws -> Decoder {
            _ModularDecoder(
                base: try base.superDecoder(),
                configuration: parent.configuration,
                context: .init(type: nil)
            )
        }
    }
}
