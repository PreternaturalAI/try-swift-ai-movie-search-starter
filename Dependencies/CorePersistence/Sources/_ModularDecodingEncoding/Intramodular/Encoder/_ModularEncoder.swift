//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

struct _ModularEncoder: Encoder {
    struct Configuration {
        var plugins: [any _ModularCodingPlugin] = []
    }
    
    struct Context {
        let type: Any.Type?
    }
    
    let base: Encoder
    let configuration: Configuration
    let context: Context
    
    init(base: Encoder, configuration: Configuration, context: Context) {
        self.base = base
        self.configuration = configuration
        self.context = context
    }
    
    var codingPath: [CodingKey] {
        return base.codingPath
    }
    
    var userInfo: [CodingUserInfoKey: Any] {
        return base.userInfo
    }
    
    func container<Key: CodingKey>(
        keyedBy type: Key.Type
    ) -> KeyedEncodingContainer<Key> {
        .init(
            KeyedContainer(
                base: base.container(keyedBy: type),
                parent: self
            )
        )
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        UnkeyedContainer(
            base: base.unkeyedContainer(),
            parent: self
        )
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        SingleValueContainer(
            base: base.singleValueContainer(),
            parent: self
        )
    }
}

extension _ModularEncoder {
    public func disabling(
        _ plugin: any _ModularCodingPlugin
    ) -> Self {
        .init(
            base: base,
            configuration: .init(plugins: configuration.plugins.removingAll(where: { AnyEquatable.equate($0.id, plugin.id)
            })),
            context: context
        )
    }
}
