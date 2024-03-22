//
// Copyright (c) Vatsal Manot
//

import Combine
import Compression
import Foundation
import Swallow

public struct CompressingTopLevelEncoder<Base: TopLevelEncoder>: TopLevelEncoder where Base.Output == Data {
    public typealias Output = Base.Output
    
    public let base: Base
    
    public init(base: Base) {
        self.base = base
    }
    
    public func encode<T: Encodable>(
        _ value: T
    ) throws -> Data {
        try (base.encode(value) as NSData).compressed(using: .zlib) as Data
    }
}
