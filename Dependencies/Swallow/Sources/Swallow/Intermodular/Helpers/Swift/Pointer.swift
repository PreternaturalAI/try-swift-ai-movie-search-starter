//
// Copyright (c) Vatsal Manot
//

import Darwin
import Swift

public protocol OpaquePointerInitiable {
    init(_: OpaquePointer)
    init?(_: OpaquePointer?)
}

public protocol Pointer: Hashable, OpaquePointerInitiable, Strideable {
    associatedtype Pointee
    
    var pointee: Pointee { get }
    
    var opaquePointerRepresentation: OpaquePointer { get }
    var unsafePointerRepresentation: UnsafePointer<Pointee> { get }
    var unsafeMutablePointerRepresentation: UnsafeMutablePointer<Pointee> { get }
    
    init(_: UnsafeMutablePointer<Pointee>)
    init?(_: UnsafeMutablePointer<Pointee>?)
    
    func pointee(at _: Stride) -> Pointee
}

// MARK: - Implementation

extension Pointer {
    public var unsafePointerRepresentation: UnsafePointer<Pointee> {
        UnsafePointer(opaquePointerRepresentation)
    }
    
    public var unsafeMutablePointerRepresentation: UnsafeMutablePointer<Pointee> {
        UnsafeMutablePointer(opaquePointerRepresentation)
    }
    
    public func pointee(at stride: Stride) -> Pointee {
        advanced(by: stride).pointee
    }
    
    public subscript(offset: Stride) -> Pointee {
        @inlinable get {
            return pointee(at: offset)
        }
    }
}

// MARK: - Auxiliary

extension Pointer {
    @inlinable
    public init<P: MutablePointer>(_ pointer: P) where P.Pointee == Pointee {
        self.init(pointer.opaquePointerRepresentation)
    }
    
    @inlinable
    public init?<P: MutablePointer>(_ pointer: P?) where P.Pointee == Pointee {
        guard let pointer = pointer else {
            return nil
        }
        
        self.init(pointer)
    }
}

// MARK: - Extensions

extension Pointer {
    @inlinable
    public init<P: Pointer>(bitPattern: P) {
        self.init(bitPattern.mutableRawRepresentation.assumingMemoryBound(to: Pointee.self))
    }
}

extension Pointer {
    @_transparent
    public var nativeWordPointerRepresentation: UnsafePointer<NativeWord> {
        UnsafePointer<NativeWord>(opaquePointerRepresentation)
    }
    
    @_transparent
    public var rawRepresentation: UnsafeRawPointer {
        UnsafeRawPointer(opaquePointerRepresentation)
    }
    
    @_transparent
    public var mutableRawRepresentation: UnsafeMutableRawPointer {
        UnsafeMutableRawPointer(opaquePointerRepresentation)
    }
}

extension Pointer {
    @inlinable
    public static func allocate(initializingTo pointee: Pointee) -> Self {
        Self(UnsafeMutablePointer.allocate(capacity: 1).initializing(to: pointee))
    }
}

extension Pointer where Stride: BinaryInteger {
    @inlinable
    public static func allocate<N: BinaryInteger>(initializingTo pointee: Pointee, count: N) -> Self {
        Self(UnsafeMutablePointer<Pointee>.allocate(capacity: numericCast(count)).initializing(to: pointee, count: count))
    }
}

extension Pointer {
    @inlinable
    public static func to(_ pointee: inout Pointee) -> Self {
        Self(withUnsafeMutablePointer(to: &pointee, id))
    }
    
    @inlinable
    public static func to<T>(assumingLayoutCompatible value: inout T) -> Self {
        Self(UnsafePointer.to(&value).opaquePointerRepresentation)
    }
}

// MARK: - Auxiliary

@_transparent
public func unsafePartialBitCast<T, U>(
    _ x: T,
    to _: U.Type
) -> U {
    withUnsafePointer(to: x) { ptr in
        ptr.withMemoryRebound(to: U.self, capacity: 1) { ptr in
            return ptr.pointee
        }
    }
}

@_transparent
public func withMemoryRebound<T, U, ReturnType>(
    _ x: inout T,
    to _: U.Type,
    _ body: ((inout U) -> ReturnType)
) -> ReturnType {
    withUnsafeMutablePointer(to: &x) { ptr in
        ptr.withMemoryRebound(to: U.self, capacity: 1) { ptr in
            body(&ptr.pointee)
        }
    }
}

extension UnsafeMutablePointer {
    public var value: Pointee {
        @_transparent
        unsafeAddress {
            return UnsafePointer(self)
        }
        @_transparent
        nonmutating unsafeMutableAddress {
            return self
        }
    }
}

extension UnsafeRawPointer {
    @_transparent
    public func offset(
        of offset: Int
    ) -> UnsafeRawPointer {
        advanced(by: MemoryLayout<Int>.size * offset)
    }
    
    @_transparent
    public func offset<T>(
        of offset: Int,
        as type: T.Type
    ) -> UnsafeRawPointer {
        advanced(by: MemoryLayout<T>.size * offset)
    }
}

@inlinable
public func _reinterpretCast<T: Pointer, U: Pointer>(_ pointer: T) -> U {
    return U(pointer.opaquePointerRepresentation)
}

@inlinable
public func _reinterpretCast<T: Pointer, U: Pointer>(_ pointer: T?) -> U {
    return U(pointer!.opaquePointerRepresentation)
}

@inlinable
public func _reinterpretCast<T: Pointer, U: Pointer>(_ pointer: T) -> U? {
    return U(pointer.opaquePointerRepresentation)
}

@inlinable
public func _reinterpretCast<T: Pointer, U: Pointer>(_ pointer: T?) -> U? {
    return pointer.map(_reinterpretCast)
}
