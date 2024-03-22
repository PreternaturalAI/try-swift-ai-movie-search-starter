//
// Copyright (c) Vatsal Manot
//

import Swift

/// A publisher that delivers the result of a task.
public struct TaskSuccessPublisher<Upstream: ObservableTask>: SingleOutputPublisher {
    public typealias Output = Upstream.Success
    public typealias Failure = TaskFailure<Upstream.Error>
    
    private let upstream: Upstream
    
    public init(upstream: Upstream) {
        self.upstream = upstream
    }
    
    public func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Output, S.Failure == Failure {
        upstream
            .outputPublisher
            .compactMap({ $0.value })
            .receive(subscriber: subscriber)
    }
}

// MARK: - API

extension ObservableTask {
    /// A publisher that delivers the result of a task.
    public var successPublisher: TaskSuccessPublisher<Self> {
        .init(upstream: self)
    }
    
    /// The successful result of a task, after it completes.
    ///
    /// - returns: The task's successful result.
    /// - throws: An error indicating task failure or task cancellation.
    public var value: Success {
        get async throws {
            try await successPublisher.output()
        }
    }
}
