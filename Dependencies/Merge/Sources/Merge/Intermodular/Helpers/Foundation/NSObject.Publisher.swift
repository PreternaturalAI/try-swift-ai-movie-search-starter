//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

extension NSObject {
    /// Publish values when the value identified by a KVO-compliant keypath changes.
    @_spi(Internal)
    public func publisher<Value>(
        for keyPath: String,
        type: Value.Type = Value.self,
        initial: Bool = false
    ) -> AnyPublisher<Value, Never> {
        StringKeyValueObservingPublisher(
            object: self,
            keyPath: keyPath,
            initial: initial
        )
        .eraseToAnyPublisher()
    }
    
    fileprivate struct StringKeyValueObservingPublisher<Value>: Combine.Publisher {
        typealias Output = Value
        typealias Failure = Never
        
        let object: NSObject
        let keyPath: String
        let initial: Bool
        
        func receive<S: Combine.Subscriber>(
            subscriber: S
        ) where Failure == S.Failure, Output == S.Input {
            let subscription = Subscription(
                subscriber: subscriber,
                object: object,
                keyPath: keyPath
            )
            
            subscriber.receive(subscription: subscription)
            
            subscription.register(initial: initial)
        }
    }
}

private extension NSObject.StringKeyValueObservingPublisher {
    private final class Subscription<S: Subscriber>: NSObject, Combine.Subscription where S.Input == Value {
        private var subscriber: S?
        private var object: NSObject?
        private let keyPath: String
        private var demand: Subscribers.Demand = .none
        
        init(subscriber: S, object: NSObject?, keyPath: String) {
            self.subscriber = subscriber
            self.object = object
            self.keyPath = keyPath
        }
        
        func request(_ demand: Subscribers.Demand) {
            self.demand += demand
        }
        
        func register(initial: Bool) {
            self.object?.addObserver(
                self,
                forKeyPath: keyPath,
                options: initial ? [.new, .initial] : [.new],
                context: nil
            )
        }
        
        func cancel() {
            self.object?.removeObserver(self, forKeyPath: keyPath)
            self.object = nil
            self.subscriber = nil
        }
        
        override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey: Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            guard keyPath == keyPath, object as? NSObject == self.object else {
                return super.observeValue(
                    forKeyPath: keyPath,
                    of: object,
                    change: change,
                    context: context
                )
            }
            
            guard demand > 0, let subscriber = self.subscriber else {
                return
            }
            
            let newValue: Value = change?[.newKey] as! Value
            
            demand -= 1
            demand += subscriber.receive(newValue)
        }
        
        deinit {
            cancel()
        }
    }
}
