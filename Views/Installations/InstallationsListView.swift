import SwiftUI
import SwiftData

struct InstallationsListView: View {
    @Environment(\.viewModelContainer) private var viewModelContainer
    
    private var viewModel: InstallationsViewModel {
        viewModelContainer?.installationsViewModel ?? InstallationsViewModel(
            dataService: DataService(modelContext: ModelContext(for: Schema([
                Installation.self, SolarJob.self, Customer.self, Equipment.self, Vendor.self, Contract.self
            ])))
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
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
                                    isSelected: viewModel.selectedStatus == nil
                                ) {
                                    viewModel.selectedStatus = nil
                                }
                                
                                ForEach(InstallationStatus.allCases, id: \.self) { status in
                                    FilterChip(
                                        title: status.rawValue,
                                        isSelected: viewModel.selectedStatus == status,
                                        count: viewModel.getInstallationsCount(for: status)
                                    ) {
                                        viewModel.selectedStatus = viewModel.selectedStatus == status ? nil : status
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        
                        // Sort Controls
                        HStack {
                            Menu("Sort: \(sortByTitle(viewModel.sortBy))") {
                                ForEach([InstallationSortBy.scheduledDate, .status, .crewSize], id: \.self) { sortOption in
                                    Button(sortByTitle(sortOption)) {
                                        viewModel.sortBy = sortOption
                                    }
                                }
                            }
                            .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.sortAscending.toggle()
                            }) {
                                Image(systemName: viewModel.sortAscending ? "arrow.up" : "arrow.down")
                                    .foregroundColor(.secondary)
                            }
                            
                            Button("Clear Filters") {
                                viewModel.clearFilters()
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        
                        // Installations List
                        List {
                            ForEach(viewModel.filteredInstallations, id: \.id) { installation in
                                Button(action: {
                                    viewModel.showInstallationDetail(installation)
                                }) {
                                    InstallationRowView(installation: installation) { newStatus in
                                        viewModel.updateInstallationStatus(installation, to: newStatus)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .onDelete(perform: deleteInstallations)
                        }
                        .searchable(text: $viewModel.searchText, prompt: "Search installations...")
                    }
                }
            }
            .navigationTitle("Schedule (\(viewModel.filteredInstallations.count))")
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
                    Button(action: { viewModel.showAddInstallation() }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddInstallation) {
                AddInstallationView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingInstallationDetail) {
                if let installation = viewModel.selectedInstallation {
                    InstallationDetailView(installation: installation)
                }
            }
            .refreshable {
                viewModel.loadData()
            }
            .onAppear {
                // Load installations when view appears
                viewModel.loadData()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    private func deleteInstallations(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                viewModel.deleteInstallation(viewModel.filteredInstallations[index])
            }
        }
    }
    
    private func sortByTitle(_ sortBy: InstallationSortBy) -> String {
        switch sortBy {
        case .scheduledDate: return "Scheduled Date"
        case .status: return "Status"
        case .crewSize: return "Crew Size"
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

struct AddInstallationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: InstallationsViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section("Job Selection") {
                    Picker("Select Job", selection: $viewModel.newInstallationJobId) {
                        Text("Select a job...").tag(UUID?.none)
                        ForEach(viewModel.getAvailableJobs(), id: \.id) { job in
                            Text("\(job.customerName) - \(job.address)")
                                .tag(UUID?.some(job.id))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Schedule Details") {
                    DatePicker("Scheduled Date", selection: $viewModel.newInstallationScheduledDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                    
                    HStack {
                        Text("Estimated Duration")
                        Spacer()
                        Picker("Duration", selection: $viewModel.newInstallationEstimatedDuration) {
                            Text("4 hours").tag(4 * 3600.0)
                            Text("6 hours").tag(6 * 3600.0)
                            Text("8 hours").tag(8 * 3600.0)
                            Text("10 hours").tag(10 * 3600.0)
                            Text("12 hours").tag(12 * 3600.0)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("Crew Size")
                        Spacer()
                        Picker("Crew Size", selection: $viewModel.newInstallationCrewSize) {
                            ForEach(1...6, id: \.self) { size in
                                Text("\(size) people").tag(size)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section("Notes") {
                    TextField("Installation notes...", text: $viewModel.newInstallationNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Validation Errors
                if !viewModel.formErrors.isEmpty {
                    Section("Please fix the following errors:") {
                        ForEach(viewModel.formErrors, id: \.field) { error in
                            Text(error.message)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Schedule Installation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schedule") {
                        viewModel.addInstallation()
                        if viewModel.formErrors.isEmpty {
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.validateForm())
                }
            }
        }
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