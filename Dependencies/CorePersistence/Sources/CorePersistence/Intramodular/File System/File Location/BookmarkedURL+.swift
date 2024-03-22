//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

extension BookmarkedURL {
    public var hasChildren: Bool {
        do {
            return try !FileManager.default
                .suburls(at: url)
                .map(BookmarkedURL.init(_unsafe:))
                .filter({ $0.path.exists })
                .isEmpty
        } catch {
            return false
        }
    }
    
    public var isEmpty: Bool {
        let result = try? FileManager.default
            .suburls(at: url)
            .map(BookmarkedURL.init(_unsafe:))
            .filter({ $0.path.exists })
        
        return result?.isEmpty ?? false
    }
}

extension Sequence where Element: FileLocationResolvable {
    public var isReachable: Bool {
        !contains(where: { !$0.isReachable })
    }
}
