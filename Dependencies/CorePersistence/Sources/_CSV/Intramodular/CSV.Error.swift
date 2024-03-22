//
// Copyright (c) Vatsal Manot
//

import Swift

extension CSV {
    public enum Error: Swift.Error {
        case cannotOpenFile
        case cannotReadFile
        case cannotWriteStream
        case streamErrorHasOccurred(error: Swift.Error)
        case unicodeDecoding
        case cannotReadHeaderRow
        case stringEncodingMismatch
        case stringEndianMismatch
    }
}
