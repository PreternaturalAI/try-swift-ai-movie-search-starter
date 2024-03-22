//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Merge
import Swallow

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct FolderStorageConfiguration<Item: Codable> {
    public enum Predicate: Hashable {
        case fileExtension(String)
        
        func evaluate(_ url: URL) -> Bool {
            switch self {
                case .fileExtension(let ext):
                    return url.pathExtension == ext
            }
        }
    }
    
    let directoryURL: URL
    let filter: (URL) -> Bool // FIXME: !!!
    let coder: TopLevelDataCoder
    
    func _makeAsyncStorageBase() throws -> _ConcreteFolderAsyncStorageBase<_AsyncFileResourceCoordinator<Item>> {
        try .init(
            directory: FileURL(directoryURL),
            resource: { file -> _AsyncFileResourceCoordinator<Item>? in
                if let url = (file as? FileURL)?.base {
                    if filter(url) {
                        return .init(
                            file: file,
                            coder: _AnyConfiguredFileCoder(.topLevelDataCoder(coder, forType: Item.self))
                        )
                    } else {
                        return nil
                    }
                } else {
                    return .init(
                        file: file,
                        coder: _AnyConfiguredFileCoder(.topLevelDataCoder(coder, forType: Item.self))
                    )
                }
            }
        )
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension AsyncStorage {
    public convenience init<Item: Codable, Coder: TopLevelDataCoder>(
        directory: URL,
        predicate: Set<FolderStorageConfiguration<Item>.Predicate>,
        coder: Coder
    ) where WrappedValue == [Item], ProjectedValue == [Item] {
        do {
            let configuration = FolderStorageConfiguration<Item>(
                directoryURL: directory,
                filter: { url in
                    !predicate.contains(where: { !$0.evaluate(url) })
                },
                coder: coder
            )
            
            try self.init(base: configuration._makeAsyncStorageBase())
        } catch {
            fatalError(error)
        }
    }
    
    public convenience init<Item: Codable, Coder: TopLevelDataCoder>(
        directory: CanonicalFileDirectory,
        predicate: Set<FolderStorageConfiguration<Item>.Predicate>,
        coder: Coder
    ) where WrappedValue == [Item], ProjectedValue == [Item] {
        self.init(
            directory: try! directory.toURL(),
            predicate: predicate,
            coder: coder
        )
    }
}
