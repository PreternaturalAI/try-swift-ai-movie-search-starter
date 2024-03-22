//
// Copyright (c) Vatsal Manot
//

import Combine
import FoundationX
import Runtime
import Swallow

public struct HadeanTopLevelCoder<EncodedRepresentation> {
    private let base: _ModularTopLevelCoder<EncodedRepresentation>
    
    private let plugins: [any _ModularCodingPlugin] = [
        _HadeanTypeCodingPlugin(),
        _DotNetTypeIdentifierCodingPlugin(
            idResolver: _UniversalTypeRegistry.typeToIdentifierResolver,
            typeResolver: _UniversalTypeRegistry.identifierToTypeResolver
        )
    ]
    
    private init(
        base: _ModularTopLevelCoder<EncodedRepresentation>
    ) {
        assert(base.plugins.isEmpty)
        
        var base = base
        
        base.plugins = plugins
        
        self.base = base
    }
}

extension HadeanTopLevelCoder: TopLevelDecoder, TopLevelEncoder {
    public func decode<T>(
        _ type: T.Type = T.self,
        from data: EncodedRepresentation
    ) throws -> T {
        try base.decode(type, from: data)
    }
    
    public func encode<T>(_ value: T) throws -> EncodedRepresentation {
        try base.encode(value)
    }
}

// MARK: - Initializers

extension HadeanTopLevelCoder {
    public init<Decoder: TopLevelDecoder, Encoder: TopLevelEncoder>(
        decoder: Decoder,
        encoder: Encoder
    ) where Decoder.Input == EncodedRepresentation, Encoder.Output == EncodedRepresentation {
        self.init(base: .init(decoder: decoder, encoder: encoder))
    }
    
    public init<Coder: TopLevelDataCoder>(
        coder: Coder
    ) where EncodedRepresentation == Data {
        self.init(base: .init(coder: coder))
    }
}

// MARK: - Conformances

extension HadeanTopLevelCoder: TopLevelDataCoder where EncodedRepresentation == Data {
    
}


// MARK: - Auxiliary

public final class _HadeanTypeCodingPlugin: _MetatypeCodingPlugin {
    public typealias CodableRepresentation = HadeanIdentifier
    
    public init() {

    }
    
    public func codableRepresentation(
        for type: Any.Type,
        context: Context
    ) throws -> CodableRepresentation {
        try _UniversalTypeRegistry[type].unwrap()
    }
    
    public func type(
        from codableRepresentation: CodableRepresentation,
        context: Context
    ) throws -> Any.Type {
        try _UniversalTypeRegistry[codableRepresentation].unwrap()
    }
}
