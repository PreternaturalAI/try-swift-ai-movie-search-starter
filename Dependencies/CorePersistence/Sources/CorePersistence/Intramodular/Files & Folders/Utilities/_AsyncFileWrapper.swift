//
// Copyright (c) Vatsal Manot
//

import Foundation
import Merge
import Swallow

public final class _AsyncFileWrapper {
    private let lock = OSUnfairLock()
    public var base: FileWrapper
    
    public var isDirectory: Bool {
        get {
            lock.withCriticalScope {
                base.isDirectory
            }
        }
    }
    
    public var preferredFileName: String? {
        get {
            lock.withCriticalScope {
                base.preferredFilename
            }
        } set {
            lock.withCriticalScope {
                base.preferredFilename = newValue
            }
        }
    }
    
    public var fileWrappers: [String: _AsyncFileWrapper]? {
        get {
            lock.withCriticalScope {
                base.fileWrappers?.mapValues {
                    .init($0)
                }
            }
        }
    }
    
    public init(_ wrapper: FileWrapper) {
        self.base = wrapper
    }
    
    public var regularFileContents: Data? {
        lock.withCriticalScope {
            base.regularFileContents
        }
    }
    
    public func addFileWrapper(_ wrapper: _AsyncFileWrapper) {
        lock.withCriticalScope {
            base.addFileWrapper(wrapper.base)
        }
    }
    
    public func contains(_ wrapper: _AsyncFileWrapper) -> Bool {
        lock.withCriticalScope {
            base.fileWrappers?.contains(where: { $0.value == wrapper.base }) == true
        }
    }
    
    public func removeFileWrapper(_ wrapper: _AsyncFileWrapper) {
        assert(contains(wrapper)) // TODO: Investigate
        
        lock.withCriticalScope {
            base.removeFileWrapper(wrapper.base)
        }
    }
    
    public func write(
        to url: URL,
        options: FileWrapper.WritingOptions,
        originalContentsURL: URL?
    ) throws {
        try lock.withCriticalScope {
            try base.write(to: url, options: options, originalContentsURL: originalContentsURL)
        }
    }
    
    public init(url: URL, options: FileWrapper.ReadingOptions = []) throws {
        self.base = try .init(url: url, options: options)
    }
    
    public init(directoryWithFileWrappers childrenByPreferredName: [String: FileWrapper]) {
        self.base = .init(directoryWithFileWrappers: childrenByPreferredName)
    }
    
    public init(regularFileWithContents contents: Data) {
        self.base = .init(regularFileWithContents: contents)
    }
}

extension _AsyncFileWrapper: Equatable {
    public static func == (lhs: _AsyncFileWrapper, rhs: _AsyncFileWrapper) -> Bool {
        lhs.base === rhs.base
    }
    
    public static func === (lhs: _AsyncFileWrapper, rhs: _AsyncFileWrapper) -> Bool {
        fatalError()
    }
    
    public static func !== (lhs: _AsyncFileWrapper, rhs: _AsyncFileWrapper) -> Bool {
        fatalError()
    }
}

extension _AsyncFileWrapper {
    public convenience init(
        regularFileWithContents contents: Data,
        preferredFileName: String
    ) {
        self.init(regularFileWithContents: contents)
        
        self.preferredFileName = preferredFileName
    }
    
    public func firstAndOnlyChildWrapper() throws -> _AsyncFileWrapper {
        try lock.withCriticalScope {
            try .init(base.firstAndOnlyChildWrapper())
        }
    }
    
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func fileWrapper(
        at path: [String],
        directoryHint: URL.DirectoryHint
    ) throws -> FileWrapper {
        try lock.withCriticalScope {
            try base.fileWrapper(at: path, directoryHint: directoryHint)
        }
    }
    
    public func removeAllFileWrappers() {
        lock.withCriticalScope {
            base.removeAllFileWrappers()
        }
    }
}
