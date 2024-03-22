//
// Copyright (c) Vatsal Manot
//

@testable import CorePersistence

import Diagnostics
import FoundationX
import XCTest

final class TypeDiscriminatedCodingTests: XCTestCase {
    func test() throws {
        let coder = _ModularTopLevelCoder(
            coder: JSONCoder(outputFormatting: [.prettyPrinted, .sortedKeys])
        )
        
        let data = Baz(
            child1: Foo(x: 42),
            child2: Bar(x: 4.2)
        )
        
        let encodedData = try coder.encode(data)
        
        print(try String(data: encodedData, using: .init(encoding: .utf8)))
        XCTAssertNoThrow(try JSONDecoder().decode(AnyCodable.self, from: encodedData))
        
        let decoded = try coder.decode(Baz.self, from: encodedData)
        
        assert(data == decoded)
    }
}

private enum TestTypeDiscriminator: String, CaseIterable, Codable, Swallow.TypeDiscriminator {
    public typealias _DiscriminatedSwiftType = _ExistentialSwiftType<any TypeDiscriminatedCodingTestType, any TypeDiscriminatedCodingTestType.Type>
    
    case foo
    case bar
    case baz
    
    func resolveType() throws -> any TypeDiscriminatedCodingTestType.Type {
        switch self {
            case .foo:
                return Foo.self
            case .bar:
                return Bar.self
            case .baz:
                return Baz.self
        }
    }
}

fileprivate protocol TypeDiscriminatedCodingTestType: Codable, Hashable, TypeDiscriminable<TestTypeDiscriminator> {
    associatedtype X: Number
    
    var x: X { get }
}

private struct Foo: TypeDiscriminatedCodingTestType {
    var x: Int
    var y: Int?
    
    var typeDiscriminator: TestTypeDiscriminator {
        .foo
    }
}

private struct Bar: TypeDiscriminatedCodingTestType {
    var x: Float
    var y: Float?
    
    var typeDiscriminator: TestTypeDiscriminator {
        .bar
    }
}

private struct Baz: TypeDiscriminatedCodingTestType {
    var x: Int {
        0
    }
    
    @TypeDiscriminated<TestTypeDiscriminator>
    var child1: any TypeDiscriminatedCodingTestType
    
    @TypeDiscriminated<TestTypeDiscriminator>
    var child2: any TypeDiscriminatedCodingTestType
    
    var typeDiscriminator: TestTypeDiscriminator {
        .baz
    }
}
