//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

/// A type that defines methods for encoding & decoding data.
public protocol TopLevelDataCoder: Sendable {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
    func encode<T: Encodable>(_ value: T) throws -> Data
}

extension TopLevelDataCoder {
    public func decode<T: Decodable>(from data: Data) throws -> T {
        try decode(T.self, from: data)
    }
}

// MARK: - Implemented Conformances

public struct PropertyListCoder: TopLevelDataCoder {
    public let format: PropertyListSerialization.PropertyListFormat
    
    private let decoder: PropertyListDecoder
    private let encoder: PropertyListEncoder
    
    public init(format: PropertyListSerialization.PropertyListFormat = .binary) {
        self.format = format
        
        self.decoder = .init()
        self.encoder = .init()
        
        encoder.outputFormat = format
    }
    
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(type, from: data)
    }
    
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }
}

extension TopLevelDataCoder where Self == PropertyListCoder {
    public static var propertyList: PropertyListCoder {
        PropertyListCoder()
    }
    
    public static func propertyList(
        format: PropertyListSerialization.PropertyListFormat
    ) -> PropertyListCoder {
        PropertyListCoder(format: format)
    }
}

@frozen
public struct JSONCoder: TopLevelDataCoder {
    @usableFromInline
    let decoder: AnyTopLevelDecoder<Data>
    @usableFromInline
    let encoder: AnyTopLevelEncoder<Data>
    
    public init(decoder: JSONDecoder, encoder: JSONEncoder) {
        self.decoder = AnyTopLevelDecoder(erasing: decoder._polymorphic())
        self.encoder = AnyTopLevelEncoder(erasing: encoder)
    }
    
    public init() {
        self.init(decoder: JSONDecoder(), encoder: JSONEncoder())
    }
    
    @_transparent
    public init(outputFormatting: JSONEncoder.OutputFormatting) {
        let encoder = JSONEncoder()
        
        encoder.outputFormatting = outputFormatting
        
        self.init(decoder: JSONDecoder(), encoder: encoder)
    }
    
    @_transparent
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(type, from: data)
    }
    
    @_transparent
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }
}

extension TopLevelDataCoder where Self == JSONCoder {
    public static var json: JSONCoder {
        JSONCoder()
    }
    
    public static func json(
        outputFormatting: JSONEncoder.OutputFormatting
    ) -> JSONCoder {
        JSONCoder(outputFormatting: outputFormatting)
    }
}

// MARK: - Auxiliary

public struct _TopLevelDecoderFromTopLevelDataCoder<Coder: TopLevelDataCoder>: TopLevelDecoder {
    public typealias Input = Data
    
    public let base: Coder
    
    public init(base: Coder) {
        self.base = base
    }
    
    public func decode<T: Decodable>(_ type: T.Type, from input: Input) throws -> T {
        try base.decode(type, from: input)
    }
}
