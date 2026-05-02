import SwiftUI
import SwiftData

@main
struct KQBookkeepingApp: App {
    @State private var refreshManager = PriceRefreshManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Asset.self,
            Transaction.self,
            AssetPriceSnapshot.self,
            ExchangeRateSnapshot.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(refreshManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
