//
// Copyright (c) Vatsal Manot
//

import Foundation
import System

extension FilePath {
    public var lastComponent: String {
        get {
            url.lastPathComponent
        } set {
            self.url = url.deletingLastPathComponent().appendingPathComponent(newValue)
        }
    }
    
    public var pathExtension: String {
        get {
            url.pathExtension
        } set {
            self.url = url.deletingPathExtension().appendingPathComponent(newValue)
        }
    }
}

extension FilePath {
    public var isAbsolute: Bool {
        return stringValue.hasPrefix(FilePath.directorySeparator)
    }
    
    public var isLiteralHardlinkToCurrent: Bool {
        return stringValue == "."
    }
    
    public var isLiteralHardlinkToParent: Bool {
        return stringValue == ".."
    }
    
    public var isEmptyOrLiteralHardlinkToCurrent: Bool {
        return stringValue.isEmpty || isLiteralHardlinkToCurrent
    }
}

extension FilePath {
    public var standardized: FilePath {
        return .init((stringValue as NSString).standardizingPath)
    }
    
    public var symlinksResolved: FilePath {
        return .init((stringValue as NSString).resolvingSymlinksInPath)
    }
}

extension FilePath {
    public static func + (lhs: Self, rhs: String) -> Self {
        FilePath(
            url: URL(_filePath: lhs)!.appendingPathComponent(
                String(
                    rhs.dropPrefixIfPresent("/")
                )
            )
        )!
    }
}
