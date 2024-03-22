//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public struct _GenericRecordMetadata: Codable, Hashable, Sendable {
    public enum TimestampKind: String, Codable, Hashable, Sendable {
        case creation
        case insertion
        case modification
        case access
        case publication
        case deletion
        case archival
    }
    
    @LossyCoding
    public var timestamps: [TimestampKind: Date] = [:]
    @LossyCoding
    public var isTombstoned: Bool? = false
}
