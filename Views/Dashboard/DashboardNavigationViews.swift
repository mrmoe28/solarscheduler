import SwiftUI
import SwiftData

// MARK: - Jobs List with Filter
struct JobsListViewWithFilter: View {
    let filter: JobsFilter
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: JobsViewModel?
    
    enum JobsFilter {
        case all
        case active
    }
    
    private var currentViewModel: JobsViewModel {
        if let vm = viewModel {
            return vm
        } else {
            let dataService = DataService(modelContext: modelContext)
            let newViewModel = JobsViewModel(dataService: dataService)
            viewModel = newViewModel
            return newViewModel
        }
    }
    
    var body: some View {
        JobsListView()
            .navigationTitle(filter == .active ? "Active Jobs" : "All Jobs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Apply filter based on the type
                if filter == .active {
                    currentViewModel.updateSelectedStatus(.inProgress)
                } else {
                    currentViewModel.updateSelectedStatus(nil)
                }
            }
    }
}

// MARK: - Inventory List with Filter
struct InventoryListViewWithFilter: View {
    let showLowStockOnly: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: EquipmentViewModel?
    
    private var currentViewModel: EquipmentViewModel {
        if let vm = viewModel {
            return vm
        } else {
            let dataService = DataService(modelContext: modelContext)
            let newViewModel = EquipmentViewModel(dataService: dataService)
            viewModel = newViewModel
            return newViewModel
        }
    }
    
    var body: some View {
        InventoryListView()
            .navigationTitle(showLowStockOnly ? "Low Stock Items" : "Inventory")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if showLowStockOnly {
                    currentViewModel.updateShowLowStockOnly(true)
                }
            }
    }
}

// MARK: - Customer List Navigation
extension CustomersListView {
    func withDismissButton() -> some View {
        self.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    // This will be handled by the parent sheet
                }
            }
        }
    }
}