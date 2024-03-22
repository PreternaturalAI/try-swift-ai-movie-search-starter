//
// Copyright (c) Vatsal Manot
//

import Runtime
@_spi(Internal) import Swallow

/// A universal registry that maps `HadeanIdentifier`s to Swift metatypes (`Any.Type`).
public struct _UniversalTypeRegistry {
    static let lock = OSUnfairLock()
            
    /// Parsed all available Swift binaries to index `HadeanIdentifiable` types.
    fileprivate static var scrapedAllTypes: Bool = false
    
    @usableFromInline
    static var typesByIdentifier: [HadeanIdentifier: Any.Type] = [:]
    @usableFromInline
    static var identifiersByType: [Metatype<Any.Type>: HadeanIdentifier] = [:]
    
    static let identifierToTypeResolver = IdentifierToSwiftTypeResolver()
    static let typeToIdentifierResolver = SwiftTypeToIdentifierResolver()
    
    @MainActor
    private init() {
        Self.register(
            Self.lock.withCriticalScope {
                RuntimeDiscoverableTypes.enumerate(typesConformingTo: (any HadeanIdentifiable).self)
            }
        )
    }
    
    private static func _indexAllTypesIfNeeded() throws {
        guard !scrapedAllTypes else {
            return
        }
        
        defer {
            scrapedAllTypes = true
        }
                
        let types = try TypeMetadata._queryAll(
            .conformsTo((any HadeanIdentifiable).self),
            .nonAppleFramework
        )
                
        types.forEach(_register)
    }
    
    public static func register(_ type: Any.Type) {
        lock.withCriticalScope {
            _register(type)
        }
    }
    
    public static func register(_ types: [Any.Type]) {
        lock.withCriticalScope {
            for type in types {
                _register(type)
            }
        }
    }
    
    @usableFromInline
    static func _register(_ type: Any.Type) {
        if let type = type as? (any HadeanIdentifiable.Type) {
            let identifier = type.hadeanIdentifier
            
            if let existing = typesByIdentifier[identifier] {
                assert(existing == type)
            } else {
                typesByIdentifier[type.hadeanIdentifier] = type
                identifiersByType[Metatype(type)] = identifier
            }
        }
        
        if let namespaceType = type as? (any _TypeIterableStaticNamespaceType.Type) {
            namespaceType._opaque_allNamespaceTypes.forEach(_register)
        }
    }
    
    public static func register(
        _ type: Any.Type,
        forIdentifier identifier: HadeanIdentifier
    ) {
        lock.withCriticalScope {
            assert(!(type is any HadeanIdentifiable.Type))
            assert(!(type is any _TypeIterableStaticNamespaceType.Type))
            
            typesByIdentifier[identifier] = type
            identifiersByType[Metatype(type)] = identifier
        }
    }
    
    public static subscript(
        _ type: Any.Type
    ) -> HadeanIdentifier? {
        get throws {
            try typeToIdentifierResolver.resolve(from: .init(type))
        }
    }
    
    public static subscript(
        _ type: HadeanIdentifier
    ) -> Any.Type? {
        get throws {
            try identifierToTypeResolver.resolve(from: type)?.value
        }
    }
}

// MARK: - Auxiliary

extension _UniversalTypeRegistry {
    public enum _Error: Error {
        case failedToResolveType(for: HadeanIdentifier)
        case failedToResolveIdentifier(for: Any.Type)
    }
    
    @usableFromInline
    struct IdentifierToSwiftTypeResolver: _PersistentIdentifierToSwiftTypeResolver {
        @usableFromInline
        typealias Input = HadeanIdentifier
        @usableFromInline
        typealias Output = _ExistentialSwiftType<Any, Any.Type>
        
        fileprivate init() {
            
        }
        
        @usableFromInline
        func resolve(
            from input: Input
        ) throws -> Output? {
            do {
                return try _UniversalTypeRegistry.lock.withCriticalScope {
                    let result: Output? = typesByIdentifier[input].map({ .existential($0) })
                    
                    if result == nil {
                        try _UniversalTypeRegistry._indexAllTypesIfNeeded()

                        if let result2: Output = typesByIdentifier[input].map({ .existential($0) }) {
                            return result2
                        }
                    }
                    
                    return try result.unwrap()
                }
            } catch {
                throw _Error.failedToResolveType(for: input)
            }
        }
    }
    
    @frozen
    @usableFromInline
    struct SwiftTypeToIdentifierResolver: _StaticSwiftTypeToPersistentIdentifierResolver {
        @usableFromInline
        typealias Input = _ExistentialSwiftType<Any, Any.Type>
        @usableFromInline
        typealias Output = HadeanIdentifier
        
        fileprivate init() {
            
        }
        
        @usableFromInline
        func resolve(
            from input: Input
        ) throws -> Output? {
            try _UniversalTypeRegistry.lock.withCriticalScope {
                let type = input.value
                
                guard let identifier = identifiersByType[Metatype(type)] else {
                    try _UniversalTypeRegistry._indexAllTypesIfNeeded()
                    
                    if let identifier = identifiersByType[Metatype(type)] {
                        return identifier
                    } else {
                        if (type is any HadeanIdentifiable.Type) {
                            throw _Error.failedToResolveIdentifier(for: input.value)
                        } else {
                            return nil
                        }
                    }
                }
                
                return identifier
            }
        }
    }
}
