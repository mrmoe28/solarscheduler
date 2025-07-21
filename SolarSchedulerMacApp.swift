import SwiftUI
import SwiftData

#if os(macOS)
@main
struct SolarSchedulerMacApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            SolarJob.self,
            Customer.self,
            Equipment.self,
            Installation.self,
            Vendor.self,
            Contract.self
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
            RootView()
                .frame(minWidth: 1000, idealWidth: 1200, maxWidth: .infinity,
                       minHeight: 700, idealHeight: 800, maxHeight: .infinity)
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            // Add macOS menu commands
            CommandGroup(after: .newItem) {
                Button("New Job") {
                    // Handle new job creation
                }
                .keyboardShortcut("j", modifiers: [.command])
                
                Button("New Customer") {
                    // Handle new customer creation
                }
                .keyboardShortcut("k", modifiers: [.command])
            }
        }
        
        #if os(macOS)
        Settings {
            SettingsView()
                .frame(width: 600, height: 400)
        }
        #endif
    }
}
#endif