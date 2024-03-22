//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension _ModularDecoder {
    struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        private var base: KeyedDecodingContainer<Key>
        private var parent: _ModularDecoder
        
        init(
            base: KeyedDecodingContainer<Key>,
            parent: _ModularDecoder
        ) {
            self.parent = parent
            self.base = base
        }
        
        var codingPath: [CodingKey] {
            base.codingPath
        }
        
        var allKeys: [Key] {
            base.allKeys
        }
        
        func contains(_ key: Key) -> Bool {
            base.contains(key)
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            try base.decodeNil(forKey: key)
        }
        
        func decode<T: CoderPrimitive>(_ type: T.Type, forKey key: Key) throws -> T {
            try base._decodePrimitive(type, forKey: key)
        }
        
        func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
            guard !(type is Date.Type) else {
                return try base.decode(T.self, forKey: key)
            }
            
            guard !(type is Optional<Date>.Type) else {
                return try base.decode(T.self, forKey: key)
            }
            
            guard !(type is URL.Type) else {
                return try base.decode(T.self, forKey: key)
            }
            
            guard !(type is Optional<URL>.Type) else {
                return try base.decode(T.self, forKey: key)
            }
            
            do {
                return try base.decode(KeyedContainerProxyDecodable<T>.self, forKey: key).value
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
                        fallthrough
                    case .keyNotFound:
                        if let nilLiteral = try? _initializeNilLiteral(ofType: T.self) {
                            return nilLiteral
                        } else if let arrayLiteral = try? _initializeEmptyArrayLiteral(ofType: T.self) {
                            return arrayLiteral
                        }
                        
                        fallthrough
                    default:
                        break
                }
                
                throw error
            }
        }
        
        func decodeIfPresent<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T? {
            guard !(type is Date.Type) else {
                return try base.decodeIfPresent(T.self, forKey: key)
            }
            
            guard !(type is Optional<Date>.Type) else {
                return try base.decodeIfPresent(T.self, forKey: key)
            }
            
            guard !(type is URL.Type) else {
                return try base.decodeIfPresent(T.self, forKey: key)
            }
            
            guard !(type is Optional<URL>.Type) else {
                return try base.decodeIfPresent(T.self, forKey: key)
            }
            
            return try base.decodeIfPresent(KeyedContainerProxyDecodable<T>.self, forKey: key)?.value
        }
        
        func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey>  {
            .init(
                KeyedContainer<NestedKey>(
                    base: try base.nestedContainer(keyedBy: type, forKey: key),
                    parent: parent
                )
            )
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            UnkeyedContainer(
                base: try base.nestedUnkeyedContainer(forKey: key),
                parent: parent
            )
        }
        
        func superDecoder() throws -> Decoder {
            _ModularDecoder(
                base: try base.superDecoder(),
                configuration: parent.configuration,
                context: .init(type: nil)
            )
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            _ModularDecoder(
                base: try base.superDecoder(forKey: key),
                configuration: parent.configuration,
                context: .init(type: nil)
            )
        }
    }
}
