//
// Copyright (c) Vatsal Manot
//

import Swift

/// A type which exposes a view of the embedded information within certain UUIDs.
///
public protocol _UUIDv6Components {
    init?(_ uuid: UUIDv6)
}

// Note: Why '.components()' uses an @autoclosure:
//
// So, we want UUIDv6.Components to be a protocol, and the user provides the type
// and we construct an instance. Normally you'd write that like this:
//
// func components<ViewType: Components>(_: ViewType.Type) -> ViewType?
//
// And the user would write:
//
// uuid.components(TimeOrderedComponents.self)?.timestamp
//
// But that kind of sucks. We'd like to take advantage of static-member syntax:
//
// uuid.components(.timeOrdered)?.timestamp
//
// Unfortunately, the regular way of expressing this doesn't work:
//
// extension UUID.Components where Self == TimeOrderedComponents {
//   public static var timeOrdered: Self { ... }
// }
//
// We would need to provide a dummy instance. And changing the type of the computed property `timeOrdered`
// to `Self.Type` or `TimeOrderedComponents.Type` doesn't work - the compiler doesn't like it.
// Hence, the workaround: use an @autoclosure parameter, which to the type-checker looks like it returns
// an instance (but really just fatalErrors). We don't need to create a dummy instance and
// we get static member syntax:
//
// func components<ViewType: Components>(_: @autoclosure () -> ViewType) -> ViewType? { ... }
//
// extension UUIDv6.Components where Self == TimeOrderedComponents {
//   public static var timeOrdered: Self { fatalError("Not intended to be called") }
// }
//
// components(.timeOrdered)?.timestamp // works.

extension UUIDv6 {
    
    /// A view of the embedded information within certain UUIDs.
    ///
    public typealias Components = _UUIDv6Components
    
    /// Returns a view of the embedded information within this UUID.
    ///
    /// The following example demonstrates extracting the timestamp from a time-ordered UUID.
    ///
    /// ```swift
    /// let id = UUIDv6("1EC5FE44-E511-6910-BBFA-F7B18FB57436")!
    /// id.components(.timeOrdered)?.timestamp
    /// // ✅ "2021-12-18 09:24:31 +0000"
    /// ```
    ///
    @inlinable
    public func components<ViewType: Components>(_: @autoclosure () -> ViewType) -> ViewType? {
        ViewType(self)
    }
}
