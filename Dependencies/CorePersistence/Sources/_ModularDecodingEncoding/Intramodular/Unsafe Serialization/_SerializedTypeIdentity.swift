//
// Copyright (c) Vatsal Manot
//

import _CoreIdentity
import Foundation
import Runtime
import Swallow

/// A custom (i.e. specific to this framework) serialization format for representing a type's identity.
/// Don’t use this type directly in your code.
///
/// The framework uses a 'best effort' approach to encode as many available representations of the target type.
///
/// Some of these representations may not be stable across compiler modes/language runtimes.
public struct _SerializedTypeIdentity: Hashable {
    public enum _Error: Error {
        case failedToResolveSwiftTypeByName(String)
    }

    /// The version of this serialization format.
    ///
    /// This is **not** a representation of the version of the type identity being serialized.
    private let version: Version
    
    /// The mangled type name of a Swift type as returned by `_mangledTypeName`.
    public let _swift_mangledTypeName: String?
    /// The mangled type name of a Swift type as returned by `_typeName`.
    public let _swift_typeName: String?
    /// The Objective-C class name of this type as returned by `NSStringFromClass`, if applicable.
    public let _objectiveC_className: String?
    
    /// The persistent type representation of the type (if any).
    public let _CorePersistence_persistentTypeRepresentation: AnyCodable?
    
    @NonCodingProperty private var _resolvedType: Any.Type?
    
    private init(
        version: _SerializedTypeIdentity.Version,
        _swift_mangledTypeName: String?,
        _swift_typeName: String?,
        _objectiveC_className: String?,
        _CorePersistence_persistentTypeRepresentation: AnyCodable?
    ) {
        self.version = version
        self._swift_mangledTypeName = _swift_mangledTypeName
        self._swift_typeName = _swift_typeName
        self._objectiveC_className = _objectiveC_className
        self._CorePersistence_persistentTypeRepresentation = _CorePersistence_persistentTypeRepresentation
        
        if (try? resolveType()) == nil {
            runtimeIssue("Failed deseriaize type named: \(_swift_typeName ?? _swift_mangledTypeName ?? "<error>")")
        }
    }
    
    @_spi(Internal)
    public init(_fromUnwrappedType type: Any.Type) {
        self.version = .v0_0_2
        
        self._resolvedType = type
        
        self._swift_mangledTypeName = _mangledTypeName(type)
        self._swift_typeName = _typeName(type)
        self._objectiveC_className = (type as? AnyObject.Type).map(NSStringFromClass)
        
        if let type = type as? (any PersistentlyRepresentableType.Type) {
            self._CorePersistence_persistentTypeRepresentation = try? AnyCodable(type.persistentTypeRepresentation)
        } else {
            self._CorePersistence_persistentTypeRepresentation = nil
        }
    }
    
    public init(from type: Any.Type) {
        self.init(_fromUnwrappedType: _getUnwrappedType(from: type))
    }
    
    public init<T>(of value: T) {
        self.init(_fromUnwrappedType: _unwrappedType(ofValue: value))
    }
}

extension _SerializedTypeIdentity {
    public func resolveType() throws -> Any.Type {
        do {
            if let _resolvedType = _resolvedType {
                return _resolvedType
            } else {
                let mangledTypeName = try _swift_mangledTypeName.unwrap()
                
                do {
                    return try _typeByName(mangledTypeName).unwrap()
                } catch {
                    throw _Error.failedToResolveSwiftTypeByName(mangledTypeName)
                }
            }
        } catch {
            throw error
        }
    }
}

// MARK: - Conformances

extension _SerializedTypeIdentity: Codable {
    private enum CodingKeys: String, CodingKey {
        case version
        case _swift_mangledTypeName
        case _swift_typeName
        case _objectiveC_className
        case _CorePersistence_persistentTypeRepresentation
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let version = try container.decode(Version.self, forKey: .version)
        
        switch version {
            case .v0_0_1:
                self = try PreviousVersions.v0_0_1(from: decoder).migrate()
            case .v0_0_2:
                self.init(
                    version: version,
                    _swift_mangledTypeName: try container.decodeIfPresent(forKey: ._swift_mangledTypeName),
                    _swift_typeName: try container.decodeIfPresent(forKey: ._swift_typeName),
                    _objectiveC_className: try container.decodeIfPresent(forKey: ._objectiveC_className),
                    _CorePersistence_persistentTypeRepresentation: try container.decodeIfPresent(forKey: ._CorePersistence_persistentTypeRepresentation)
                )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(version, forKey: .version)
        try container.encodeIfPresent(_swift_mangledTypeName, forKey: ._swift_mangledTypeName)
        try container.encodeIfPresent(_swift_typeName, forKey: ._swift_typeName)
        try container.encodeIfPresent(_objectiveC_className, forKey: ._objectiveC_className)
        try container.encodeIfPresent(_CorePersistence_persistentTypeRepresentation, forKey: ._CorePersistence_persistentTypeRepresentation)
    }
}

// MARK: - Auxiliary

extension _SerializedTypeIdentity {
    private enum Version: String, Codable, Hashable {
        case v0_0_1 = "0.0.1"
        case v0_0_2 = "0.0.2"
    }
    
    private enum PreviousVersions {
        struct v0_0_1: Codable, Hashable {
            let version: Version
            let _swift_mangledTypeName: String?
            let objCClassName: String
            let typeRepresentation: AnyCodable?
            
            func migrate() -> _SerializedTypeIdentity {
                .init(
                    version: .v0_0_2,
                    _swift_mangledTypeName: _swift_mangledTypeName,
                    _swift_typeName: nil,
                    _objectiveC_className: objCClassName,
                    _CorePersistence_persistentTypeRepresentation: typeRepresentation
                )
            }
        }
    }
}
