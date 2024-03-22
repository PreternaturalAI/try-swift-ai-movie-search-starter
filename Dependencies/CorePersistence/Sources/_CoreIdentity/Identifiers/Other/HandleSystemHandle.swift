//
// Copyright (c) Vatsal Manot
//

import Swallow

/// http://www.cnri.reston.va.us/home/cstr/handle-overview.html
@_typeEraser(AnyHandleSystemHandle)
public protocol HandleSystemHandle: PersistentIdentifier {
    associatedtype NamingAuthority: CustomStringConvertible & LosslessStringConvertible
    associatedtype LocalIdentifier: CustomStringConvertible & LosslessStringConvertible
    
    var namingAuthority: NamingAuthority { get }
    var localIdentifier: LocalIdentifier { get }
}

public struct AnyHandleSystemHandle: HandleSystemHandle {
    public let namingAuthority: String
    public let localIdentifier: String
    
    public var body: some IdentityRepresentation {
        "\(namingAuthority)/\(localIdentifier)"
    }
    
    public init<T: HandleSystemHandle>(erasing handle: T) {
        self.namingAuthority = handle.namingAuthority.description
        self.localIdentifier = handle.localIdentifier.description
    }
}
