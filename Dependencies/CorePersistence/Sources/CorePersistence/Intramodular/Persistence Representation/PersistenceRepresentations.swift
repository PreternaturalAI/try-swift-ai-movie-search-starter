//
// Copyright (c) Vatsal Manot
//

import CoreTransferable
import Swallow

public enum PersistenceRepresentations {
    
}

extension PersistenceRepresentations {
    public struct DeduplicateCopy<Item>: PersistenceRepresentation {
        public let deduplicate: (Item, Item) throws -> Item
        
        public init(deduplicate: @escaping (Item, Item) throws -> Item) {
            self.deduplicate = deduplicate
        }
    }
    
    public struct ImportFileURL<Parent>: PersistenceRepresentation {
        public let keyPath: AnyKeyPath
        public let url: (URL) throws -> URL
        
        public init<T>(
            _ keyPath: KeyPath<T, ImportedFileURL>,
            _ url: @escaping (URL) throws -> URL
        ) {
            self.keyPath = keyPath
            self.url = url
        }
    }
}

@_spi(Internal)
extension PersistenceRepresentations.DeduplicateCopy: _PersistenceRepresentationBuiltin {
    @_spi(Internal)
    public func _resolve(
        into representation: inout _ResolvedPersistentRepresentation,
        context: Context
    ) throws {
        representation[Item.self].deduplicateCopy = self
    }
}

@_spi(Internal)
extension PersistenceRepresentations.ImportFileURL: _PersistenceRepresentationBuiltin {
    @_spi(Internal)
    public func _resolve(
        into representation: inout _ResolvedPersistentRepresentation,
        context: Context
    ) throws {
        
    }
}

extension PersistenceRepresentable {
    public typealias DeduplicateCopy = PersistenceRepresentations.DeduplicateCopy<Self>
    public typealias ImportFileURL = PersistenceRepresentations.ImportFileURL<Self>
}

@propertyWrapper
public struct ImportedFileURL: Codable, Hashable {
    @_PersistenceContext.Resolved var persistenceContext: _PersistenceContext?
    
    public var url: URL?
    public var assignedURL: URL?
    
    public var wrappedValue: URL? {
        @storageRestrictions(initializes: assignedURL, url)
        init(initialValue)  {
            self.assignedURL = initialValue
            self.url = nil
        }
        
        get {
            url
        } set {
            assignedURL = newValue
        }
    }
    
    public var projectedValue: Self {
        self
    }
    
    public init(wrappedValue: URL?) {
        self.assignedURL = wrappedValue
    }
    
    public mutating func `import`(_ url: URL) throws {
        self.assignedURL = url
    }
    
    public init(from decoder: Decoder) throws {
        _persistenceContext = try .init(from: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        try $persistenceContext.encode(to: encoder)
    }
}
