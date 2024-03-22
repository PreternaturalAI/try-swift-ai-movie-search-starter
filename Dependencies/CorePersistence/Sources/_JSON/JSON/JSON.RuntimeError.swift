//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension JSON {
    public enum RuntimeError: Error {
        case noContainer
        case irrepresentableNumber(NSNumber)
        case noFallbackCovariantForSupertype(Any.Type)
        case stringEncodingError
        case unexpectedlyFoundNil(file: StaticString, function: StaticString, line: UInt)
        case isNotEmpty
    }
}
