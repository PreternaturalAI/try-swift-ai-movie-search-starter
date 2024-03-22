//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow
import System

public final class _DirectoryEventsPublisher: Cancellable, ConnectablePublisher {
    public typealias Output = Void
    public typealias Failure = Error

    public let url: URL
    public let filePath: FilePath
    
    private let queue = DispatchQueue.global(qos: .utility)
    private let eventsPublisher = PassthroughSubject<Void, Error>()
    private var fileDescriptor: FileDescriptor?
    private var source: DispatchSourceProtocol?
    private var lastContentsSnapshot: Set<URL>?
    
    init(url: URL) throws {
        self.url = url
        self.filePath = try FilePath(url: url).unwrap()
        
        refreshSnapshot()
    }
    
    public func start() throws {
        guard fileDescriptor == nil || source == nil else {
            assert(fileDescriptor == nil && source == nil)
            
            return
        }
        
        let fileDescriptor = try FileDescriptor.open(filePath, .init(rawValue: O_EVTONLY))
        
        self.fileDescriptor = fileDescriptor
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor.rawValue,
            eventMask: .write,
            queue: queue
        )
        
        self.source = source
        
        source.setEventHandler { [weak self] in
            guard let `self` = self else {
                return 
            }
            
            guard self.contentsAreDirty() else {
                return
            }
             
            self.eventsPublisher.send(())
        }
        
        source.setCancelHandler { [weak self] in
            self?.cancel()
        }
        
        source.resume()
    }
    
    public func cancel()  {
        guard let source, let fileDescriptor else {
            return
        }
        
        self.source = nil
        self.fileDescriptor = nil
        
        do {
            source.cancel()
            
            try fileDescriptor.close()
            
            self.eventsPublisher.send(completion: .finished)
        } catch {
            assertionFailure()
            
            self.eventsPublisher.send(completion: .failure(error))
        }
    }
    
    private func refreshSnapshot() {
        do {
            lastContentsSnapshot = try Set(FileManager.default.contentsOfDirectory(at: url))
        } catch {
            lastContentsSnapshot = nil
            
            assertionFailure(error)
        }
    }
    
    private func contentsAreDirty() -> Bool {
        let lastSnapshot = lastContentsSnapshot
        
        refreshSnapshot()
        
        return lastSnapshot != self.lastContentsSnapshot
    }

    public func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Void, S.Failure == Error {
        eventsPublisher.receive(subscriber: subscriber)
    }
    
    public func connect() -> Cancellable {
        do {
            _ = try start()
        } catch {
            eventsPublisher.send(completion: .failure(error))
        }
        
        return self
    }
}

