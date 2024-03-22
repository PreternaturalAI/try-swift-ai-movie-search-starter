//
// Copyright (c) Vatsal Manot
//

#if os(macOS)
import AppKit
#endif
import Combine
import Swift
import SwiftUI
#if os(iOS)
import UIKit
#endif

/// An enumeration that represents either a screen or a SwiftUI `CoordinateSpace`.
public enum _ScreenOrCoordinateSpace: Hashable {
    case cocoa(Screen?)
    case coordinateSpace(CoordinateSpace)
    
    public var _cocoaScreen: Screen? {
        guard case .cocoa(let screen) = self else {
            return nil
        }
        
        return screen
    }
}

extension _ScreenOrCoordinateSpace {
    public static var local: Self {
        .coordinateSpace(.local)
    }
    
    public static var global: Self {
        .coordinateSpace(.global)
    }
}

/// A value relative to one or multiple coordinate spaces.
public struct _CoordinateSpaceRelative<Value: Equatable>: Equatable {
    private weak var __sourceAppKitOrUIKitWindow: NSObject?
        
    private var storage: [_ScreenOrCoordinateSpace: Value] = [:]
    
    init(
        storage: [_ScreenOrCoordinateSpace: Value],
        _sourceAppKitOrUIKitWindow: NSObject?
    ) {
        self.storage = storage
        self.__sourceAppKitOrUIKitWindow = _sourceAppKitOrUIKitWindow
    }
    
    public init() {
        
    }
    
    public init(_ value: Value, in space: _ScreenOrCoordinateSpace) {
        self.storage[space] = value
    }
    
    public func first(
        where predicate: (_ScreenOrCoordinateSpace) -> Bool
    ) -> (_ScreenOrCoordinateSpace, Value)? {
        storage.first(where: { predicate($0.key) })
    }
    
    public subscript(
        _ key: _ScreenOrCoordinateSpace
    ) -> Value? {
        get {
            storage[key]
        } set {
            storage[key] = newValue
        }
    }
    
    public subscript<T>(
        _ keyPath: KeyPath<Value, T>
    ) -> _CoordinateSpaceRelative<T> {
        get {
            .init(
                storage: self.storage.compactMapValues({ $0[keyPath: keyPath] }),
                _sourceAppKitOrUIKitWindow: __sourceAppKitOrUIKitWindow
            )
        }
    }
    
    @_spi(Internal)
    public subscript<T>(
        _unsafe keyPath: WritableKeyPath<Value, T>
    ) -> T {
        get {
            self.storage.first!.value[keyPath: keyPath]
        } set {
            self.storage.keys.forEach { key in
                self.storage[key]![keyPath: keyPath] = newValue
            }
        }
    }
}

#if os(iOS) || os(macOS)
extension _CoordinateSpaceRelative {
    public var _sourceAppKitOrUIKitWindow: AppKitOrUIKitWindow? {
        get {
            __sourceAppKitOrUIKitWindow as? AppKitOrUIKitWindow
        } set {
            __sourceAppKitOrUIKitWindow = newValue
        }
    }
}
#endif

extension _CoordinateSpaceRelative where Value == CGPoint {
    public func offset(x: CGFloat, y: CGFloat) -> Self {
        var storage = self.storage
        
        for (key, value) in storage {
            switch key {
                case .cocoa:
                    storage[key] = CGPoint(x: value.x + x, y: value.y + y)
                case .coordinateSpace:
                    storage[key] = CGPoint(x: value.x + x, y: value.y + y)
            }
        }
        
        return Self(
            storage: storage,
            _sourceAppKitOrUIKitWindow: __sourceAppKitOrUIKitWindow
        )
    }
    
    public func offset(_ offset: CGPoint) -> Self {
        self.offset(x: offset.x, y: offset.y)
    }
}

extension _CoordinateSpaceRelative where Value == CGRect {
    public static var zero: Self {
        .init(.zero, in: .coordinateSpace(.global))
    }
    
    public var size: CGSize {
        get {
            storage.first!.value.size
        } set {
            storage.keys.forEach { key in
                storage[key]!.size = newValue
            }
        }
    }
}
