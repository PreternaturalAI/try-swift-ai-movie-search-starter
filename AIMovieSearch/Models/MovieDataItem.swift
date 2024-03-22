//
// Copyright (c) Preternatural AI, Inc.
//

import Foundation

public struct MovieDataItem: Codable, Hashable, Sendable {
    
    public enum CodingKeys: String, CodingKey {
        case title = "Series_Title"
        case titleProcessed = "Processed_Title"
        case releaseYear = "Released_Year"
        case posterLinkSmall = "Poster_Link"
        case posterLinkLarge = "Poster_Link_Large"
        case plotIMBDShort = "Overview"
        case plotWikiLong = "Wiki_Plot"
        case certificate = "Certificate"
        case runtime = "Runtime"
        case genre = "Genre"
        case imbdRating = "IMDB_Rating"
        case metaScore = "Meta_score"
        case director = "Director"
    }
    
    public let title: String
    public let titleProcessed: String
    public let releaseYear: String
    public let posterLinkSmall: String
    public let posterLinkLarge: String
    public let plotIMBDShort: String
    public let plotWikiLong: String?
    public let certificate: String
    public let runtime: String
    public let genre: String
    public let imbdRating: String
    public let metaScore: String
    public let director: String
    
    public static func == (lhs: MovieDataItem, rhs: MovieDataItem) -> Bool {
        let result = lhs.title.compare(rhs.title) == .orderedSame
        return result
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(UUID())
    }
}
