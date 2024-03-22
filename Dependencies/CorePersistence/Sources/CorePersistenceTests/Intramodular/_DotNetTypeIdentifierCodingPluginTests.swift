//
// Copyright (c) Vatsal Manot
//

@testable import CorePersistence

import Diagnostics
import FoundationX
import XCTest

final class ModularCodingTests: XCTestCase {
    func test() throws {
        var coder = _ModularTopLevelCoder(coder: JSONCoder(outputFormatting: [.prettyPrinted, .sortedKeys]))
        
        coder.plugins = [
            _DotNetTypeIdentifierCodingPlugin(
                idResolver: TestTypes.TypeToIdentifierResolver(),
                typeResolver: TestTypes.IdentifierToTypeResolver()
            )
        ]
        
        let data: [Any] = [
            TestTypes.Foo(x: 69, y: nil),
            TestTypes.Bar(x: 6.9, y: 9.6),
            TestTypes.Baz(
                children: [
                    TestTypes.Foo(x: 42),
                    TestTypes.Bar(x: 4.2)
                ]
            )
        ]
        
        let encodedData = try coder.encode(data)
        
        print(try String(data: encodedData, using: .init(encoding: .utf8)))
        XCTAssertNoThrow(try JSONDecoder().decode(AnyCodable.self, from: encodedData))
        
        let decoded = try coder.decode([Any].self, from: encodedData)
        
        let equatableData = try data.map({ AnyEquatable(erasing: try cast($0, to: (any Equatable).self)) })
        let equatableDecodedData = try decoded.map({ AnyEquatable(erasing: try cast($0, to: (any Equatable).self)) })
        
        XCTAssert(equatableData == equatableDecodedData)
    }
}

struct TestTypes {
    enum TypeIdentifier: String, Codable, Hashable, PersistentIdentifier {
        case foo
        case bar
        case baz
        
        public var body: some IdentityRepresentation {
            _StringIdentityRepresentation(rawValue)
        }
    }
    
    struct Foo: TestType {
        var x: Int
        var y: Int?
    }
    
    struct Bar: TestType {
        var x: Float
        var y: Float?
    }
    
    struct Baz: TestType {
        var x: Int {
            0
        }
        
        @_UnsafelySerialized
        var children: [any TestType]
    }
}

protocol TestType: Codable, Hashable {
    associatedtype X: Number
    
    var x: X { get }
}

extension TestTypes {
    struct IdentifierToTypeResolver: _PersistentIdentifierToSwiftTypeResolver {
        typealias Input = TypeIdentifier
        typealias Output = _ExistentialSwiftType<any TestType, any TestType.Type>
        
        fileprivate init() {
            
        }
        
        public func resolve(
            from input: Input
        ) throws -> Output? {
            switch input {
                case .foo:
                    return .existential(Foo.self)
                case .bar:
                    return .existential(Bar.self)
                case .baz:
                    return .existential(Baz.self)
            }
        }
    }
    
    struct TypeToIdentifierResolver: _StaticSwiftTypeToPersistentIdentifierResolver {
        typealias Input = _ExistentialSwiftType<any TestType, any TestType.Type>
        typealias Output = TypeIdentifier
        
        fileprivate init() {
            
        }
        
        public func resolve(
            from input: Input
        ) throws -> Output? {
            switch input.value {
                case Foo.self:
                    return .foo
                case Bar.self:
                    return .bar
                case Baz.self:
                    return .baz
                default:
                    throw _AssertionFailure()
            }
        }
    }
}
