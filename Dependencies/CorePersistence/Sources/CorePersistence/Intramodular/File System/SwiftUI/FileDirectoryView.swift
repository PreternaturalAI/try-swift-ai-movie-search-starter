//
// Copyright (c) Vatsal Manot
//

#if canImport(SwiftUI) && (os(iOS) || targetEnvironment(macCatalyst))

import FoundationX
import Swift
import SwiftUI
import System

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@available(iOS 14.0, *)
public struct FileDirectoryView: FileLocationInitiable, View {
    public let location: BookmarkedURL
    
    @StateObject var fileDirectory: ObservableFileDirectory
    
    public init(_ location: BookmarkedURL) {
        self.location = location
        self._fileDirectory = .init(wrappedValue: ObservableFileDirectory(url: location.url))
    }
    
    public init(_ location: CanonicalFileDirectory) {
        self.init(try! BookmarkedURL(url: location.toURL()).unwrap())
    }
    
    @ViewBuilder
    public var body: some View {
        ZStack {
            if let children = fileDirectory.children, !children.isEmpty {
                List {
                    OutlineGroup(
                        children.compactMap(BookmarkedURL.init(url:)),
                        children: \.children,
                        content: FileItemRowView.init
                    )
                }
                .listStyle(InsetGroupedListStyle())
            } else {
                Text("No Files")
                    .font(.title)
                    .foregroundColor(.secondary)
                    .fixedSize()
                    .padding(.bottom)
            }
        }
        .navigationTitle(Text(location.path.lastComponent))
        .id(location)
    }
}

extension BookmarkedURL {
    fileprivate var children: [BookmarkedURL]? {
        let result = try? FileManager.default
            .suburls(at: url)
            .map(BookmarkedURL.init(_unsafe:))
            .filter({ $0.path.exists })
        
        return (result ?? []).isEmpty ? nil : result
    }
}

#endif
