import SwiftUI
import SwiftData

@Observable
class ViewModelContainer {
    private let dataService: DataService
    
    // ViewModels
    let jobsViewModel: JobsViewModel
    let customersViewModel: CustomersViewModel
    let equipmentViewModel: EquipmentViewModel
    let installationsViewModel: InstallationsViewModel
    let dashboardViewModel: DashboardViewModel
    
    init(modelContext: ModelContext) {
        self.dataService = DataService(modelContext: modelContext)
        
        // Initialize all ViewModels with the shared DataService
        self.jobsViewModel = JobsViewModel(dataService: dataService)
        self.customersViewModel = CustomersViewModel(dataService: dataService)
        self.equipmentViewModel = EquipmentViewModel(dataService: dataService)
        self.installationsViewModel = InstallationsViewModel(dataService: dataService)
        self.dashboardViewModel = DashboardViewModel(dataService: dataService)
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