//
// Copyright (c) Vatsal Manot
//

import Swallow

@resultBuilder
public struct IdentityRepresentationBuilder {
    public static func buildBlock<R: IdentityRepresentation>(
        _ representation: R
    ) -> R {
        representation
    }
    
    public static func buildBlock(
        _ string: String
    ) -> _StringIdentityRepresentation {
        .init(string)
    }
    
    public static func buildPartialBlock<R: IdentityRepresentation>(
        first representation: R
    ) -> Accumulated {
        .init(base: [representation])
    }
    
    public static func buildPartialBlock(
        first string: String
    ) -> Accumulated {
        .init(base: [_StringIdentityRepresentation(string)])
    }
    
    public static func buildPartialBlock<R: IdentityRepresentation>(
        accumulated: Accumulated,
        next: R
    ) -> Accumulated  {
        .init(base: accumulated.base + [next])
    }
}

extension IdentityRepresentationBuilder {
    /// This type is a work-in-progress. Do not use this type directly in your code.
    public struct Accumulated: IdentityRepresentation {
        var base: [any IdentityRepresentation]
        
        public var body: some IdentityRepresentation {
            self
        }
    }
}

public struct AnyIdentityRepresentation {
    private var base: IdentityRepresentationBuilder.Accumulated
    
    public init(_from representation: any IdentityRepresentation) {
        var base = IdentityRepresentationBuilder.Accumulated(base: [])
        
        Self.reduce(representation, into: &base)
        
        self.base = base
    }
    
    private static func reduce(
        _ representation: any IdentityRepresentation,
        into representations: inout IdentityRepresentationBuilder.Accumulated
    ) {
        if type(of: representation.body) is Never.Type {
            representations.base.append(representation)
        } else if let accumulated = representation.body as? IdentityRepresentationBuilder.Accumulated {
            for representation in accumulated.base {
                reduce(representation, into: &representations)
            }
        } else {
            assertionFailure()
        }
    }
}
