//
// Copyright (c) Vatsal Manot
//

import CoreTransferable
import Diagnostics
import Swallow
import UniformTypeIdentifiers

/// A type-erased primitive `TransferRepresentation`.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public enum _AnyPrimitiveTransferRepresentation: CustomDebugStringConvertible {
    case codable(any _opaque_CodableTransferRepresentation)
    case proxyRepresentation(any _opaque_ProxyTransferRepresentation)
    case unknown(Any)
    
    public var rawValue: any _opaque_PrimitiveTransferRepresentation {
        get throws {
            switch self {
                case .codable(let x):
                    return x
                case .proxyRepresentation(let x):
                    return x
                case .unknown:
                    throw Never.Reason.unsupported
            }
        }
    }
    
    public var debugDescription: String {
        switch self {
            case .codable(let x):
                return String(describing: x)
            case .proxyRepresentation(let x):
                return String(describing: x)
            case .unknown(let x):
                return String(describing: x)
        }
    }
    
    init(from x: Any) throws {
        switch x {
            case let x as any _opaque_CodableTransferRepresentation:
                self = .codable(x)
            case let x as any _opaque_ProxyTransferRepresentation:
                self = .proxyRepresentation(x)
            default:
                self = .unknown(x)
        }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension Array where Element == _AnyPrimitiveTransferRepresentation {
    @_spi(Internal)
    public static func from<R: TransferRepresentation>(
        _ representation: R
    ) throws -> Self {
        if let representation = representation as? (any _opaque_PrimitiveTransferRepresentation) {
            return try representation._opaque_destructureTransferRepresentation()
        } else if let representation = representation.body as? (any _opaque_PrimitiveTransferRepresentation) {
            return try representation._opaque_destructureTransferRepresentation()
        } else {
            throw Never.Reason.unexpected
        }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public protocol _opaque_PrimitiveTransferRepresentation<Item>: TransferRepresentation {
    var _opaque_contentType: UTType? { get }
    
    func _opaque_destructureTransferRepresentation() throws -> [_AnyPrimitiveTransferRepresentation]
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public protocol _opaque_CodableTransferRepresentation: _opaque_PrimitiveTransferRepresentation {
    
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public protocol _opaque_ProxyTransferRepresentation: _opaque_PrimitiveTransferRepresentation {
    
}

// MARK: - Implemented Conformances

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension CodableRepresentation: _opaque_CodableTransferRepresentation {
    public var _opaque_contentType: UTType? {
        _expectNoThrow {
            try Mirror(reflecting: self).descendant("contentType").map({ try cast($0, to: UTType.self) })
        }
    }
    
    public func _opaque_destructureTransferRepresentation() throws -> [_AnyPrimitiveTransferRepresentation] {
        [.codable(self)]
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension ProxyRepresentation: _opaque_ProxyTransferRepresentation {
    public var _opaque_contentType: UTType? {
        nil
    }
    
    public func _opaque_destructureTransferRepresentation() throws -> [_AnyPrimitiveTransferRepresentation] {
        [.proxyRepresentation(self)]
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension TupleTransferRepresentation: _opaque_PrimitiveTransferRepresentation {
    public var _opaque_contentType: UTType? {
        nil
    }
    
    public func _opaque_destructureTransferRepresentation() throws -> [_AnyPrimitiveTransferRepresentation] {
        try Mirror(reflecting: self)
            ._reflectDescendant(at: "value")
            .unwrap()
            ._flattenAndDestructureTuple()
            .map {
                try _AnyPrimitiveTransferRepresentation(from: $0)
            }
    }
}
