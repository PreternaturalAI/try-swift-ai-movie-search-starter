//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

public protocol _AsyncStorageBase<WrappedValue, ProjectedValue>: ObservableObject where ObjectWillChangePublisher.Output == Void, ObjectWillChangePublisher.Failure == Never {
    associatedtype WrappedValue
    associatedtype ProjectedValue
    
    var wrappedValue: WrappedValue { get }
    var projectedValue: ProjectedValue { get }
}
