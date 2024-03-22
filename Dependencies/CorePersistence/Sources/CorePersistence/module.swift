//
// Copyright (c) Vatsal Manot
//

@_exported import Diagnostics
@_exported import Foundation
@_exported import FoundationX
@_exported import Swallow
@_exported import SwallowMacrosClient

@_exported import _CoreIdentity
@_exported import _CSV
@_exported import _JSON
@_exported import _ModularDecodingEncoding

@attached(extension, conformances: HadeanIdentifiable, names: named(hadeanIdentifier))
public macro HadeanIdentifier(_ identifier: String) = #externalMacro(
    module: "CorePersistenceMacros",
    type: "HadeanIdentifierMacro"
)

public enum _module {
    private static var isInitialized: Bool = false
    
    public static func initialize() {
        guard !isInitialized else {
            return
        }
        
        defer {
            isInitialized = true
        }
        
        _UniversalTypeRegistry.register(UUID.self)
    }
}
