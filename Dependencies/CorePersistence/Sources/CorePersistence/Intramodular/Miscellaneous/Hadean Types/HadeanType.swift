//
// Copyright (c) Vatsal Manot
//

import Proquint
import Swallow

public struct HadeanType<T: Sendable>: Sendable {
    private let base: _TypeCastTo2<any Any.Type, T>
    private let typeIdentifier: HadeanIdentifier
    
    public var id: HadeanIdentifier {
        typeIdentifier
    }
    
    public var rawValue: Any.Type {
        base.first
    }
    
    public var value: T {
        base.second
    }
    
    public init(_ type: T) throws {
        self.base = try _TypeCastTo2(base: type)
        
        do {
            self.typeIdentifier = try _UniversalTypeRegistry[base.first].unwrap()
        } catch {
            assertionFailure()
            
            throw error
        }
    }
    
    public init(_ type: T, id: HadeanIdentifier) throws {
        self.base = try _TypeCastTo2(base: type)
        
        _UniversalTypeRegistry.register(base.first, forIdentifier: id)
        
        self.typeIdentifier = id
    }
    
    public func _isConformedTo<A>(by value: A) -> Bool {
        (try? _opaque_openExistentialAndCast(value, to: base.first)) != nil
    }
}

// MARK: - Conformances

extension HadeanType: Codable {
    public init(from decoder: Decoder) throws {
        let typeIdentifier = try HadeanIdentifier(from: decoder)
        let type: Any.Type
        
        do {
            type = try _UniversalTypeRegistry[typeIdentifier].unwrap()
        } catch {
            assertionFailure()
            
            throw error
        }
        
        self.base = try .init(base: type)
        self.typeIdentifier = typeIdentifier
    }
    
    public func encode(to encoder: Encoder) throws {
        try typeIdentifier.encode(to: encoder)
    }
}

extension HadeanType: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension HadeanType: Hashable {
    public func hash(into hasher: inout Hasher) {
        typeIdentifier.hash(into: &hasher)
    }
}
