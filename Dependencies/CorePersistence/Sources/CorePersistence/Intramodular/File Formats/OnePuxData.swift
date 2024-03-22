//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Combine
import Swallow

public struct OnePuxItemDetailsLoginField: Codable, Hashable {
    let value: String
    let id: String
    let name: String
    let fieldType: String
    let designation: String?
}

public struct OnePuxItemDetailsSectionField: Codable, Hashable {
    let title: String
    let id: String
    let value: [String: String?]
    let indexAtSource: Int
    let guarded: Bool
    let multiline: Bool
    let dontGenerate: Bool
    let inputTraits: [String: String]
}

public struct OnePuxItemDetailsSection: Codable, Hashable {
    let title: String
    let name: String
    let fields: [OnePuxItemDetailsSectionField]
}

public struct OnePuxItemDetailsPasswordHistory: Codable, Hashable {
    let value: String
    let time: Int
}

public struct OnePuxItemOverviewUrl: Codable, Hashable {
    let label: String
    let url: String
}

public struct OnePuxItemDetails: Codable, Hashable {
    let loginFields: [OnePuxItemDetailsLoginField]
    let notesPlain: String?
    let sections: [OnePuxItemDetailsSection]
    let passwordHistory: [OnePuxItemDetailsPasswordHistory]
    let documentAttributes: [String: AnyCodable]?
}

public struct OnePuxItemOverview: Codable, Hashable {
    let subtitle: String
    let urls: [OnePuxItemOverviewUrl]?
    let title: String
    let url: String
    let ps: Int?
    let pbe: Int?
    let pgrng: Bool?
    let tags: [String]?
}

public struct OnePuxItem: Codable, Hashable {
    let item: OnePuxItemData?
    let file: [String: AnyCodable]?
}

public struct OnePuxItemData: Codable, Hashable {
    let uuid: String
    let favIndex: Int
    let createdAt: Int
    let updatedAt: Int
    let trashed: Bool
    let categoryUuid: String
    let details: OnePuxItemDetails
    let overview: OnePuxItemOverview
}

public struct OnePuxVault: Codable, Hashable {
    let attrs: [String: AnyCodable]
    let items: [OnePuxItem]
}

public struct OnePuxAccount: Codable, Hashable {
    let attrs: [String: AnyCodable]
    let vaults: [OnePuxVault]
}

public struct OnePuxData: Codable, Hashable {
    let accounts: [OnePuxAccount]
}

public struct OnePuxAttributes: Codable, Hashable {
    let version: Int
    let description: String
    let createdAt: Int
}

public struct OnePuxExport: Codable, Hashable {
    public let attributes: OnePuxAttributes
    public let data: OnePuxData
}
