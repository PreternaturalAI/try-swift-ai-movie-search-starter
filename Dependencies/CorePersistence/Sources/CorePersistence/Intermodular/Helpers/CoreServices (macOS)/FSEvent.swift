//
// Copyright (c) Vatsal Manot
//

#if os(macOS)
import CoreServices
#endif

import Foundation
import Swallow
import System

public struct FSEvent {
    #if os(macOS)
    public static let allEventID = 0
    public static let nowEventID = FSEventStreamEventId(kFSEventStreamEventIdSinceNow)
    public var id: FSEventStreamEventId
    #endif
    
    public var path: FilePath
    public var flags: Flags
}
