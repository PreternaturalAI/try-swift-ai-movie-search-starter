//
// Copyright (c) Vatsal Manot
//

import Combine
import FoundationX
import Swallow
import SwiftUI

@dynamicMemberLookup
@propertyWrapper
public final class PublishedAsyncBinding<Value>: ObservableObject {
    public typealias _Self = PublishedAsyncBinding
    
    private lazy var _wrappedValueObjectWillChangeRelay = ObjectWillChangePublisherRelay<Value, PublishedAsyncBinding<Value>>(destination: self)
    private let _enclosingInstanceObjectWillChangeRelay = ObjectWillChangePublisherRelay()
    
    private let cancellables = Cancellables()
    private let subject = _MultiReaderSubject<Value, Never>()
    
    @Published private var value: Value
    
    private var cache: (any SingleValueCache<Value>)?
    private let accessor: _AsyncElementAccessor<Value>
    
    public var animation: Animation?
    
    @MainActor
    private var _wrappedValue: Value {
        get {
            value
        } set {
            value = newValue
            
            _wrappedValueObjectWillChangeRelay.source = value
            
            subject.send(newValue)
        }
    }
    
    @MainActor
    public var wrappedValue: Value {
        get {
            value
        } set {
            if let animation {
                withAnimation(animation) {
                    value = newValue
                }
            } else {
                value = newValue
            }
        }
    }
    
    public var projectedValue: Published<Value>.Publisher {
        $value
    }
    
    public init(
        accessor: _AsyncElementAccessor<Value>,
        cache: any SingleValueCache<Value> = InMemorySingleValueCache(),
        defaultValue: () -> Value,
        debounceInterval: DispatchQueue.SchedulerTimeType.Stride?
    ) {
        self.accessor = accessor
        self.cache = cache
        
        let cachedValue = cache.retrieve()
        
        self.value = cachedValue ?? defaultValue()
        
        _wrappedValueObjectWillChangeRelay.source = self.value
        
        if cachedValue == nil {
            cache.store(self.value)
        }
        
        accessor
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] newValue in
                self?.didReceiveNewValueFromUpstream(newValue)
            })
            .store(in: cancellables)
        
        setUpValueAssignmentObserver(debounceInterval: debounceInterval)
        
        subject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.value = newValue
            }
            .store(in: cancellables)
    }
    
    /// Set up the sink that pushes value assignments to upstream.
    private func setUpValueAssignmentObserver(
        debounceInterval: DispatchQueue.SchedulerTimeType.Stride?
    ) {
        var debounceInterval = debounceInterval
        
        if debounceInterval == .zero {
            debounceInterval = nil
        }
        
        if let debounceInterval {
            $value
                .dropFirst()
                .debounce(for: debounceInterval, scheduler: DispatchQueue.main)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newValue in
                    self?.didReceiveNewValueByAssignment(newValue)
                }
                .store(in: cancellables)
        } else {
            $value
                .dropFirst()
                .sink { [weak self] newValue in
                    self?.didReceiveNewValueByAssignment(newValue)
                }
                .store(in: cancellables)
        }
    }
    
    @MainActor
    public static subscript<EnclosingSelf>(
        _enclosingInstance enclosingInstance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, _Self>
    ) -> Value {
        get {
            let propertyWrapper = enclosingInstance[keyPath: storageKeyPath]
            
            if propertyWrapper._enclosingInstanceObjectWillChangeRelay.isUninitialized {
                propertyWrapper._enclosingInstanceObjectWillChangeRelay.source = propertyWrapper
                propertyWrapper._enclosingInstanceObjectWillChangeRelay.destination = enclosingInstance
            }
            
            return propertyWrapper.wrappedValue
        } set {
            let propertyWrapper = enclosingInstance[keyPath: storageKeyPath]
            
            propertyWrapper._enclosingInstanceObjectWillChangeRelay.source = propertyWrapper
            propertyWrapper._enclosingInstanceObjectWillChangeRelay.destination = enclosingInstance
            
            propertyWrapper.wrappedValue = newValue
        }
    }
    
    var isReceivingValueByAssignment: Bool = false
    
    private func didReceiveNewValueByAssignment(
        _ newValue: Value
    ) {
        guard !isReceivingValueByAssignment else {
            return
        }
        
        isReceivingValueByAssignment = true
        
        accessor.send(newValue)
        
        cache?.store(newValue)
        
        isReceivingValueByAssignment = false
    }
    
    private func didReceiveNewValueFromUpstream(
        _ newValue: Value
    ) {
        if let cachedValue = cache?.retrieve() {
            guard !AnyEquatable.equate(cachedValue, newValue) else {
                return
            }
            
            let resolvedValue = resolveConflict(latest: newValue, cached: cachedValue)
            
            value = resolvedValue
            
            cache?.store(resolvedValue)
        } else {
            value = newValue
        }
    }
    
    private func resolveConflict(latest: Value, cached: Value) -> Value {
        return latest
    }
    
    public subscript<Subject>(
        dynamicMember keyPath: WritableKeyPath<Value, Subject>
    ) -> PublishedAsyncBinding<Subject> {
        get {
            map(keyPath)
        }
    }
}

