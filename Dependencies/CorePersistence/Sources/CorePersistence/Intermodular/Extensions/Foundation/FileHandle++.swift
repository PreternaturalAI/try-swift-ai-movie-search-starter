//
// Copyright (c) Vatsal Manot
//

import Foundation
import POSIX
import Swallow

extension FileHandle {
    public func seekToStartOfFile() {
        seek(toFileOffset: 0)
    }
    
    public func seekingToStartOfFile() -> FileHandle {
        return build(self, with: { $0.seekToStartOfFile() })
    }
    
    public func write(truncatingTo data: Data) {
        write(data)
        
        let offsetInFile = self.offsetInFile
        
        if offsetInFile < seekToEndOfFile() {
            truncateFile(atOffset: offsetInFile)
        }
    }
}
