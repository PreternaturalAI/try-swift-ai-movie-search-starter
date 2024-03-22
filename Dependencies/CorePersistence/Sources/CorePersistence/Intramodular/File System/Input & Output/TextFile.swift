//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

public class TextFile<Encoding: StringEncodingType, AccessMode: FileAccessModeType>: RegularFile<String, AccessMode> {
    
}

extension TextFile where AccessMode: FileAccessModeTypeForReading {
    public func data() throws -> String {
        return try data(using: .init(encoding: Encoding.encodingTypeValue))
    }
}

extension TextFile where AccessMode: FileAccessModeTypeForWriting {
    public func write(_ data: String) throws {
        try write(data, using: .init(encoding: Encoding.encodingTypeValue, allowLossyConversion: false))
    }
}

extension TextFile where AccessMode: FileAccessModeTypeForUpdating {
    public var unsafelyAccessedData: String {
        get {
            return try! data()
        } set {
            try! write(newValue)
        }
    }
}
