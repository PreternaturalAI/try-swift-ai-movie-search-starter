//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct CSVColumnHeader: Codable {
    public var index: Int
    public var name: String?
    
    public init(index: Int, name: String? = nil) {
        self.index = index
        self.name = name?.removingBOMCharacter()
    }
}

// MARK: - Conformances

extension CSVColumnHeader: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.index <= rhs.index
    }
}

extension CSVColumnHeader: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.index == rhs.index
    }
}

extension CSVColumnHeader: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(index)
    }
}
