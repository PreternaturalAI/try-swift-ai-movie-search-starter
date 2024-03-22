//
// Copyright (c) Vatsal Manot
//

#if canImport(SwiftUI) && (os(iOS) || targetEnvironment(macCatalyst))

import Foundation
import Swift
import SwiftUI
import System

public struct FileManagerView: View {
    @Environment(\.fileManager) var fileManager
    
    public let directories: [FileManager.SearchPathDirectory]
    public let domainMask: FileManager.SearchPathDomainMask
    
    private var locationGroups: [[BookmarkedURL]] {
        directories
            .flatMap { directory in
                FileManager.default
                    .urls(for: directory, in: .allDomainsMask)
                    .map(BookmarkedURL.init(_unsafe:))
                    .sorted(by: { $0.url.lastPathComponent < $1.url.lastPathComponent })
            }
            .group(by: { $0.url.lastPathComponent })
            .sorted(by: { $0.key < $1.key })
            .map({ $0.value })
    }
    
    public init(
        directories: [FileManager.SearchPathDirectory],
        domainMask: FileManager.SearchPathDomainMask
    ) {
        self.directories = directories
        self.domainMask = domainMask
    }
    
    public var body: some View {
        List(locationGroups, id: \.hashValue) { group in
            Group {
                if let root = group.first {
                    NavigationLink(destination: FileDirectoryView(root)) {
                        Label(
                            root.url.lastPathComponent,
                            systemImage: root.hasChildren ? "folder.fill" : "folder"
                        )
                    }
                }
            }
            .disabled(!group.isReachable)
        }
        .navigationBarTitle("Files")
    }
}

// MARK: - Auxiliary

@usableFromInline
struct FileManagerEnvironmentKey: EnvironmentKey {
    @usableFromInline
    static let defaultValue: FileManager = .default
}

extension EnvironmentValues {
    @inlinable
    public var fileManager: FileManager {
        get {
            self[FileManagerEnvironmentKey.self]
        } set {
            self[FileManagerEnvironmentKey.self] = newValue
        }
    }
}

#endif
