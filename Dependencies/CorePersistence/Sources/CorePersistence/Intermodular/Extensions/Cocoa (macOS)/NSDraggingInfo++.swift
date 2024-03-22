//
// Copyright (c) Vatsal Manot
//

#if canImport(Cocoa) && !canImport(UIKit)

import Cocoa
import Foundation
import Swallow

extension NSDraggingInfo {
    public func pathsFromDraggingPasteboard() -> [URL]? {
        let pasteboard = draggingPasteboard
        
        guard pasteboard.types?.contains(NSPasteboard.PasteboardType.fileURL) ?? false else {
            return nil
        }
        
        guard let objects = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) else {
            return nil
        }
        
        return try? cast(objects, to: Array<URL>.self)
    }
}

#endif
