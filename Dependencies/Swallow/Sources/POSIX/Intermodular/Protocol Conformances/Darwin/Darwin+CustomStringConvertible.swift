//
// Copyright (c) Vatsal Manot
//

import Darwin
import Swallow

extension MachErrorCode: CustomStringConvertible {
    public var description: String {
        return .init(utf8String: mach_error_string(rawValue))
    }
    
    public var descriptionOfType: String {
        return .init(utf8String: mach_error_type(rawValue))
    }
}

extension POSIXErrorCode: CustomStringConvertible {
    public var description: String {
        return .init(utf8String: strerror(rawValue))
    }
}
