//
// Copyright (c) Vatsal Manot
//

import Combine
import FoundationX
import Swallow

/// A wrapper coder that allows for polymorphic decoding.
public struct _ModularTopLevelCoder<EncodedRepresentation>: TopLevelDecoder, TopLevelEncoder, Sendable {
    private var decoder: _ModularTopLevelDecoder<EncodedRepresentation>
    private var encoder: _ModularTopLevelEncoder<EncodedRepresentation>
    
    public var plugins: [any _ModularCodingPlugin] {
        get {
            encoder.plugins
        } set {
            decoder.plugins = newValue
            encoder.plugins = newValue
        }
    }
    
    public init<Decoder: TopLevelDecoder, Encoder: TopLevelEncoder>(
        decoder: Decoder,
        encoder: Encoder
    ) where Decoder.Input == EncodedRepresentation, Encoder.Output == EncodedRepresentation {
        self.decoder = _ModularTopLevelDecoder(from: decoder)
        self.encoder = _ModularTopLevelEncoder(from: encoder)
    }
    
    public init<Coder: TopLevelDataCoder>(
        coder: Coder
    ) where EncodedRepresentation == Data {
        self.decoder = _ModularTopLevelDecoder(from: AnyTopLevelDecoder(erasing: coder))
        self.encoder = _ModularTopLevelEncoder(from: AnyTopLevelEncoder(erasing: coder))
    }
    
    public func decode<T>(
        _ type: T.Type,
        from input: EncodedRepresentation
    ) throws -> T {
        try decoder.decode(type, from: input)
    }
    
    public func encode<T>(_ value: T) throws -> EncodedRepresentation {
        try encoder.encode(value)
    }
}

// MARK: - Conformances

extension _ModularTopLevelCoder: TopLevelDataCoder where EncodedRepresentation == Data {
    
}

// MARK: - Supplementary

extension TopLevelDataCoder {
    public func _modular() -> _ModularTopLevelCoder<Data> {
        _ModularTopLevelCoder(coder: self)
    }
}
