//
// Copyright (c) Preternatural AI, Inc.
//

import SwiftUI
import StarRatingViewSwiftUI

struct MovieItemView: View {
    let movie: MovieItem
    
    var body: some View {
        LazyVStack(alignment: .leading) {
            Text(movie.title)
                .font(.largeTitle)
                .foregroundColor(AppColors.titleColor)
            
            MoviePosterView(url: movie.posterLinkLarge)
            
            Text(movie.plotIMBDShort)
                .font(.body)
                .foregroundColor(AppColors.plotSummaryColor)
            
            Text(movie.genre)
                .font(.body)
                .italic()
                .foregroundColor(AppColors.plotSummaryColor)
            
            if let runtime = movie.adjustedRuntime {
                Text(runtime)
                    .font(.body)
                    .bold()
                    .foregroundColor(AppColors.plotSummaryColor)
            }

            
            if let rating = movie.adjustedRating {
                HStack {
                    Text("IMBD: ")
                        .font(.body)
                        .foregroundColor(AppColors.titleColor)
                    StarRatingView(rating: Float(rating), color: Color.orange, maxRating: 5)
                }
            }
        }
        .padding()
    }
}
