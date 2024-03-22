//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Foundation
import Merge
import Swallow
import SwiftData

class _FileBundleBackingObject: _FileBundleContainerElement {
    var fileWrapper: _AsyncFileWrapper? = nil
    
    public var knownFileURL: URL? {
        get throws {
            fatalError(.abstract)
        }
    }
    
    fileprivate init(fileWrapper: _AsyncFileWrapper?) {
        self.fileWrapper = fileWrapper
    }
    
    func childDidUpdate(_ node: _FileBundleChild) {
        fatalError(.abstract)
    }
}

extension _FileBundleBackingObject: _FileOrFolderRepresenting {
    public func _toURL() throws -> URL {
        try knownFileURL.unwrap()
    }
    
    public func decode(using coder: _AnyConfiguredFileCoder) throws -> Any? {
        throw Never.Reason.illegal
    }
    
    public func encode<T>(
        _ contents: T,
        using coder: _AnyConfiguredFileCoder
    ) throws {
        throw Never.Reason.illegal
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension _FileBundleBackingObject {
    final class Root: _FileBundleBackingObject {
        private let objectWillChangeRelay = ObjectWillChangePublisherRelay()
        private let directory: FileURL
        private let writeScheduler = DispatchQueue(qos: .userInitiated)._debounce(for: .milliseconds(50))
        
        public override var knownFileURL: URL? {
            get throws {
                try directory._toURL()
            }
        }
        
        init(
            _enclosingInstance: any FileBundle,
            directory: FileURL,
            readOptions: Set<FileDocumentReadOption>
        ) throws {
            let url = try directory._toURL()
            
            if readOptions.contains(.createIfNeeded) {
                if !FileManager.default.fileExists(at: url) {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                }
            }
            
            guard FileManager.default.isDirectory(at: url) else {
                throw CocoaError(.formatting)
            }
            
            self.directory = directory
            
            try super.init(fileWrapper: .init(url: url))
            
            objectWillChangeRelay.source = self
            objectWillChangeRelay.destination = _enclosingInstance
        }
        
        override func childDidUpdate(_ node: _FileBundleChild) {
            Task { @MainActor in
                objectWillChange.send()
            }
            
            writeScheduler.schedule {
                _expectNoThrow {
                    try self.fileWrapper.unwrap().write(
                        to: self.directory.base,
                        options: [
                            .atomic,
                            .withNameUpdating
                        ],
                        originalContentsURL: self.directory.base
                    )
                }
            }
        }
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension _FileBundleBackingObject {
    final class KeyedChild: _FileBundleBackingObject, _FileBundleChild {
        private let objectWillChangeRelay = ObjectWillChangePublisherRelay()
        
        private weak var owner: (any _FileBundleContainerElement)?
        
        public override var knownFileURL: URL? {
            get throws {
                try owner?.knownFileURL
            }
        }
        
        init(
            _enclosingInstance: any FileBundle,
            owner: (any _FileBundleContainerElement)?,
            fileWrapper: _AsyncFileWrapper
        ) throws {
            self.owner = owner
            
            super.init(fileWrapper: fileWrapper)
            
            objectWillChangeRelay.source = self
            objectWillChangeRelay.destination = _enclosingInstance
        }
        
        func refresh() throws {
            
        }
        
        override func childDidUpdate(_ node: _FileBundleChild) {
            Task { @MainActor in
                objectWillChange.send()
            }
            
            owner?.childDidUpdate(self)
        }
    }
}
