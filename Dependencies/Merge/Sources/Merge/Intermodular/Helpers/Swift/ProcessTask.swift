//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Combine
import Foundation
import Swallow
import System
import os

extension Process {
    public final class Task: ObservableTask {
        public typealias Success = Void
        
        public enum Error: Swift.Error {
            case exitFailure(ProcessExitFailure)
            case unknown(Swift.Error)
        }
        
        public let process: Process
        
        private let base = PassthroughTask<Void, Error>()
        
        private let standardOutputPipe = Pipe()
        private let standardOutputData = PassthroughSubject<Data, Never>()
        private let standardErrorPipe = Pipe()
        private let standardErrorData = PassthroughSubject<Data, Never>()
        
        public var id: some Hashable {
            process.processIdentifier
        }
        
        public var status: TaskStatus<Success, Error> {
            base.status
        }
        
        public var objectWillChange: AnyObjectWillChangePublisher {
            .init(from: base)
        }
        
        public var objectDidChange: AnyPublisher<TaskStatus<Success, Error>, Never> {
            base.objectDidChange
        }
        
        public init(process: Process) {
            self.process = process
        }
        
        public func start() {
            guard status == .idle else {
                return
            }
            
            setupPipes()
            
            process.terminationHandler = { [weak self] process in
                guard let `self` = self else {
                    return
                }
                
                self.teardownPipes()
                
                let terminationStatus = process.terminationStatus
                
                if terminationStatus == 0 {
                    self.base.send(status: .success(()))
                } else {
                    self.base.send(status: .error(.exitFailure(.exit(status: terminationStatus))))
                }
            }
            
            do {                
                try process.run()
                
                base.send(status: .active)
            } catch {
                base.send(status: .error(.unknown(error)))
                
                if let errorData = error.localizedDescription.data(using: .utf8) {
                    standardErrorData.send(errorData)
                }
                
                teardownPipes()
            }
        }
        
        public func cancel() {
            process.terminate()
            
            base.send(status: .canceled)
        }
    }
}

extension Process.Task {
    private func setupPipes() {
        guard !process.isRunning else {
            return
        }
        
        standardOutputPipe.fileHandleForReading.readabilityHandler = {
            let data = $0.availableData
            
            if data.isEmpty {
                return self.standardOutputPipe.fileHandleForReading.readabilityHandler = nil
            }
            
            self.standardOutputData.send(data)
        }
        
        standardErrorPipe.fileHandleForReading.readabilityHandler = {
            let data = $0.availableData
            
            if data.isEmpty {
                return self.standardErrorPipe.fileHandleForReading.readabilityHandler = nil
            }
            
            self.standardErrorData.send(data)
        }
        
        process.standardOutput = standardOutputPipe
        process.standardError = standardErrorPipe
    }
    
    private func teardownPipes() {
        standardOutputPipe.fileHandleForReading.readabilityHandler?(standardOutputPipe.fileHandleForReading)
        standardErrorPipe.fileHandleForReading.readabilityHandler?(standardErrorPipe.fileHandleForReading)
        
        standardOutputData.send(completion: .finished)
        standardErrorData.send(completion: .finished)
    }
}

// MARK: - Initializers

extension Process.Task {
    public convenience init(
        currentDirectoryURL: URL? = nil,
        executableURL: URL,
        arguments: [String],
        environment: [String: String]? = nil
    ) {
        let process = Process()
        
        process.currentDirectoryURL = currentDirectoryURL
        process.executableURL = executableURL
        process.arguments = arguments
        process.environment = environment
        
        self.init(process: process)
    }
    
    public convenience init(
        currentDirectoryURL: URL? = nil,
        executablePath: String,
        arguments: [String],
        environment: [String: String]? = nil
    ) {
        let process = Process()
        
        process.currentDirectoryURL = currentDirectoryURL
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.environment = environment
        
        self.init(process: process)
    }
    
    public convenience init(
        currentDirectoryPath: FilePath? = nil,
        executablePath: FilePath,
        arguments: [String],
        environment: [String: String]? = nil
    ) {
        let process = Process()
        
        process.currentDirectoryURL = currentDirectoryPath.flatMap({ URL(_filePath: $0) })
        process.executableURL = URL(_filePath: executablePath)
        process.arguments = arguments
        process.environment = environment
        
        self.init(process: process)
    }
}

// MARK: - API

extension Process.Task {
    public var terminationStatus: Int32 {
        process.terminationStatus
    }
}

extension Process.Task {
    public var standardOutputAndErrorPublisher: AnyPublisher<Either<Data, Erroneous<Data>>, Never> {
        Publishers.Merge(
            standardOutputData.map({ .left($0) }),
            standardErrorData.map({ .right(.init($0)) })
        )
        .handleEvents(receiveSubscription: { _ in self.start() })
        .eraseToAnyPublisher()
    }
    
    public var standardOutputAndErrorLinesPublisher: AnyPublisher<Either<String, Erroneous<String>>, Never> {
        Publishers.Merge(
            standardOutputData.lines().map({ .left($0) }),
            standardErrorData.lines().map({ .right(.init($0)) })
        )
        .handleEvents(receiveSubscription: { _ in self.start() })
        .eraseToAnyPublisher()
    }
}

#endif
