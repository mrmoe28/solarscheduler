import SwiftUI
import SwiftData

struct JobsListView: View {
    @Environment(\.viewModelContainer) private var viewModelContainer
    
    private var viewModel: JobsViewModel {
        viewModelContainer?.jobsViewModel ?? JobsViewModel(
            dataService: DataService(modelContext: ModelContext(for: Schema([
                SolarJob.self, Customer.self, Equipment.self, Installation.self, Vendor.self, Contract.self
            ])))
        )
    }
    
    var body: some View {
        ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading jobs...")
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
                                
                                ForEach(JobStatus.allCases, id: \.self) { status in
                                    FilterChip(
                                        title: status.rawValue,
                                        isSelected: viewModel.selectedStatus == status,
                                        count: viewModel.getJobsCount(for: status)
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
                                ForEach([SortBy.createdDate, .customerName, .revenue, .systemSize], id: \.self) { sortOption in
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
                        
                        // Jobs List
                        List {
                            ForEach(viewModel.filteredJobs, id: \.id) { job in
                                Button(action: {
                                    viewModel.showJobDetail(job)
                                }) {
                                    JobRowView(job: job) { newStatus in
                                        viewModel.updateJobStatus(job, to: newStatus)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .onDelete(perform: deleteJobs)
                        }
                        .searchable(text: $viewModel.searchText, prompt: "Search jobs...")
                    }
                }
            }
            .navigationTitle("Jobs (\(viewModel.filteredJobs.count))")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu("Export") {
                        Button("Export as CSV") {
                            viewModel.exportJobs(format: .csv)
                        }
                        Button("Export as JSON") {
                            viewModel.exportJobs(format: .json)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showAddJob() }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddJob) {
                AddJobView()
            }
            .sheet(isPresented: $viewModel.showingJobDetail) {
                if let job = viewModel.selectedJob {
                    JobDetailView(job: job)
                }
            }
            .refreshable {
                viewModel.loadJobs()
            }
            .onAppear {
                // Load jobs when view appears
                viewModel.loadJobs()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
    }
    
    private func deleteJobs(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                viewModel.deleteJob(viewModel.filteredJobs[index])
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
    
    init(job: SolarJob, onStatusChange: ((JobStatus) -> Void)? = nil) {
        self.job = job
        self.onStatusChange = onStatusChange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.customerName)
                        .font(.headline)
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
        .padding(.vertical, 4)
    }
}

// Placeholder views that need to be implemented
struct JobDetailView: View {
    let job: SolarJob
    
    var body: some View {
        Text("Job Detail: \(job.customerName)")
            .navigationTitle("Job Details")
    }
}

// AddJobView is now defined in Views/Jobs/AddJobView.swift

#Preview {
    let container = try! ModelContainer(for: SolarJob.self, Customer.self, Equipment.self, Installation.self, Vendor.self, Contract.self)
    let dataService = DataService(modelContext: container.mainContext)
    let viewModel = JobsViewModel(dataService: dataService)
    
    return JobsListView(viewModel: viewModel)
        .modelContainer(container)
}