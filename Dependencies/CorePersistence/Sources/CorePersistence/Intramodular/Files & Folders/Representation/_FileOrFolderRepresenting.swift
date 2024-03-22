//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow
import System

/// A type that represents a file or folder.
public protocol _FileOrFolderRepresenting: Identifiable {
    associatedtype Child: _FileOrFolderRepresenting = FileURL
    
    func _toURL() throws -> URL
    
    func decode(using coder: _AnyConfiguredFileCoder) throws -> Any?
    
    mutating func encode<T>(_ contents: T, using coder: _AnyConfiguredFileCoder) throws
    
    func child(at path: String) throws -> Child
    
    @_spi(Internal)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func streamChildren() throws -> AsyncThrowingStream<AnyAsyncSequence<Child>, Error>
}

extension _FileOrFolderRepresenting {
    @_spi(Internal)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func _opaque_streamChildren() throws -> AsyncThrowingStream<AnyAsyncSequence<any _FileOrFolderRepresenting>, Error> {
        try streamChildren().map { sequence in
            sequence
                .map {
                    $0 as (any _FileOrFolderRepresenting)
                }
                .eraseToAnyAsyncSequence()
        }
    }
}

extension _FileOrFolderRepresenting {
    public func _toURL() throws -> URL {
        throw Never.Reason.unimplemented
    }
    
    public func decode(
        using coder: _AnyConfiguredFileCoder
    ) throws -> Any? {
        throw Never.Reason.unimplemented
    }
    
    public func decode<T>(
        _ type: T.Type,
        using coder: _AnyConfiguredFileCoder
    ) throws -> T? {
        guard let contents = try self.decode(using: coder) else {
            return nil
        }
        
        return try cast(contents, to: T.self)
    }
    
    @_spi(Internal)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func streamChildren() throws -> AsyncThrowingStream<AnyAsyncSequence<Child>, Error> {
        throw Never.Reason.unimplemented
    }
    
    public func child(
        at path: String
    ) throws -> Child {
        throw Never.Reason.unimplemented
    }
}

public struct FileURL: _FileOrFolderRepresenting {
    public typealias Child = Self
    
    public let base: URL
    
    public var id: AnyHashable {
        base
    }
    
    init(base: URL) {
        self.base = base
    }
    
    public init(_ url: URL) {
        self.init(base: url)
    }
    
    public func _toURL() throws -> URL {
        base
    }
    
    public func decode(
        using coder: _AnyConfiguredFileCoder
    ) throws -> Any? {
        try FileManager.default._decode(from: base, coder: coder)
    }
    
    public func encode<T>(
        _ contents: T,
        using coder: _AnyConfiguredFileCoder
    ) throws {
        try FileManager.default._encode(contents, to: base, coder: coder)
    }
    
    @_spi(Internal)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func streamChildren() throws -> AsyncThrowingStream<AnyAsyncSequence<Child>, Error> {
        try _DirectoryEventsPublisher(url: base)
            .autoconnect()
            .prepend(())
            .values
            .eraseToThrowingStream()
            .map {
                AnyAsyncSequence {
                    _AsyncDirectoryIterator(directoryURL: base)
                }
                .map {
                    FileURL(base: $0)
                }
                .eraseToAnyAsyncSequence()
            }
            .eraseToThrowingStream()
    }
    
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func child(at path: String) -> Self {
        .init(base: base.appending(path: path))
    }
}

// MARK: - Implemented Conformances

public struct DeferredURL {
    
}
