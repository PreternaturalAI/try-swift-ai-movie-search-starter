//
// Copyright (c) Vatsal Manot
//

import Foundation
import POSIX
import Swift

extension Data {
    @_disfavoredOverload
    public init(
        memoryMapping descriptor: POSIXIOResourceDescriptor,
        count: Int
    ) throws {
        self.init(bytesNoCopy: .init(mutating: try descriptor.map(length: count, protection: [.read, .write]).baseAddress!), count: count, deallocator: .custom({ try! POSIXMemoryMap(.init(start: $0, count: $1)).unmap() }))
    }
    
    @_disfavoredOverload
    public init(
        memoryMapping descriptor: POSIXIOResourceDescriptor
    ) throws {
        try self.init(memoryMapping: descriptor, count: numericCast(try descriptor.getFileStatus().size))
    }
}
