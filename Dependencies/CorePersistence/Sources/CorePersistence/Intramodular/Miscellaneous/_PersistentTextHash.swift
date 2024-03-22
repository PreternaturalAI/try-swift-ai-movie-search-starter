//
// Copyright (c) Vatsal Manot
//

import CryptoKit
import Foundation

public struct _PersistentTextHash: Codable, Hashable, PersistentIdentifier, Sendable {
    public let rawValue: String
    
    fileprivate init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public var body: some IdentityRepresentation {
        _StringIdentityRepresentation(rawValue)
    }
}

extension _PersistentTextHash {
    public static func compute(for text: String) -> Self {
        .init(rawValue: text._persistentHash(using: SHA256.self))
    }
}

extension String {
    func _persistentHash<H: HashFunction>(
        using function: H.Type
    ) -> String {
        function.hash(data: self.data(using: .utf8)!).hexadecimalString
    }
}
