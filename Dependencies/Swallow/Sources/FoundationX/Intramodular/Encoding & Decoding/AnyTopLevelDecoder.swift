//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

public struct AnyTopLevelDecoder<Input>: TopLevelDecoder, Sendable {
    private let _decode: @Sendable (Decodable.Type, Input) throws -> Decodable
    
    public init<Decoder: TopLevelDecoder>(
        erasing decoder: Decoder
    ) where Decoder.Input == Input {
        if let decoder = decoder as? AnyTopLevelDecoder {
            self = decoder
        } else {
            self._decode = { try decoder.decode($0, from: $1) }
        }
    }
    
    public init<Coder: TopLevelDataCoder>(
        erasing coder: Coder
    ) where Input == Data {
        self._decode = { try coder.decode($0, from: $1) }
    }
    
    public func decode<T: Decodable>(
        _ type: T.Type,
        from input: Input
    ) throws -> T {
        try cast(_decode(type, input))
    }
}
