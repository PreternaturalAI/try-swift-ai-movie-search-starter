//
// Copyright (c) Preternatural AI, Inc.
//

import SwiftUI
import SwiftData

@main
struct App: SwiftUI.App {
    
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MovieItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        let modelContainer = self.sharedModelContainer
        
        Task.detached(priority: .high) {
            await Self.load(container: modelContainer)
        }
    }
    
    static func load(container: ModelContainer) async {
        await CSVDataManager(modelContainer: container).parseCSV()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
