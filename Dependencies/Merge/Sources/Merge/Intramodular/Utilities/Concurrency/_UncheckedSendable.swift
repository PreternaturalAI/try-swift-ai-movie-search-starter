//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

/// A property wrapper that declares a stored value as an `@unchecked Sendable`.
@propertyWrapper
public struct _UncheckedSendable<Value>: @unchecked Sendable {
    public var wrappedValue: Value
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    public init(initialValue: Value) {
        self.wrappedValue = initialValue
    }
    
    public init(_ value: Value) {
        self.init(wrappedValue: value)
    }
}
