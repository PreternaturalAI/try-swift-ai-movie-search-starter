//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

extension UUID {
    /// Losslessly convert a `UUIDv6` to a Foundation `UUID`.
    ///
    /// The bytes of the UUIDv6 are preserved exactly.
    /// Both random (v4) and time-ordered (v6) IDs are supported.
    ///
    @inlinable
    public init(_ uuid: UUIDv6) {
        self.init(uuid: uuid.bytes)
    }
}

extension UUIDv6 {
    /// Losslessly convert a Foundation `UUID` to a `UUIDv6`.
    ///
    /// The bytes of the Foundation UUID are preserved exactly.
    /// By default, Foundation generates random UUIDs (v4).
    ///
    @inlinable
    public init(_ uuid: Foundation.UUID) {
        self.init(bytes: uuid.uuid)
    }
}

// Note: 'Date' might move in to the standard library and increase precision to capture this timestamp exactly.
// https://forums.swift.org/t/pitch-clock-instant-date-and-duration/52451

extension UUIDv6.TimeOrdered {
    
    /// The timestamp of the UUID. Note that this has at most 100ns precision.
    ///
    /// ```swift
    /// let id = UUIDv6("1EC5FE44-E511-6910-BBFA-F7B18FB57436")!
    /// id.components(.timeOrdered)?.timestamp
    /// // ✅ "2021-12-18 09:24:31 +0000"
    /// ```
    ///
    @inlinable
    public var timestamp: Date {
        Date(timeIntervalSince1970: TimeInterval(_uuid_timestamp_to_unix(timestamp: rawTimestamp)) / 10_000_000)
    }
}
