//
// Copyright (c) Vatsal Manot
//

import Swift

public protocol StringEncodingType {
    static var encodingTypeValue: String.Encoding { get }
}

// MAKR: - Conformances -

extension UTF8: StringEncodingType {
    public static let encodingTypeValue = String.Encoding.utf8
}

extension UTF16: StringEncodingType {
    public static let encodingTypeValue = String.Encoding.utf16
}

extension UTF32: StringEncodingType {
    public static let encodingTypeValue = String.Encoding.utf32
}
