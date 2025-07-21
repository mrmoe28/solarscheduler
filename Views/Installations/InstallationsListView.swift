import SwiftUI
import SwiftData

struct InstallationsListView: View {
    @Environment(\.viewModelContainer) private var viewModelContainer
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: InstallationsViewModel?
    
    private var currentViewModel: InstallationsViewModel {
        if let vm = viewModel {
            return vm
        } else {
            if let container = viewModelContainer {
                return container.installationsViewModel
            } else {
                let dataService = DataService(modelContext: modelContext)
                let newViewModel = InstallationsViewModel(dataService: dataService)
                viewModel = newViewModel
                return newViewModel
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if currentViewModel.isLoading {
                    ProgressView("Loading installations...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(UIColor.systemBackground))
                } else {
                    VStack(spacing: 0) {
                        // Filter Section
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FilterChip(
                                    title: "All",
                                    isSelected: currentViewModel.selectedStatus == nil
                                ) {
                                    currentViewModel.selectedStatus = nil
                                }
                                
                                ForEach(InstallationStatus.allCases, id: \.self) { status in
                                    FilterChip(
                                        title: status.rawValue,
                                        isSelected: currentViewModel.selectedStatus == status,
                                        count: currentViewModel.getInstallationsCount(for: status)
                                    ) {
                                        currentViewModel.selectedStatus = currentViewModel.selectedStatus == status ? nil : status
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        
                        // Sort Controls
                        HStack {
                            Menu("Sort: \(sortByTitle(currentViewModel.sortBy))") {
                                ForEach([InstallationSortBy.scheduledDate, .status, .crewMembers], id: \.self) { sortOption in
                                    Button(sortByTitle(sortOption)) {
                                        currentViewModel.sortBy = sortOption
                                    }
                                }
                            }
                            .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                currentViewModel.sortAscending.toggle()
                            }) {
                                Image(systemName: currentViewModel.sortAscending ? "arrow.up" : "arrow.down")
                                    .foregroundColor(.secondary)
                            }
                            
                            Button("Clear Filters") {
                                currentViewModel.clearFilters()
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        
                        // Installations List
                        List {
                            ForEach(currentViewModel.filteredInstallations, id: \.id) { installation in
                                Button(action: {
                                    currentViewModel.showInstallationDetail(installation)
                                }) {
                                    InstallationRowView(installation: installation) { newStatus in
                                        currentViewModel.updateInstallationStatus(installation, to: newStatus)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .onDelete(perform: deleteInstallations)
                        }
                        .searchable(text: $currentViewModel.searchText, prompt: "Search installations...")
                    }
                }
            }
            .navigationTitle("Schedule (\(currentViewModel.filteredInstallations.count))")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu("Export") {
                        Button("Export as CSV") {
                            // Export functionality would go here
                        }
                        Button("Export as JSON") {
                            // Export functionality would go here
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { currentViewModel.showAddInstallation() }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $currentViewModel.showingAddInstallation) {
                AddInstallationView(viewModel: viewModel)
            }
            .sheet(isPresented: $currentViewModel.showingInstallationDetail) {
                if let installation = currentViewModel.selectedInstallation {
                    InstallationDetailView(installation: installation)
                }
            }
            .refreshable {
                currentViewModel.loadData()
            }
            .onAppear {
                // Load installations when view appears
                currentViewModel.loadData()
            }
            .alert("Error", isPresented: .constant(currentViewModel.errorMessage != nil)) {
                Button("OK") {
                    currentViewModel.errorMessage = nil
                }
            } message: {
                Text(currentViewModel.errorMessage ?? "")
            }
        }
    }
    
    private func deleteInstallations(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                currentViewModel.deleteInstallation(currentViewModel.filteredInstallations[index])
            }
        }
    }
    
    private func sortByTitle(_ sortBy: InstallationSortBy) -> String {
        switch sortBy {
        case .scheduledDate: return "Scheduled Date"
        case .status: return "Status"
        case .crewMembers: return "Crew Size"
        }
    }
}

struct InstallationRowView: View {
    let installation: Installation
    let onStatusChange: ((InstallationStatus) -> Void)?
    
    init(installation: Installation, onStatusChange: ((InstallationStatus) -> Void)? = nil) {
        self.installation = installation
        self.onStatusChange = onStatusChange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: installation.status.icon)
                    .foregroundColor(Color(installation.status.color))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(installation.scheduledDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                    
                    if let jobCustomer = installation.job?.customerName {
                        Text("Customer: \(jobCustomer)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Text("Crew Size: \(installation.crewSize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let onStatusChange = onStatusChange {
                        Menu {
                            ForEach(InstallationStatus.allCases, id: \.self) { status in
                                Button(status.rawValue) {
                                    onStatusChange(status)
                                }
                            }
                        } label: {
                            StatusBadge(status: installation.status.rawValue, color: Color(installation.status.color))
                        }
                    } else {
                        StatusBadge(status: installation.status.rawValue, color: Color(installation.status.color))
                    }
                    
                    Text("Duration: \(formatDuration(installation.estimatedDuration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if installation.isOverdue {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("Overdue")
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        return "\(hours)h"
    }
}


// Placeholder views that need to be implemented
struct InstallationDetailView: View {
    let installation: Installation
    
    var body: some View {
        Text("Installation Detail: \(installation.scheduledDate.formatted())")
            .navigationTitle("Installation Details")
    }
}

#Preview {
    let container = try! ModelContainer(for: Installation.self, SolarJob.self, Customer.self, Equipment.self, Vendor.self, Contract.self)
    let dataService = DataService(modelContext: container.mainContext)
    let viewModel = InstallationsViewModel(dataService: dataService)
    
    return InstallationsListView(viewModel: viewModel)
        .modelContainer(container)
}