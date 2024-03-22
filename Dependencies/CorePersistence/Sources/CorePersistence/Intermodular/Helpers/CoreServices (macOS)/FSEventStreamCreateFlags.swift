//
// Copyright (c) Vatsal Manot
//

#if os(macOS)
import CoreServices
#else
import MobileCoreServices
#endif

import Foundation
import Swallow

public struct FSEventStreamCreateFlags: RawRepresentable {
    public typealias RawValue = Int

    public let rawValue: RawValue

    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

// MARK: - Conformances

extension FSEventStreamCreateFlags: CustomStringConvertibleOptionSet {
    #if os(macOS)

    public static let none = FSEventStreamCreateFlags(rawValue: kFSEventStreamCreateFlagNone)
    public static let useCFTypes = FSEventStreamCreateFlags(rawValue: kFSEventStreamCreateFlagUseCFTypes)
    public static let flagNoDefer = FSEventStreamCreateFlags(rawValue: kFSEventStreamCreateFlagNoDefer)
    public static let watchRoot = FSEventStreamCreateFlags(rawValue: kFSEventStreamCreateFlagWatchRoot)
    public static let ignoreSelf = FSEventStreamCreateFlags(rawValue: kFSEventStreamCreateFlagIgnoreSelf)
    public static let fileEvents = FSEventStreamCreateFlags(rawValue: kFSEventStreamCreateFlagFileEvents)
    public static let markSelf = FSEventStreamCreateFlags(rawValue: kFSEventStreamCreateFlagMarkSelf)

    public static let descriptions: [FSEventStreamCreateFlags: String] =
        [
            .none: " none",
            .useCFTypes: "useCFTypes",
            .flagNoDefer: "flagNoDefer",
            .watchRoot: "watchRoot",
            .ignoreSelf: "ignoreSelf",
            .fileEvents: "fileEvents",
            .markSelf: "markSelf"
    ]

    #else

    public static let descriptions: [FSEventStreamCreateFlags: String] = [:]

    #endif
}

extension FSEventStreamCreateFlags: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
