//
// Copyright (c) Vatsal Manot
//

import Swallow

@_spi(Internal)
public protocol _ResolvedPersistentRepresentation_Element: Identifiable where ID == Metatype<Any.Type> {
    var id: Metatype<Any.Type> { get }
}

@_spi(Internal)
public struct _ResolvedPersistentRepresentation {
    private var storage = IdentifierIndexingArray<any _ResolvedPersistentRepresentation_Element, Metatype<Any.Type>>(id: \.id)
    
    public struct Element<Item>: _ResolvedPersistentRepresentation_Element {
        public var deduplicateCopy: PersistenceRepresentations.DeduplicateCopy<Item>?
        
        public init() {
            
        }
        
        public var id: Metatype<Any.Type> {
            Metatype(Item.self)
        }
    }

    public subscript<Item>(_ type: Item.Type) -> Element<Item> {
        get {
            try! cast(storage[id: Metatype(type), default: Element<Item>()])
        } set {
            storage[id: Metatype(type)] = newValue
        }
    }
}
