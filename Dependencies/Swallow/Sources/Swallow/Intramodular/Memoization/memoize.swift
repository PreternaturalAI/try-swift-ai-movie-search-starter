//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

@inlinable
@inline(__always)
public func _memoize<Key: Hashable, Result>(
    uniquingWith key: Key,
    file: StaticString = #fileID,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column,
    operation: () -> Result
) -> Result {
    let location = SourceCodeLocation(file: file, function: function, line: line, column: column)
    
    return _GloballyMemoizedValues[location][key, operation: operation]
}

@inlinable
@inline(__always)
public func _memoize<K0: Hashable, K1: Hashable, Result>(
    uniquingWith key: (K0, K1),
    file: StaticString = #fileID,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column,
    operation: () -> Result
) -> Result {
    _memoize(
        uniquingWith: Hashable2ple(key),
        file: file,
        function: function,
        line: line,
        column: column,
        operation: operation
    )
}

@inlinable
@inline(__always)
public func _memoize<K0: Hashable, K1: Hashable, K2: Hashable, Result>(
    uniquingWith key: (K0, K1, K2),
    file: StaticString = #fileID,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column,
    operation: () -> Result
) -> Result {
    _memoize(
        uniquingWith: Hashable2ple(key),
        file: file,
        function: function,
        line: line,
        column: column,
        operation: operation
    )
}

@inlinable
@inline(__always)
public func _memoize<T: Hashable, Result>(
    uniquingWith key: T,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column,
    _ expression: @autoclosure () -> Result
) -> Result {
    _memoize(
        uniquingWith: key,
        file: file,
        function: function,
        line: line,
        column: column,
        operation: {
            expression()
        }
    )
}

@usableFromInline
struct _GloballyMemoizedValues {
    @usableFromInline
    class _KeyValueMap {
        let lock = OSUnfairLock()

        @usableFromInline
        var storage: [Int: Any] = [:]
        
        init() {
            
        }
        
        @inline(__always)
        @usableFromInline
        subscript<Key: Hashable, Result>(
            _ key: Key,
            operation fn: () -> Result
        ) -> Result {
            get {
                lock.withCriticalScope {
                    guard let result = storage[key.hashValue].map({ $0 as! Result }) else {
                        let result = fn()
                        
                        storage[key.hashValue] = result
                        
                        return result
                    }
                    
                    return result
                }
            }
        }
    }
    
    private static let lock = OSUnfairLock()
    private static var storage: [SourceCodeLocation: _KeyValueMap] = [:]
    
    @inline(__always)
    @usableFromInline
    static subscript(_ location: SourceCodeLocation) -> _KeyValueMap {
        get {
            lock.withCriticalScope {
                storage[location, defaultInPlace: .init()]
            }
        }
    }
}
