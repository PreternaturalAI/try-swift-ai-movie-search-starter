//
// Copyright (c) Vatsal Manot
//

import Foundation
@_spi(Internal) import Swallow

public final class _PersistenceContext: @unchecked Sendable {
    private let lock = OSUnfairLock()
    
    public let persistenceRepresentation: any PersistenceRepresentation
    
    var persistenceRepresentationResolutionContext = _PersistentRepresentationResolutionContext()
    
    private lazy var resolvedPersistenceRepresentation: _ResolvedPersistentRepresentation = {
        do {
            return try persistenceRepresentation.resolve(context: persistenceRepresentationResolutionContext)
        } catch {
            runtimeIssue(error)
            
            return .init()
        }
    }()
    
    public init(
        persistenceRepresentation: any PersistenceRepresentation
    ) {
        self.persistenceRepresentation = persistenceRepresentation
    }
    
    public convenience init<T>(for type: T.Type) {
        self.init(persistenceRepresentation: PersistenceRepresentationBuilder.Accumulated(components: []))
    }
}

extension _PersistenceContext {
    @propertyWrapper
    public final class Resolved: Codable, HashEquatable {
        public var wrappedValue: _PersistenceContext?
        
        public var projectedValue: Resolved {
            self
        }
        
        public init() {
            self.wrappedValue = nil
        }
        
        public init(wrappedValue: _PersistenceContext?) {
            self.wrappedValue = wrappedValue
        }
        
        public func hash(into hasher: inout Hasher) {
            
        }
        
        public convenience init(from decoder: Decoder) throws {
            try self.init(wrappedValue: decoder._persistenceContext)
        }
        
        public func encode(to encoder: Encoder) throws {
            self.wrappedValue = try encoder._persistenceContext
        }
    }
}

// MARK: - Auxiliary

extension CodingUserInfoKey {
    public static let _persistenceContext = Self(rawValue: "com.vmanot._PersistenceContext")!
}

extension Decoder {
    public var _persistenceContext: _PersistenceContext {
        get throws {
            try cast(userInfo[._persistenceContext], to: _PersistenceContext.self)
        }
    }
}

extension Encoder {
    public var _persistenceContext: _PersistenceContext {
        get throws {
            try cast(userInfo[._persistenceContext], to: _PersistenceContext.self)
        }
    }
}
