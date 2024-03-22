//
// Copyright (c) Vatsal Manot
//

import Swallow
import SwiftUI
import UniformTypeIdentifiers

@propertyWrapper
public struct WebLocationDocument: Hashable, Sendable {
    public var url: URL
    
    public init(url: URL) {
        self.url = url
    }
        
    public init(url: String) throws {
        try self.init(url: URL(string: url).unwrap())
    }
    
    public var wrappedValue: URL {
        get {
            url
        } set {
            self = Self(url: url)
        }
    }

    public init(wrappedValue: URL) throws {
        self.init(url: wrappedValue)
    }
}

// MARK: - Conformances

extension WebLocationDocument: Codable {
    public enum CodingKeys: String, CodingKey {
        case url = "URL"
    }
    
    public init(from decoder: Decoder) throws {
        let url: Result<URL, Error> = try Result.from {
            try URL(from: decoder)
        } or: {
            try URL(string: try String(from: decoder)).unwrap()
        } or: {
            try URL(string: try _WebLocationFilePayload1(from: decoder).url).unwrap()
        } or: {
            try _WebLocationFilePayload2(from: decoder).url
        } or: {
            try _RelativeURL(from: decoder).url
        }
        
        self.url = try url.get()
    }
    
    public func encode(to encoder: Encoder) throws {
        try url.encode(to: encoder)
    }
}

extension WebLocationDocument: _FileDocument {
    public static var readableContentTypes = [UTType.internetLocation]
    
    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        do {
            self = try PropertyListDecoder().decode(Self.self, from: data)
        } catch {
            let payload = try PropertyListDecoder().decode(_WebLocationFilePayload1.self, from: data)
            
            self.init(url: try URL(string: payload.url).unwrap())
        }
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try PropertyListEncoder().encode(_WebLocationFilePayload1(url: url.absoluteString))
        
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Auxiliary

extension WebLocationDocument {
    struct _WebLocationFilePayload1: Codable, Hashable, Sendable {
        enum CodingKeys: String, CodingKey {
            case url = "URL"
        }
        
        let url: String
    }
    
    struct _WebLocationFilePayload2: Codable, Hashable, Sendable {
        enum CodingKeys: String, CodingKey {
            case url = "URL"
        }
        
        let url: URL
    }
    
    struct _RelativeURL: Codable, Hashable, Sendable {
        enum CodingKeys: String, CodingKey {
            case _url = "URL"
        }
        
        private let _url: [String: String]
        
        public var url: URL {
            get throws {
                guard try _url.keys.toCollectionOfOne().value == "relative" else {
                    throw Never.Reason.unexpected
                }
                
                return try URL(string: _url["relative"]!).unwrap()
            }
        }
    }
}
