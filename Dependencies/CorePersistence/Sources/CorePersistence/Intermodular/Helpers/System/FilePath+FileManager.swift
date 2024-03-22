//
// Copyright (c) Vatsal Manot
//

import Darwin
import Foundation
import Swallow
import System

extension FilePath {
    public static var directorySeparator: String {
        return "/"
    }
    
    public static var root: FilePath {
        .init(directorySeparator)
    }
    
    public static var currentDirectory: FilePath {
        get {
            .init(FileManager.default.currentDirectoryPath)
        } set {
            FileManager.default.changeCurrentDirectoryPath(newValue.stringValue)
        }
    }
    
    public var exists: Bool {
        FileManager.default.fileExists(atPath: stringValue)
    }
}

extension FilePath {
    public static func paths(
        inDomains directory: FileManager.SearchPathDirectory,
        mask: FileManager.SearchPathDomainMask
    ) -> [FilePath] {
        NSSearchPathForDirectoriesInDomains(directory, mask, true).map({ FilePath($0) })
    }
    
    public static func path(inUserDomain directory: FileManager.SearchPathDirectory) -> FilePath {
        paths(inDomains: directory, mask: .userDomainMask).first!
    }
    
    public static func path(inSystemDomain directory: FileManager.SearchPathDirectory) -> FilePath {
        paths(inDomains: directory, mask: .systemDomainMask).first!
    }
}

extension FilePath {
    public static func temporaryDirectory() -> Self {
        FilePath(url: URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true))!
    }
    
    #if os(macOS)
    public static var homeDirectoryForCurrentUser: Self! {
        FilePath(url: URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path))
    }
    
    public static var desktopDirectoryForCurrentUser: Self! {
        FilePath(url: URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path).appendingPathComponent("Desktop", isDirectory: true))
    }
    #endif
}
