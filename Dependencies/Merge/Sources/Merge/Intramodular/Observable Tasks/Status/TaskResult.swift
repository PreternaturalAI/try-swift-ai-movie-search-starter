//
// Copyright (c) Vatsal Manot
//

import Swift

/// The result of a `Task`.
public enum TaskResult<Success, Error: Swift.Error> {
    case canceled
    case success(Success)
    case error(Error)
    
    public var value: Success? {
        if case .success(let value) = self {
            return value
        } else {
            return nil
        }
    }
    
    public init?(_ status: TaskStatus<Success, Error>) {
        switch status {
            case .idle:
                return nil
            case .active:
                return nil
            case .paused:
                return nil
            case .canceled:
                self = .canceled
            case .success(let success):
                self = .success(success)
            case .error(let error):
                self = .error(error)
        }
    }
    
    public init?(from result: Result<TaskOutput<Success, Error>, TaskFailure<Error>>) {
        switch result {
            case .success(let output):
                guard let success = output.value else {
                    return nil
                }
                
                self = .success(success)
            case .failure(let failure):
                switch failure {
                    case .canceled:
                        self = .canceled
                    case .error(let error):
                        self = .error(error)
                }
        }
    }
    
    /// Returns the success value as a throwing expression.
    public func get() throws -> Success {
        try Result(from: self).unwrap().get()
    }
}

extension TaskResult {
    public func map<T>(_ transform: (Success) throws -> T) rethrows -> TaskResult<T, Error> {
        switch self {
            case .canceled:
                return .canceled
            case .success(let success):
                return try .success(transform(success))
            case .error(let error):
                return .error(error)
        }
    }
    
    public func mapError<T: Swift.Error>(_ transform: (Error) throws -> T) rethrows -> TaskResult<Success, T> {
        switch self {
            case .canceled:
                return .canceled
            case .success(let success):
                return .success(success)
            case .error(let error):
                return try .error(transform(error))
        }
    }
}

// MARK: - Conformances

extension TaskResult: Sendable where Success: Sendable {
    
}

// MARK: - Supplementary

extension TaskStatus {
    public init(_ result: TaskResult<Success, Error>) {
        switch result {
            case .canceled:
                self = .canceled
            case .success(let value):
                self = .success(value)
            case .error(let error):
                self = .error(error)
        }
    }
}

// MARK: - Auxiliary

extension TaskResult {
    public enum Comparison {
        case canceled
        case success
        case error
        
        public static func == (lhs: Comparison, rhs: TaskResult) -> Bool {
            switch (lhs, rhs) {
                case (.canceled, .canceled):
                    return true
                case (.success, .success):
                    return true
                case (.error, .error):
                    return true
                    
                default:
                    return false
            }
        }
        
        public static func == (lhs: TaskResult, rhs: Comparison) -> Bool {
            rhs == lhs
        }
    }
}

extension Result {
    public init?(from result: TaskResult<Success, Failure>) {
        switch result {
            case .canceled:
                return nil
            case .success(let value):
                self = .success(value)
            case .error(let error):
                self = .failure(error)
        }
    }
}
