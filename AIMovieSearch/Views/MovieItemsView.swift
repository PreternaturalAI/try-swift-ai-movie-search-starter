//
// Copyright (c) Preternatural AI, Inc.
//

import SwiftUI
import SwiftData

struct MovieItemsView: View {
    @Query private var movieItems: [MovieItem]
    @State var movieItemsShuffled: [MovieItem] = []
    
    var body: some View {
        ScrollView() {
            LazyVGrid(alignment: .leading, minWidth: 300) {
                ForEach(movieItemsShuffled) { movie in
                    MovieItemView(movie: movie)
                }
            }
        }
        ._onAppearAndChange(of: movieItems) {
            movieItemsShuffled = $0.shuffled()
        }
        .background(AppColors.backgroundColor)
    }
}
