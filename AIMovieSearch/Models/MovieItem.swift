//
// Copyright (c) Preternatural AI, Inc.
//

import Foundation
import SwiftData

@Model
final class MovieItem: Identifiable {
    @Attribute(.unique) public let id: UUID
    @Attribute(.unique) public let title: String
    public let titleProcessed: String
    public let releaseYear: Date?
    public let posterLinkSmall: URL?
    public let posterLinkLarge: URL?
    public let plotIMBDShort: String
    public let plotWikiLong: String?
    public let certificate: String
    public let runtime: Int?
    public let genre: String
    public let imbdRating: Double?
    public let metaScore: Double?
    public let director: String
    
    init(movieData: MovieDataItem) {
        let helper = MovieItemHelper()
        id = UUID()
        title = movieData.title
        titleProcessed = movieData.titleProcessed
        releaseYear = helper.convertToYear(movieData.releaseYear)
        posterLinkSmall = URL(string: movieData.posterLinkSmall)
        posterLinkLarge = URL(string: movieData.posterLinkLarge)
        plotIMBDShort = movieData.plotIMBDShort
        plotWikiLong = movieData.plotWikiLong
        certificate = movieData.certificate
        runtime = helper.convertToMinutes(movieData.runtime)
        genre = movieData.genre
        imbdRating = Double(movieData.imbdRating)
        metaScore = Double(movieData.metaScore)
        director = movieData.director
    }
}

extension MovieItem {
    
    var adjustedRating: Float? {
        guard let rating = imbdRating else { return nil }
        // change from 10 as max to 5 as max
        let newRating = (rating * 5) / 10
        return Float(newRating)
    }
    
    var adjustedRuntime: String? {
        guard let totalMinutes = runtime else {return nil}
        
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        let hourText = hours == 1 ? "hour" : "hours"
        let minuteText = minutes == 1 ? "minute" : "minutes"

        return "\(hours) \(hourText), \(minutes) \(minuteText)"
    }
}

struct MovieItemHelper {
    
    func convertToYear(_ yearString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter.date(from: yearString)
    }
    
    func convertToMinutes(_ minutesString: String) -> Int? {
        let minutes = minutesString.replacingOccurrences(of: " min", with: "")
        return Int(minutes)
    }
}