// MARK: - Initializers

extension PublishedAsyncBinding {
    @MainActor
    public convenience init(
        wrappedValue: Value
    ) {
        let referenceBox = ReferenceBox(wrappedValue: wrappedValue)
        
        self.init(
            accessor: .init(referenceBox),
            cache: InMemorySingleValueCache(wrappedValue),
            defaultValue: { wrappedValue },
            debounceInterval: nil
        )
    }
    
    @MainActor
    public convenience init(
        from binding: Binding<Value>
    ) {
        self.init(
            accessor: .init(binding),
            cache: InMemorySingleValueCache(binding.wrappedValue),
            defaultValue: { binding.wrappedValue },
            debounceInterval: nil
        )
    }
}

extension PublishedAsyncBinding {
    public static func unsafelyUnwrapping<T: AnyObject>(
        _ root: T,
        _ keyPath: ReferenceWritableKeyPath<T, Value?>,
        initial: Value? = nil
    ) -> PublishedAsyncBinding {
        let currentValue: Value = (root[keyPath: keyPath] ?? initial)!
        
        return self.init(
            accessor: .anonymous(
                .init(
                    upstream: Deferred { [weak root] in
                        guard let root else {
                            assertionFailure()
                            
                            return Just(currentValue)
                        }
                        
                        return Just(root[keyPath: keyPath] ?? currentValue)
                    }
                        .eraseToAnyPublisher(),
                    push: { [weak root] in
                        guard let root = `root` else {
                            assertionFailure()
                            
                            return
                        }
                        
                        root[keyPath: keyPath] = $0
                    }
                )
            ),
            defaultValue: {
                currentValue
            },
            debounceInterval: .milliseconds(200)
        )
    }
    
    public static func unsafelyUnwrapping<T: AnyObject>(
        _ root: T,
        _ keyPath: ReferenceWritableKeyPath<T, Value>
    ) -> PublishedAsyncBinding {
        let currentValue: Value = root[keyPath: keyPath]
        
        return self.init(
            accessor: .anonymous(
                .init(
                    upstream: Deferred { [weak root] in
                        guard let root else {
                            assertionFailure()
                            
                            return Just(currentValue)
                        }
                        
                        return Just(root[keyPath: keyPath])
                    }
                        .eraseToAnyPublisher(),
                    push: { [weak root] in
                        guard let root = `root` else {
                            assertionFailure()
                            
                            return
                        }
                        
                        root[keyPath: keyPath] = $0
                    }
                )
            ),
            defaultValue: {
                currentValue
            },
            debounceInterval: .milliseconds(200)
        )
    }
    
