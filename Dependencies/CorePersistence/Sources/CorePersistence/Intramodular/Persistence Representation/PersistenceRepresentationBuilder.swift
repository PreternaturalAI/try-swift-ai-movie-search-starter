//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Swallow

@resultBuilder
public struct PersistenceRepresentationBuilder {
    public typealias Component = PersistenceRepresentation
    
    public static func buildBlock() -> Accumulated {
        Accumulated(components: [])
    }
    
    public static func buildBlock<T: Component>(
        _ component: T
    ) -> T {
        component
    }
    
    public static func buildPartialBlock() -> Accumulated {
        Accumulated()
    }
    
    public static func buildPartialBlock<T: Component>(
        first: T
    ) -> Accumulated {
        Accumulated(components: [first])
    }
    
    public static func buildPartialBlock<T: Component>(
        accumulated: Accumulated,
        next: T
    ) -> Accumulated  {
        accumulated.appending(next)
    }
}

extension PersistenceRepresentationBuilder {
    public struct Accumulated: PersistenceRepresentation {
        public let components: [any Component]
        
        public var isEmpty: Bool {
            components.isEmpty
        }
        
        public init(components: [any Component] = []) {
            self.components = components
        }
        
        public func appending(
            contentsOf other: Self
        ) -> Self {
            .init(components: components.appending(contentsOf: other.components))
        }
        
        public func appending(
            _ component: any Component
        ) -> Self {
            .init(components: components.appending(component))
        }
        
        @_spi(Internal)
        public func _resolve(
            into representation: inout _ResolvedPersistentRepresentation,
            context: Context
        ) throws {
            for component in components {
                try component._recursivelyResolve(into: &representation, context: context)
            }
        }
    }
}

@_spi(Internal)
extension PersistenceRepresentationBuilder.Accumulated: _PersistenceRepresentationBuiltin {
    
}

extension PersistenceRepresentation {
    @_spi(Internal)
    public func resolve(
        context: _PersistentRepresentationResolutionContext
    ) throws -> _ResolvedPersistentRepresentation {
        var representation = _ResolvedPersistentRepresentation()
        
        let accumulated = PersistenceRepresentationBuilder.Accumulated(
            components: context.sourceList.compactMap({ source -> (any PersistenceRepresentation)? in
                guard let source = source.wrappedValue else {
                    return nil
                }
                
                return type(of: source).persistenceRepresentation
            })
        )

        if accumulated.isEmpty {
            try accumulated._recursivelyResolve(into: &representation, context: context)
        }
        
        try _recursivelyResolve(into: &representation, context: context)
        
        return representation
    }
     
}
extension PersistenceRepresentation {
    fileprivate func _recursivelyResolve(
        into representation: inout _ResolvedPersistentRepresentation,
        context: _PersistentRepresentationResolutionContext
    ) throws {
        if let `self` = self as? _PersistenceRepresentationBuiltin {
            try self._resolve(into: &representation, context: context)
        } else if let `self` = self as? PersistenceRepresentationBuilder.Accumulated {
            try self._resolve(into: &representation, context: context)
        } else {
            try _tryAssert(Body.self != Never.self)
            
            try self.body._recursivelyResolve(into: &representation, context: context)
        }
    }
}

