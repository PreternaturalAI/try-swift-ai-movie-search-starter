//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swift
import System

#if os(macOS)
public class FSEventObserver: ObservableObject {
    public let objectWillChange = PassthroughSubject<FSEvent, Never>()
    
    private let paths: [FilePath]
    private let latency: CFTimeInterval
    private let queue: DispatchQueue?
    private let flags: FSEventStreamCreateFlags
    
    private var runLoop: CFRunLoop = CFRunLoopGetMain()
    private var stream: FSEventStream?
    
    public private(set) var lastEventId: FSEventStreamEventId
    public private(set) var isRunning = false
    
    public init(
        paths: [FilePath],
        sinceWhen: FSEventStreamEventId = FSEvent.nowEventID,
        flags: FSEventStreamCreateFlags = [.useCFTypes, .fileEvents],
        latency: CFTimeInterval = 0,
        queue: DispatchQueue? = nil
    ) {
        self.lastEventId = sinceWhen
        self.paths = paths
        self.flags = flags
        self.latency = latency
        self.queue = queue
    }
    
    public func start() {
        guard isRunning == false else {
            return
        }
        
        var context = FSEventStreamContext()
        
        context.info = Unmanaged.passUnretained(self).toOpaque()
        
        let callback: FSEventStreamCallback = {
            (stream: ConstFSEventStreamRef, contextInfo: UnsafeMutableRawPointer?, numEvents: Int, eventPaths: UnsafeMutableRawPointer, eventFlags: UnsafePointer<FSEventStreamEventFlags>, eventIds: UnsafePointer<FSEventStreamEventId>) in
            
            let observer = unsafeBitCast(contextInfo, to: FSEventObserver.self)
            
            defer {
                observer.lastEventId = eventIds[numEvents - 1]
            }
            
            guard let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else {
                return
            }
            
            for index in 0..<numEvents {
                let id = eventIds[index]
                let path = paths[index]
                let flags = eventFlags[index]
                
                observer.objectWillChange.send(FSEvent(id: id, path: .init(path), flags: .init(rawValue: Int(flags))))
            }
        }
        
        guard let streamRef = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            paths.map({ $0.stringValue }) as CFArray,
            lastEventId,
            latency,
            UInt32(flags.rawValue)
        ) else {
            return
        }
        
        stream = FSEventStream(rawValue: streamRef)
        stream?.schedule(with: .main, runLoopMode: .defaultMode)
        
        if let queue = queue {
            stream?.dispatchQueue = queue
        }
        
        stream?.start()
        
        isRunning = true
    }
    
    public func flush(synchronously: Bool) {
        stream?.flush(synchronously: synchronously)
    }
    
    public func close() {
        guard isRunning == true else {
            return
        }
        
        stream?.stop()
        stream?.invalidate()
        stream?.release()
        stream = nil
        
        isRunning = false
    }
    
    deinit {
        close()
    }
}
#endif