    @_disfavoredOverload
    public static func unsafelyUnwrapping<T: AnyObject, U>(
        _ root: T,
        _ keyPath: ReferenceWritableKeyPath<T, U>,
        as type: Value.Type
    ) -> PublishedAsyncBinding? {
        guard let currentValue: Value = root[keyPath: keyPath] as? Value else {
            return nil
        }
        
        return self.init(
            accessor: .anonymous(
                .init(
                    upstream: Deferred { [weak root] in
                        guard let root else {
                            assertionFailure()
                            
                            return Just(currentValue)
                        }
                        
                        return Just(root[keyPath: keyPath] as! Value)
                    }
                        .eraseToAnyPublisher(),
                    push: { [weak root] (newValue: Value) in
                        guard let root = `root` else {
                            assertionFailure()
                            
                            return
                        }
                        
                        root[keyPath: keyPath] = newValue as! U
                    }
                )
            ),
            defaultValue: {
                currentValue
            },
            debounceInterval: .milliseconds(200)
        )
    }
    
    public static func unwrapping<T: AnyObject, Result>(
        _ root: T,
        _ keyPath: ReferenceWritableKeyPath<T, Value?>,
        operation: (PublishedAsyncBinding<Value>) -> Result
    ) -> Result? {
        guard root[keyPath: keyPath] != nil else {
            return nil
        }
        
        return operation(unsafelyUnwrapping(root, keyPath))
    }
}

// MARK: - Auxiliary

public enum _AsyncElementAccessor<Element>: Publisher {
    public typealias Output = Element
    public typealias Failure = Never
    
    public struct _AnonymousPushPull {
        let upstream: AnyPublisher<Element, Never>
        let push: (Element) -> Void
        
        public init(upstream: AnyPublisher<Element, Never>, push: @escaping (Element) -> Void) {
            self.upstream = upstream
            self.push = push
        }
        
        public init(upstream: some Publisher<Element, Never>, push: @escaping (Element) -> Void) {
            self.upstream = upstream.eraseToAnyPublisher()
            self.push = push
        }
    }
    
    case anonymous(_AnonymousPushPull)
    case multiReaderSubjectChild(_MultiReaderSubject<Element, Never>.Child)
    
    public init(
        _ binding: Binding<Element>
    ) {
        self = .anonymous(
            .init(
                upstream: Deferred(createPublisher: { Just(binding.wrappedValue) }).eraseToAnyPublisher(),
                push: {
                    binding.wrappedValue = $0
                }
            )
        )
    }
    
    public init<P: AnyObject & MutablePropertyWrapper<Element>>(
        _ wrapper: P
    ) {
        self = .anonymous(
            .init(
                upstream: Deferred {
                    Just(wrapper.wrappedValue)
                }
                    .eraseToAnyPublisher(),
                push: {
                    var wrapper = wrapper
                    
                    wrapper.wrappedValue = $0
                }
            )
        )
    }
    
    public func send(_ value: Element) {
        switch self {
            case .anonymous(let accessor):
                accessor.push(value)
            case .multiReaderSubjectChild(let subject):
                subject.send(value)
        }
    }
    
    public func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Element, S.Failure == Never {
        switch self {
            case .anonymous(let source):
                source.upstream.receive(subscriber: subscriber)
            case .multiReaderSubjectChild(let subject):
                subject.receive(subscriber: subscriber)
        }
    }
}

extension PublishedAsyncBinding {
    public func map<T>(
        get: @escaping (Value) -> T,
        set: @escaping (inout Value, T) -> Void
    ) -> PublishedAsyncBinding<T> {
        let cache = InMemorySingleValueCache<T>()
        
        let initialValue = get(value)
        
        cache.store(initialValue)
        
        let subject = self.subject.child()
        
        let accessor = _AsyncElementAccessor<T>._AnonymousPushPull(
            upstream: subject.map(get).eraseToAnyPublisher(),
            push: { [weak self] newValue in
                guard let `self` = self else {
                    assertionFailure()
                    
                    return
                }
                
                var rootValue = self.value
                
                set(&rootValue, newValue)
                
                subject.send(rootValue)
            }
        )
        
        return PublishedAsyncBinding<T>(
            accessor: .anonymous(accessor),
            cache: cache,
            defaultValue: { initialValue },
            debounceInterval: 0
        )
    }
    
    public func map<T>(
        _ keyPath: WritableKeyPath<Value, T>
    ) -> PublishedAsyncBinding<T> {
        map(
            get: {
                $0[keyPath: keyPath]
            },
            set: {
                $0[keyPath: keyPath] = $1
            }
        )
    }
}
