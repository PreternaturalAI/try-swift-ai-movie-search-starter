//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow
import UniformTypeIdentifiers

public struct _AnyConfiguredFileCoder {
    public enum RawValue {
        case document(_FileDocumentProtocol.Type)
        case topLevelData(_AnyTopLevelDataCoder)
    }
    
    public let rawValue: RawValue
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    public init(
        _ coder: any TopLevelDataCoder,
        for type: any Codable.Type
    ) {
        self.init(rawValue: .topLevelData(.topLevelDataCoder(coder, forType: type)))
    }
    
    public init(
        _ documentType: any _FileDocumentProtocol.Type,
        supportedTypes: [any _FileDocumentProtocol.Type] = []
    ) {
        self.init(rawValue: .document(documentType))
    }
    
    public init(
        _ coder: _AnyTopLevelDataCoder,
        supportedTypes: [Any.Type] = []
    ) {
        self.init(rawValue: .topLevelData(coder))
    }
}

extension _AnyConfiguredFileCoder {
    public init<Coder: TopLevelDataCoder, T>(
        _ coder: Coder,
        forUnsafelySerialized type: T.Type
    ) {
        let coder = _AnyTopLevelDataCoder.custom(
            .init(
                for: type,
                decode: { (data: Data) -> T in
                    try coder.decode(_UnsafelySerialized<T>.self, from: data).wrappedValue
                },
                encode: { (value: T) in
                    try coder.encode(_UnsafelySerialized(wrappedValue: value))
                }
            )
        )
        
        self.init(rawValue: .topLevelData(coder))
    }
    
}


// MARK: - Auxiliary

extension FileManager {
    func _decode(
        from url: URL,
        coder: _AnyConfiguredFileCoder
    ) throws -> Any? {
        switch coder.rawValue {
            case .document(let document):
                return try document.init(configuration: .init(url: url))
            case .topLevelData(let coder):
                guard let data = try fileExists(at: url) ? contents(of: url) : nil else {
                    return nil
                }
                
                return try coder.decode(from: data)
        }
    }
    
    func _encode<T>(
        _ value: T,
        to url: URL,
        coder: _AnyConfiguredFileCoder
    ) throws {
        var url = url
        var endSecurityScopedAccess: (() -> Void)? = nil
        
        if !FileManager.default.fileExists(at: url.deletingLastPathComponent()) {
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        }
        
        if !isReadableAndWritable(at: url) {
            if let securityScopedURL = try? URL._BookmarksCache.cachedURL(for: url) {
                if isReadableAndWritable(at: securityScopedURL) {
                    url = securityScopedURL
                }
            } else if let securityScopedParent = nearestAccessibleSecurityScopedAncestor(for: url) {
                guard securityScopedParent.startAccessingSecurityScopedResource() else {
                    assertionFailure("Failed to acquire permission to write to parent URL: \(securityScopedParent) (parent for \(url)")
                    
                    return
                }
                
                endSecurityScopedAccess = {
                    securityScopedParent.stopAccessingSecurityScopedResource()
                }
            }
        }
        
        switch coder.rawValue {
            case .document(let document):
                try document
                    ._opaque_fileWrapper(
                        for: value,
                        configuration: .init(url: url)
                    )
                    .write(
                        to: url,
                        options: [.atomic, .withNameUpdating],
                        originalContentsURL: nil
                    )
            case .topLevelData(let coder):
                let createDirectoriesIfNecessary = true
                
                try setContents(
                    of: url,
                    to: try coder.encode(value),
                    createDirectoriesIfNecessary: createDirectoriesIfNecessary
                )
        }
        
        endSecurityScopedAccess?()
    }
}

extension URL {
    func _suggestedTopLevelDataCoder(
        contentType: UTType?
    ) -> (any TopLevelDataCoder)? {
        let detectedContentType: UTType
        
        if let contentType {
            detectedContentType = contentType
        } else if let inferredContentType = UTType(from: self) {
            detectedContentType = inferredContentType
        } else {
            return nil
        }
        
        return detectedContentType._suggestedTopLevelDataCoder()
    }
}

extension UTType {
    public func _suggestedTopLevelDataCoder() -> (any TopLevelDataCoder)? {
        switch self {
            case .propertyList:
                return PropertyListCoder()
            case .json:
                return JSONCoder()
            default:
                return nil
        }
    }
}
