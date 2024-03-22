//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swift
import System

public protocol FileLocationInitiable {
    init(_: BookmarkedURL)
}

extension FileLocationInitiable {
    public init?(url: URL) {
        guard let location = BookmarkedURL(url: url) else {
            return nil
        }
        
        self.init(location)
    }
}
