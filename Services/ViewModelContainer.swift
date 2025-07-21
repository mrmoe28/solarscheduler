import SwiftUI
import SwiftData

@Observable
class ViewModelContainer {
    private let dataService: DataService
    private let userSession: UserSession
    
    // ViewModels
    let jobsViewModel: JobsViewModel
    let customersViewModel: CustomersViewModel
    let equipmentViewModel: EquipmentViewModel
    let installationsViewModel: InstallationsViewModel
    let dashboardViewModel: DashboardViewModel
    
    init(modelContext: ModelContext) {
        self.dataService = DataService(modelContext: modelContext)
        self.userSession = UserSession.shared
        
        // Configure UserSession with ModelContext
        userSession.configure(with: modelContext)
        
        // Initialize all ViewModels with the shared DataService and UserSession
        self.jobsViewModel = JobsViewModel(dataService: dataService, userSession: userSession)
        self.customersViewModel = CustomersViewModel(dataService: dataService, userSession: userSession)
        self.equipmentViewModel = EquipmentViewModel(dataService: dataService, userSession: userSession)
        self.installationsViewModel = InstallationsViewModel(dataService: dataService, userSession: userSession)
        self.dashboardViewModel = DashboardViewModel(dataService: dataService, userSession: userSession)
    }
}

// Environment key for ViewModelContainer
struct ViewModelContainerKey: EnvironmentKey {
    static let defaultValue: ViewModelContainer? = nil
}

extension EnvironmentValues {
    var viewModelContainer: ViewModelContainer? {
        get { self[ViewModelContainerKey.self] }
        set { self[ViewModelContainerKey.self] = newValue }
    }
}