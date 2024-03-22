//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Compute
import Merge
import Swallow

/// Makes no assumptions about transport.
///
/// Not called "reference"/"container" intentionally.
public protocol _AsyncResourceCoordinator: Identifiable {
    associatedtype Value
    
    func _getSynchronously() throws -> Value
    
    func get() async throws -> Value
}

public protocol _AsyncMutableResourceCoordinator: _AsyncResourceCoordinator {
    func update(_: Value) async throws
}

public struct _AnyAsyncResourceCoordinator<Value>: _AsyncResourceCoordinator {
    private let _getSynchronouslyImpl: () throws -> Value
    
    public let id: AnyHashable
    
    public init(id: AnyHashable, get: @escaping () throws -> Value) {
        self.id = id
        self._getSynchronouslyImpl = get
    }
    
    public func _getSynchronously() throws -> Value {
        try self._getSynchronouslyImpl()
    }
    
    public func get() async throws -> Value {
        try self._getSynchronously() // FIXME!!
    }
}
