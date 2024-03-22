//
// Copyright (c) Vatsal Manot
//

import Runtime
import Swallow

public struct _UniversallyRegisteredType<Existential>: Hashable, Sendable {
    private let base: Metatype<Existential>
    
    public var value: Existential {
        base.value
    }
    
    public init(base: Metatype<Existential>) {
        assert(!base._isAnyOrNever(unwrapIfNeeded: true))
        
        self.base = base
    }
}
