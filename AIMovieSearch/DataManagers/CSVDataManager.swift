//
// Copyright (c) Preternatural AI, Inc.
//

import CorePersistence
import SwiftData
import LargeLanguageModels

actor CSVDataManager: ModelActor {
    let modelContainer: ModelContainer
    let modelExecutor: any ModelExecutor


    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        let context = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    }
    
    let decoder = CSVDecoder()
    let csvPath = Bundle.main.path(forResource: "movieData", ofType: "csv")
    
    func parseCSV() async {
        do {
            guard let csvPath = csvPath else {
                return
            }
            let url = URL(fileURLWithPath: csvPath)
            let movieDataItems = try await decodeFileForURL(url)
            try await addMovieItemsModelContext(items: movieDataItems)
        }
        catch {
            runtimeIssue(error)
        }
    }
    
    private func decodeFileForURL(_ url: URL) async throws -> [MovieDataItem] {
        var movieDataItems: [MovieDataItem] = []
        do {
            let data = try decoder.decode(
                [MovieDataItem].self,
                from: CSV(data: Data(contentsOf: url), using: .init(encoding: .utf8, hasHeaderRow: true))
            )
            movieDataItems = data
        }
        catch {
            runtimeIssue(error)
        }
        return movieDataItems
    }
    
    private func addMovieItemsModelContext(items: [MovieDataItem]) async throws {
        do {
            for item in items {
                let fetchDescriptor = FetchDescriptor(predicate: #Predicate<MovieItem> { movie in
                    movie.title == item.title
                })
                
                if (try? modelContext.fetch(fetchDescriptor).first) != nil {
                    continue
                }
                
                let movieItem = MovieItem(movieData: item)
                modelContext.insert(movieItem)
            }
            try modelContext.save()
        } catch {
            runtimeIssue(error)
        }
    }
}
