//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow
import UniformTypeIdentifiers

public struct _RelativeFileConfiguration<Value> {
    public struct ValidatePath {
        let base: (URL) -> Bool
        
        init(base: @escaping @Sendable (URL) -> Bool) {
            self.base = base
        }
    }
    
    public var path: String?
    public let serialization: _FileOrFolderSerializationConfiguration<Value>
    public var readWriteOptions: FileStorageOptions
    public var pathValidations: [ValidatePath] = []
    
    public func isValid(for url: URL) -> Bool {
        !pathValidations.contains(where: { $0.base(url) == false })
    }
    
    /// Unconditionally consume the relative path.
    public mutating func consumePath() throws -> String {
        defer {
            path = nil
        }
        
        return try path.unwrap()
    }
}

// MARK: - Initializers

extension _RelativeFileConfiguration {
    public init(
        path: String? = nil,
        serialization: _FileOrFolderSerializationConfiguration<Value>,
        readWriteOptions: FileStorageOptions
    ) {
        self.path = path
        self.serialization = serialization
        self.readWriteOptions = readWriteOptions
    }
    
    public init(
        path: String? = nil,
        contentType: UTType? = nil,
        coder fileCoder: _AnyConfiguredFileCoder? = nil,
        readWriteOptions: FileStorageOptions,
        initialValue: Value?
    ) throws {
        let coder: _AnyConfiguredFileCoder
        
        if let fileCoder {
            coder = fileCoder
        } else {
            let topLevelCoder: (any TopLevelDataCoder)?
            
            if let path {
                if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
                    topLevelCoder = URL(filePath: path, relativeTo: nil)
                        ._suggestedTopLevelDataCoder(contentType: contentType)
                } else {
                    topLevelCoder = URL(fileURLWithPath: path)
                        ._suggestedTopLevelDataCoder(contentType: contentType)
                }
            } else {
                topLevelCoder = nil
            }
            
            coder = _AnyConfiguredFileCoder(topLevelCoder ?? JSONCoder(), for: try cast(Value.self, to: (any Codable.Type).self))
        }
        self.path = path
        self.serialization = .init(
            contentType: contentType,
            coder: coder,
            initialValue: initialValue
        )
        self.readWriteOptions = readWriteOptions
    }
    
    public init(
        fileURL: some _FileOrFolderRepresenting,
        contentType: UTType? = nil,
        coder: _AnyConfiguredFileCoder? = nil,
        readWriteOptions: FileStorageOptions,
        initialValue: Value?
    ) throws {
        try self.init(
            path: try fileURL._toURL().lastPathComponent,
            contentType: contentType,
            coder: coder,
            readWriteOptions: readWriteOptions,
            initialValue: initialValue
        )
    }
}

// MARK: - Conformances

extension _RelativeFileConfiguration: _PartiallyEquatable {
    public func isEqual(
        to other: Self
    ) -> Bool? {
        if (path != other.path) || (readWriteOptions != other.readWriteOptions) {
            return false
        } else {
            return nil
        }
    }
}
