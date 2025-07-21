import SwiftUI
import SwiftData

// MARK: - Simple Add Job Form
struct AddJobFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var customers: [Customer]
    
    @State private var customerName = ""
    @State private var address = ""
    @State private var systemSize = ""
    @State private var estimatedRevenue = ""
    @State private var notes = ""
    @State private var selectedStatus: JobStatus = .pending
    
    var body: some View {
        Form {
            Section("Customer Information") {
                TextField("Customer Name", text: $customerName)
                TextField("Installation Address", text: $address)
            }
            
            Section("System Details") {
                HStack {
                    TextField("System Size", text: $systemSize)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Text("kW")
                        .foregroundColor(.secondary)
                }
                
                Picker("Status", selection: $selectedStatus) {
                    ForEach(JobStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
            }
            
            Section("Financial") {
                HStack {
                    Text("$")
                    TextField("Estimated Revenue", text: $estimatedRevenue)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
            }
            
            Section("Notes") {
                TextField("Additional Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle("New Solar Job")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Cancel") { dismiss() }
            }
            
            ToolbarItem(placement: .automatic) {
                Button("Create") {
                    saveJob()
                }
                .fontWeight(.semibold)
                .disabled(!isFormValid)
            }
        }
    }
    
    private var isFormValid: Bool {
        !customerName.isEmpty && !address.isEmpty && !systemSize.isEmpty
    }
    
    private func saveJob() {
        guard let systemSizeValue = Double(systemSize) else { return }
        let revenueValue = Double(estimatedRevenue) ?? 0.0
        
        let job = SolarJob(
            customerName: customerName,
            address: address,
            systemSize: systemSizeValue,
            status: selectedStatus,
            estimatedRevenue: revenueValue,
            notes: notes
        )
        
        modelContext.insert(job)
        do {
            try modelContext.save()
            print("✅ Job saved successfully: \(job.customerName)")
            dismiss()
        } catch {
            print("❌ Failed to save job: \(error)")
        }
    }
}

struct JobsListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: JobsViewModel?
    
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
    
    private var isAllSelected: Bool {
        currentViewModel.selectedStatus == nil
    }
    
    var body: some View {
        ZStack {
                if currentViewModel.isLoading {
                    ProgressView("Loading jobs...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.systemBackground)
                } else {
                    VStack(spacing: 0) {
                        // Filter Section
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FilterChip(
                                    title: "All",
                                    isSelected: isAllSelected
                                ) {
                                    currentViewModel.updateSelectedStatus(nil)
                                }
                                
                                ForEach(JobStatus.allCases, id: \.self) { status in
                                    FilterChip(
                                        title: status.rawValue,
                                        isSelected: currentViewModel.selectedStatus == status,
                                        count: currentViewModel.getJobsCount(for: status)
                                    ) {
                                        currentViewModel.updateSelectedStatus(currentViewModel.selectedStatus == status ? nil : status)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        
                        // Sort Controls
                        HStack {
                            Menu("Sort: \(sortByTitle(currentViewModel.sortBy))") {
                                ForEach([SortBy.createdDate, .customerName, .revenue, .systemSize], id: \.self) { sortOption in
                                    Button(sortByTitle(sortOption)) {
                                        currentViewModel.updateSortBy(sortOption)
                                    }
                                }
                            }
                            .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                currentViewModel.updateSortAscending(!currentViewModel.sortAscending)
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
                        
                        // Jobs List
                        List {
                            ForEach(currentViewModel.filteredJobs, id: \.id) { job in
                                JobRowView(job: job) { newStatus in
                                    currentViewModel.updateJobStatus(job, to: newStatus)
                                }
                            }
                            .onDelete(perform: deleteJobs)
                        }
                        .searchable(text: Binding(
                            get: { currentViewModel.searchText },
                            set: { currentViewModel.updateSearchText($0) }
                        ), prompt: "Search jobs...")
                    }
                }
            }
            .navigationTitle("Jobs (\(currentViewModel.filteredJobs.count))")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu("Export") {
                        Button("Export as CSV") {
                            currentViewModel.exportJobs(format: .csv)
                        }
                        Button("Export as JSON") {
                            currentViewModel.exportJobs(format: .json)
                        }
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button(action: { currentViewModel.showAddJob() }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .sheet(isPresented: Binding(
                get: { currentViewModel.showingAddJob },
                set: { currentViewModel.showingAddJob = $0 }
            )) {
                NavigationStack {
                    AddJobFormView()
                }
            }
            .sheet(isPresented: Binding(
                get: { currentViewModel.showingJobDetail },
                set: { currentViewModel.showingJobDetail = $0 }
            )) {
                if let job = currentViewModel.selectedJob {
                    JobDetailView(job: job)
                }
            }
            .refreshable {
                currentViewModel.loadJobs()
            }
            .onAppear {
                // Load jobs when view appears
                currentViewModel.loadJobs()
            }
            .onChange(of: currentViewModel.showingAddJob) { _, newValue in
                if !newValue {
                    // Refresh jobs list when add job sheet is dismissed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        currentViewModel.loadJobs()
                    }
                }
            }
            .alert("Error", isPresented: .constant(currentViewModel.errorMessage != nil)) {
                Button("OK") {
                    currentViewModel.errorMessage = nil
                }
            } message: {
                Text(currentViewModel.errorMessage ?? "")
            }
            .overlay(alignment: .bottomTrailing) {
                Button(action: { currentViewModel.showAddJob() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.orange)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 100)
                .zIndex(1000)
            }
    }
    
    private func deleteJobs(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                currentViewModel.deleteJob(currentViewModel.filteredJobs[index])
            }
        }
    }
    
    private func sortByTitle(_ sortBy: SortBy) -> String {
        switch sortBy {
        case .createdDate: return "Date Created"
        case .customerName: return "Customer Name"
        case .revenue: return "Revenue"
        case .systemSize: return "System Size"
        }
    }
}

struct JobRowView: View {
    let job: SolarJob
    let onStatusChange: ((JobStatus) -> Void)?
    @State private var showingDetail = false
    @State private var showingDeleteAlert = false
    @State private var showShareSheet = false
    @Environment(\.modelContext) private var modelContext
    
    init(job: SolarJob, onStatusChange: ((JobStatus) -> Void)? = nil) {
        self.job = job
        self.onStatusChange = onStatusChange
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Main content - clickable
            Button(action: { showingDetail = true }) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(job.customerName)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text(job.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            if let onStatusChange = onStatusChange {
                                Menu {
                                    ForEach(JobStatus.allCases, id: \.self) { status in
                                        Button(status.rawValue) {
                                            onStatusChange(status)
                                        }
                                    }
                                } label: {
                                    StatusBadge(status: job.status.rawValue, color: Color(job.status.color))
                                }
                            } else {
                                StatusBadge(status: job.status.rawValue, color: Color(job.status.color))
                            }
                            
                            Text("$\(job.estimatedRevenue.safeValue, specifier: "%.0f")")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack {
                        Label("\(job.systemSize.safeValue, specifier: "%.1f") kW", systemImage: "bolt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(job.createdDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Action buttons
            HStack(spacing: 16) {
                // View button
                Button(action: { showingDetail = true }) {
                    Image(systemName: "eye")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
                
                // Share button
                Button(action: { showShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                }
                
                // Delete button
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingDetail) {
            NavigationStack {
                JobDetailView(job: job)
            }
        }
        .alert("Delete Job", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(job)
                do {
                    try modelContext.save()
                } catch {
                    print("Failed to delete job: \(error)")
                }
            }
        } message: {
            Text("Are you sure you want to delete this job? This action cannot be undone.")
        }
        #if os(iOS)
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(items: [createJobShareText()])
        }
        #endif
    }
    
    private func createJobShareText() -> String {
        """
        Solar Job Details:
        Customer: \(job.customerName)
        Address: \(job.address)
        System Size: \(job.systemSize) kW
        Status: \(job.status.rawValue)
        Revenue: $\(job.estimatedRevenue.formatted())
        Created: \(job.createdDate.formatted())
        \(job.notes.isEmpty ? "" : "\nNotes: \(job.notes)")
        """
    }
}

// MARK: - Job Detail View
struct JobDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var job: SolarJob
    @State private var showingEditJob = false
    @State private var showingDeleteAlert = false
    @State private var showingScheduleInstallation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(job.customerName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(job.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        StatusBadge(status: job.status.rawValue, color: Color(job.status.color))
                    }
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("System Size")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(job.systemSize, specifier: "%.1f") kW")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Revenue")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(job.estimatedRevenue, specifier: "%.0f")")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Created")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(job.createdDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.headline)
                        }
                        
                        Spacer()
                    }
                }
                .padding(20)
                .background(Color.secondarySystemBackground)
                .cornerRadius(12)
                
                // Status Management
                VStack(alignment: .leading, spacing: 12) {
                    Text("Job Status")
                        .font(.headline)
                    
                    Menu {
                        ForEach(JobStatus.allCases, id: \.self) { status in
                            Button(status.rawValue) {
                                withAnimation {
                                    job.status = status
                                    saveChanges()
                                }
                            }
                        }
                    } label: {
                        HStack {
                            StatusBadge(status: job.status.rawValue, color: Color(job.status.color))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(Color.secondarySystemBackground)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Notes Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes")
                        .font(.headline)
                    
                    TextField("Add notes about this job...", text: $job.notes, axis: .vertical)
                        .lineLimit(3...8)
                        .padding(16)
                        .background(Color.secondarySystemBackground)
                        .cornerRadius(12)
                        .onChange(of: job.notes) { _, _ in
                            saveChanges()
                        }
                }
                
                // Quick Actions
                VStack(spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 8) {
                        JobActionButton(
                            icon: "calendar.badge.plus",
                            title: "Schedule Installation",
                            color: .orange
                        ) {
                            showingScheduleInstallation = true
                        }
                        
                        JobActionButton(
                            icon: "pencil",
                            title: "Edit Job Details",
                            color: .blue
                        ) {
                            showingEditJob = true
                        }
                        
                        JobActionButton(
                            icon: "trash",
                            title: "Delete Job",
                            color: .red
                        ) {
                            showingDeleteAlert = true
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(20)
        }
        .navigationTitle("Job Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showingEditJob) {
            EditJobView(job: job)
        }
        .sheet(isPresented: $showingScheduleInstallation) {
            NavigationStack {
                if let installationViewModel = createInstallationViewModel() {
                    AddInstallationView(viewModel: installationViewModel)
                        .onAppear {
                            // Pre-select this job when opening the installation scheduling
                            installationViewModel.newInstallationJobId = job.id
                        }
                } else {
                    Text("Unable to load installation scheduling")
                        .foregroundColor(.secondary)
                }
            }
        }
        .alert("Delete Job", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteJob()
            }
        } message: {
            Text("Are you sure you want to delete this job? This action cannot be undone.")
        }
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save job changes: \(error)")
        }
    }
    
    private func deleteJob() {
        modelContext.delete(job)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete job: \(error)")
        }
    }
    
    private func createInstallationViewModel() -> InstallationsViewModel? {
        let dataService = DataService(modelContext: modelContext)
        return InstallationsViewModel(dataService: dataService)
    }
}

// MARK: - Job Action Button
struct JobActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color.secondarySystemBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Job View
struct EditJobView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var job: SolarJob
    
    @State private var customerName: String
    @State private var address: String
    @State private var systemSize: String
    @State private var estimatedRevenue: String
    @State private var notes: String
    @State private var selectedStatus: JobStatus
    
    init(job: SolarJob) {
        self.job = job
        self._customerName = State(initialValue: job.customerName)
        self._address = State(initialValue: job.address)
        self._systemSize = State(initialValue: String(job.systemSize))
        self._estimatedRevenue = State(initialValue: String(job.estimatedRevenue))
        self._notes = State(initialValue: job.notes)
        self._selectedStatus = State(initialValue: job.status)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Customer Information") {
                    TextField("Customer Name", text: $customerName)
                    TextField("Installation Address", text: $address)
                }
                
                Section("System Details") {
                    HStack {
                        TextField("System Size", text: $systemSize)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                        Text("kW")
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(JobStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }
                
                Section("Financial") {
                    HStack {
                        Text("$")
                        TextField("Estimated Revenue", text: $estimatedRevenue)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                }
                
                Section("Notes") {
                    TextField("Additional Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Job")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !customerName.isEmpty && !address.isEmpty && !systemSize.isEmpty
    }
    
    private func saveChanges() {
        guard let systemSizeValue = Double(systemSize) else { return }
        let revenueValue = Double(estimatedRevenue) ?? 0.0
        
        job.customerName = customerName
        job.address = address
        job.systemSize = systemSizeValue
        job.estimatedRevenue = revenueValue
        job.notes = notes
        job.status = selectedStatus
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save job: \(error)")
        }
    }
}

// AddJobView is now defined in Views/Jobs/AddJobView.swift

#Preview {
    let container = try! ModelContainer(for: SolarJob.self, Customer.self, Equipment.self, Installation.self, Vendor.self, Contract.self)
    
    JobsListView()
        .modelContainer(container)
}

