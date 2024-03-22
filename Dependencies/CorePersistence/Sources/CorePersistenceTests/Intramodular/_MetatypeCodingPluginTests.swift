//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import XCTest

/// lamuf-dosih-fipus-fatut
/// lolam-lomup-hinop-muvot
/// japug-kudof-pasol-sohoj
/// namoj-hofiv-jusif-torim
/// vapid-tamov-jovug-nahiz
/// giloj-mogud-gozir-tatom
/// fobat-nisuk-vivol-komav
/// viluh-tobom-sijis-sovul
final class _MetatypeCodingPluginTests: XCTestCase {
    func test() throws {
        var coder = _ModularTopLevelCoder(coder: .json)
        
        coder.plugins = [_HadeanTypeCodingPlugin()]
        
        let testData = SomeMetatypeContainer(type: SomeType.self)
        let encodedTestData = try coder.encode(testData)
        let decodedTestData = try coder.decode(SomeMetatypeContainer.self, from: encodedTestData)
    }
}

extension _MetatypeCodingPluginTests {
    @RuntimeDiscoverable
    @HadeanIdentifier("libup-tatuz-huraf-supos")
    struct SomeType {
        
    }
    
    struct SomeMetatypeContainer: Codable {
        @_UnsafelySerialized
        var type: Any.Type
    }
}
