//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Runtime
import Swallow

public protocol AsyncStorageProjectionElement<Value> {
    associatedtype Value
    associatedtype ValuesPublisher: Publisher<Value, Never> where ValuesPublisher.Output == Value, ValuesPublisher.Failure == Never // FIXME: Allow errors
    
    var upstreamValuesPublisher: ValuesPublisher { get }
    
    func send(_ value: Value) async
}

@propertyWrapper
public final class AsyncStorage<WrappedValue, ProjectedValue>: ObservableObject, PropertyWrapper {
    private var base: any _AsyncStorageBase<WrappedValue, ProjectedValue>
    private let objectWillChangeRelay = ObjectWillChangePublisherRelay()
        
    public var objectWillChange: AnyObjectWillChangePublisher {
        base.eraseObjectWillChangePublisher()
    }
    
    public static subscript<EnclosingSelf: ObservableObject>(
        _enclosingInstance enclosingInstance: EnclosingSelf,
        wrapped wrappedKeyPath: KeyPath<EnclosingSelf, WrappedValue>,
        storage storageKeyPath: KeyPath<EnclosingSelf, AsyncStorage>
    ) -> WrappedValue {
        let propertyWrapper = enclosingInstance[keyPath: storageKeyPath]
        
        propertyWrapper.objectWillChangeRelay.source = propertyWrapper
        propertyWrapper.objectWillChangeRelay.destination = enclosingInstance
        
        return propertyWrapper.wrappedValue
    }
        
    public var wrappedValue: WrappedValue {
        get {
            base.wrappedValue
        }
    }
    
    init<Base: _AsyncStorageBase<WrappedValue, ProjectedValue>>(
        base: Base
    ) {
        self.base = base
    }
}
