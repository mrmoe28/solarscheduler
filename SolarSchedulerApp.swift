import SwiftUI
import SwiftData

@main
struct SolarSchedulerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SolarJob.self,
            Customer.self,
            Equipment.self,
            Vendor.self,
            Installation.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}