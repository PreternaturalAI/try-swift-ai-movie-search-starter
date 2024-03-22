//
// Copyright (c) Vatsal Manot
//

#if os(macOS)
import CoreServices
#endif

import Foundation
import Swallow
import System

extension FSEvent {
    public struct Flags: Codable, Hashable, OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
}

// MARK: - Conformances

extension FSEvent.Flags: CustomStringConvertibleOptionSet {
    #if os(macOS)
    public static let none = with(rawValue: kFSEventStreamEventFlagNone)
    public static let mustScanSubDirs = with(rawValue: kFSEventStreamEventFlagMustScanSubDirs)
    public static let userDropped = with(rawValue: kFSEventStreamEventFlagUserDropped)
    public static let kernelDropped = with(rawValue: kFSEventStreamEventFlagKernelDropped)
    public static let eventIdsWrapped = with(rawValue: kFSEventStreamEventFlagEventIdsWrapped)
    public static let historyDone = with(rawValue: kFSEventStreamEventFlagHistoryDone)
    public static let rootChanged = with(rawValue: kFSEventStreamEventFlagRootChanged)
    public static let mount = with(rawValue: kFSEventStreamEventFlagMount)
    public static let unmount = with(rawValue: kFSEventStreamEventFlagUnmount)
    public static let created = with(rawValue: kFSEventStreamEventFlagItemCreated)
    public static let itemRemoved = with(rawValue: kFSEventStreamEventFlagItemRemoved)
    public static let itemInodeMetaMod = with(rawValue: kFSEventStreamEventFlagItemInodeMetaMod)
    public static let itemRenamed = with(rawValue: kFSEventStreamEventFlagItemRenamed)
    public static let itemModified = with(rawValue: kFSEventStreamEventFlagItemModified)
    public static let itemFinderInfoMod = with(rawValue: kFSEventStreamEventFlagItemFinderInfoMod)
    public static let itemChangeOwner = with(rawValue: kFSEventStreamEventFlagItemChangeOwner)
    public static let itemXattrMod = with(rawValue: kFSEventStreamEventFlagItemXattrMod)
    public static let itemIsFile = with(rawValue: kFSEventStreamEventFlagItemIsFile)
    public static let itemIsDir = with(rawValue: kFSEventStreamEventFlagItemIsDir)
    public static let itemIsSymlink = with(rawValue: kFSEventStreamEventFlagItemIsSymlink)
    public static let ownEvent = with(rawValue: kFSEventStreamEventFlagOwnEvent)
    public static let itemIsHardlink = with(rawValue: kFSEventStreamEventFlagItemIsHardlink)
    public static let itemIsLastHardlink = with(rawValue: kFSEventStreamEventFlagItemIsLastHardlink)
    
    public static var descriptions: [Self: String] = [
        .none: "none",
        .mustScanSubDirs: "must scan sub-directories",
        .userDropped: "user dropped",
        .kernelDropped: "kernel dropped",
        .eventIdsWrapped: "event IDs wrapped",
        .historyDone: "history done",
        .rootChanged: "root changed",
        .mount: "mount",
        .unmount: "unmount",
        .created: "created",
        .itemRemoved: "item removed",
        .itemInodeMetaMod: "item inode metadata modified",
        .itemRenamed: "item renamed",
        .itemModified: "item modified",
        .itemFinderInfoMod: "item finder info modified",
        .itemChangeOwner: "item owner changed",
        .itemXattrMod: "item exended-attributes modified",
        .itemIsFile: "item is file",
        .itemIsDir: "item is directory",
        .itemIsSymlink: "item is symlink",
        .ownEvent: "own even",
        .itemIsHardlink: "item is hardlink",
        .itemIsLastHardlink: "item is last hardlink"
    ]
    #else
    public static var descriptions: [Self: String] = [:]
    #endif
}
