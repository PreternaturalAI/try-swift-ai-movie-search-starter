//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
protocol _FileBundle_DynamicProperty {
    typealias InitializationParameters = _KeyedFileBundleChildConfiguration

    func _initialize(with _: InitializationParameters) throws -> Bool
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
protocol _FileBundle_ManifestPropertyType: _FileBundle_DynamicProperty {
    
}
