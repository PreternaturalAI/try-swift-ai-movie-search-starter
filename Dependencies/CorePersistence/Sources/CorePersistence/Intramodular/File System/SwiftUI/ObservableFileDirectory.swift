//
// Copyright (c) Vatsal Manot
//

import Dispatch
import Merge
import System
import Swift

public final class ObservableFileDirectory: Logging, ObservableObject {
    let url: URL
    
    var fileSource: DispatchSourceFileSystemObject?
    
    @Published private var directoryDescriptor: FileDescriptor?
    @Published private var directorySource: DispatchSourceFileSystemObject?
    
    @Published private(set) var children: [URL]?
    
    public init(url: URL) {
        self.url = url
        
        Task { @MainActor in
            populateChildren()
            
            do {
                try self.beginObserving()
            } catch {
                logger.error(error)
            }
        }
    }
    
    @MainActor
    private func beginObserving() throws {
        try stopObserving()
        
        let directoryDescriptor = try FileDescriptor.open(FilePath(fileURL: url), .readOnly, options: .eventOnly)
        let directorySource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: directoryDescriptor.rawValue, eventMask: .all, queue: DispatchQueue.global(qos: .userInitiated))
        
        directorySource.setEventHandler { [weak self] in
            guard let `self` = self else {
                return
            }
                        
            Task { @MainActor in
                self.objectWillChange.send()

                self.populateChildren()
            }
        }
        
        directorySource.resume()
        
        self.directoryDescriptor = directoryDescriptor
        self.directorySource = directorySource
    }
    
    @MainActor
    private func stopObserving() throws {
        guard directoryDescriptor != nil else {
            assert(directorySource == nil)
            
            return
        }
        
        try directoryDescriptor?.closeAfter {
            directorySource?.cancel()
        }
    }
    
    @MainActor
    private func populateChildren() {
        do {
            children = try FileManager.default.suburls(at: self.url)
        } catch {
            logger.error(error)
            
            children = []
        }
    }
}
