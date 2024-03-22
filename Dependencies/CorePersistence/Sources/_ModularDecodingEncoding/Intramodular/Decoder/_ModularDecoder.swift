//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

struct _ModularDecoder: Decoder {
    struct Configuration {
        var plugins: [any _ModularCodingPlugin] = []
        
        var allowsUnsafeSerialization: Bool {
            plugins.contains(where: { $0 is _UnsafeSerializationPlugin })
        }
    }
    
    struct Context {
        let type: Any.Type?
    }
    
    let base: Decoder
    let configuration: Configuration
    let context: Context
    
    var codingPath: [CodingKey] {
        base.codingPath
    }
    
    var userInfo: [CodingUserInfoKey: Any] {
        base.userInfo
    }
    
    init(
        base: Decoder,
        configuration: Configuration,
        context: Context
    ) {
        self.base = base
        self.configuration = configuration
        self.context = context
    }
    
    func container<Key: CodingKey>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key> {
        .init(
            KeyedContainer(
                base: try base.container(keyedBy: type),
                parent: self
            )
        )
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        UnkeyedContainer(
            base: try base.unkeyedContainer(),
            parent: self
        )
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        SingleValueContainer(
            try base.singleValueContainer(),
            parent: self
        )
    }
}

// MARK: - Auxiliary

extension Decoder {
    public func _determineContainerKind(
        guess: _DecodingContainerKind? = nil // TODO: Use this at some point
    ) throws -> _DecodingContainerKind {
        try _DecodingContainerKind.allCases.first(byUnwrapping: { kind in
            do {
                _ = try _container(ofKind: kind)
                
                return kind
            } catch {
                return nil
            }
        })
        .unwrap()
    }
}
