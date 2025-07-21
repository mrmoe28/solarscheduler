import SwiftUI
import SwiftData

#if os(iOS)
@main
struct SolarSchedulerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            SolarJob.self,
            Customer.self,
            Equipment.self,
            Vendor.self,
            Installation.self,
            Contract.self
        ])
        
        // Configure for local storage only (no CloudKit)
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("ModelContainer Error Details:")
            print("Error Type: \(type(of: error))")
            print("Error Description: \(error)")
            print("Error LocalizedDescription: \(error.localizedDescription)")
            
            // Try with in-memory storage as fallback
            print("Attempting to create in-memory ModelContainer...")
            let memoryConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                allowsSave: true,
                cloudKitDatabase: .none
            )
            
            do {
                return try ModelContainer(for: schema, configurations: [memoryConfig])
            } catch {
                fatalError("Could not create ModelContainer even with in-memory storage: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
#endif