//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

/// A logger that broadcasts its entries.
public final class PassthroughLogger: @unchecked Sendable, LoggerProtocol, ObservableObject {
    public typealias LogLevel = ClientLogLevel
    public typealias LogMessage = Message
    
    @usableFromInline
    let base: _PassthroughLogger
    
    private init(base: _PassthroughLogger) {
        self.base = base
    }
    
    public var source: Source {
        base.source
    }
    
    public convenience init(source: Source) {
        self.init(base: .init(source: source))
    }
    
    public convenience init(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = #column
    ) {
        self.init(
            source: .location(
                SourceCodeLocation(
                    file: file,
                    function: function,
                    line: line,
                    column: column
                )
            )
        )
    }
}

extension LoggerProtocol where Self: PassthroughLogger {
    @_transparent
    public func log(
        level: LogLevel,
        _ message: @autoclosure () -> LogMessage,
        metadata: @autoclosure () -> [String: Any]?,
        file: String,
        function: String,
        line: UInt
    ) {
        if Thread.isMainThread {
            objectWillChange.send()
        } else {
            DispatchQueue.main.async { 
                self.objectWillChange.send()
            }
        }
        
        if _isDebugAssertConfiguration {
            if level == .error {
                runtimeIssue(message().description)
            }
        }
        
        base.log(
            level: level,
            message(),
            metadata: metadata(),
            file: file,
            function: function,
            line: line
        )
    }
}

extension PassthroughLogger: _LogExporting {
    public func exportLog() async throws -> some _LogFormat {
        try await base.exportLog()
    }
}

// MARK: - Conformances

extension PassthroughLogger: ScopedLogger {
    public func scoped(to scope: AnyLogScope) throws -> PassthroughLogger {
        PassthroughLogger(base: try base.scoped(to: scope))
    }
}

extension PassthroughLogger: TextOutputStream {
    public func write(_ string: String) {
        base.write(string)
    }
}

// MARK: - Extensions

extension PassthroughLogger {
    public var dumpToConsole: Bool {
        get {
            base.configuration.dumpToConsole
        } set {
            base.configuration.dumpToConsole = newValue
        }
    }
}

// MARK: - Auxiliary

extension PassthroughLogger {
    public struct Message: Codable, CustomStringConvertible, Hashable, LogMessageProtocol {
        public typealias StringLiteralType = String
        
        private var rawValue: String
        
        public var description: String {
            rawValue
        }
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(stringLiteral value: String) {
            self.rawValue = value
        }
        
        public init(from decoder: Decoder) throws {
            try self.init(rawValue: .init(from: decoder))
        }
        
        public func encode(to encoder: Encoder) throws {
            try rawValue.encode(to: encoder)
        }
    }
    
    public struct LogEntry: Hashable {
        public let sourceCodeLocation: SourceCodeLocation?
        public let timestamp: Date
        public let scope: PassthroughLoggerScope
        public let level: LogLevel
        public let message: LogMessage
    }
    
    public struct Source: CustomStringConvertible {
        public enum Content {
            case sourceCodeLocation(SourceCodeLocation)
            case logger(any LoggerProtocol, scope: AnyLogScope?)
            case something(Any)
            case object(Weak<AnyObject>)
        }
        
        private let content: Content
        
        public var description: String {
            switch content {
                case .sourceCodeLocation(let location):
                    return location.description
                case .logger(let logger, let scope):
                    if let logger = logger as? _PassthroughLogger {
                        guard let scope else {
                            assertionFailure()
                            
                            return String(describing: logger)
                        }
                        
                        return "\(logger.source.description): \(scope.description)"
                    } else {
                        assertionFailure()
                        
                        return String(describing: logger)
                    }
                case .something(let value):
                    return String(describing: value)
                case .object(let object):
                    if let object = object.wrappedValue {
                        return String(describing: object)
                    } else {
                        return "(null)"
                    }
            }
        }
        
        private init(content: Content) {
            if content is any LoggerProtocol {
                assertionFailure()
            }

            self.content = content
        }
        
        public static func location(_ location: SourceCodeLocation) -> Self {
            Self(content: .sourceCodeLocation(location))
        }
        
        public static func logger(
            _ logger: any LoggerProtocol,
            scope: AnyLogScope
        ) -> Self {
            Self(content: .logger(logger, scope: scope))
        }
        
        public static func object(_ object: AnyObject) -> Self {
            if object is any LoggerProtocol {
                assertionFailure()
            }
            
            return Self(content: .object(Weak(wrappedValue: object)))
        }
        
        public static func something(_ thing: Any) -> Self {
            if swift_isClassType(type(of: thing)) {
                return .object(thing as AnyObject)
            } else {
                return .init(content: .something(thing))
            }
        }
    }
    
    public struct Configuration {
        @TaskLocal static var global = Self()
        
        public var dumpToConsole: Bool
        
        public init(dumpToConsole: Bool = _isDebugAssertConfiguration) {
            self.dumpToConsole = dumpToConsole
        }
    }
}
