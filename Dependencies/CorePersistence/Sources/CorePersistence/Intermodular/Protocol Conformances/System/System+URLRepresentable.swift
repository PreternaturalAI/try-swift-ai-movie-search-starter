//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swift
import System

extension FilePath: URLRepresentable {
    public var url: URL {
        get {
            URL(fileURLWithPath: standardized.stringValue)
        } set {
            self = .init(newValue.path)
        }
    }
    
    public init?(url: URL) {
        guard url.isFileURL else {
            return nil
        }
        
        self.init(url.path)
    }
    
    public init(fileURL url: URL) {
        self.init(url: url)!
    }
}
