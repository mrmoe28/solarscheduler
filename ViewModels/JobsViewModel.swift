import Foundation
import SwiftUI

@Observable
class JobsViewModel {
    private let dataService: DataService
    private let validationService: ValidationService
    private let notificationService: NotificationService
    
    // Data
    var jobs: [SolarJob] = []
    var filteredJobs: [SolarJob] = []
    
    // UI State
    var isLoading = false
    var errorMessage: String?
    var searchText = "" {
        didSet {
            applyFilters()
        }
    }
    var selectedStatus: JobStatus? {
        didSet {
            applyFilters()
        }
    }
    var sortBy: SortBy = .createdDate {
        didSet {
            applyFilters()
        }
    }
    var sortAscending = false {
        didSet {
            applyFilters()
        }
    }
    
    // Form State
    var showingAddJob = false
    var showingJobDetail = false
    var selectedJob: SolarJob?
    
    // Add Job Form
    var newJobCustomerName = ""
    var newJobAddress = ""
    var newJobSystemSize = 0.0
    var newJobEstimatedRevenue = 0.0
    var newJobScheduledDate: Date?
    var newJobNotes = ""
    var formErrors: [ValidationService.ValidationError] = []
    
    init(dataService: DataService, validationService: ValidationService = .shared, notificationService: NotificationService = .shared) {
        self.dataService = dataService
        self.validationService = validationService
        self.notificationService = notificationService
        loadJobs()
    }
    
    // MARK: - Data Loading
    
    func loadJobs() {
        Task { @MainActor in
            isLoading = true
            errorMessage = nil
            
            do {
                jobs = try dataService.fetchJobs(
                    sortBy: sortBy,
                    ascending: sortAscending
                )
                applyFilters()
            } catch {
                errorMessage = "Failed to load jobs: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
            
            isLoading = false
        }
    }
    
    private func applyFilters() {
        var filtered = jobs
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.customerName.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply status filter
        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }
        
        // Apply sorting
        switch sortBy {
        case .createdDate:
            filtered.sort { sortAscending ? $0.createdDate < $1.createdDate : $0.createdDate > $1.createdDate }
        case .customerName:
            filtered.sort { sortAscending ? $0.customerName < $1.customerName : $0.customerName > $1.customerName }
        case .revenue:
            filtered.sort { sortAscending ? $0.estimatedRevenue < $1.estimatedRevenue : $0.estimatedRevenue > $1.estimatedRevenue }
        case .systemSize:
            filtered.sort { sortAscending ? $0.systemSize < $1.systemSize : $0.systemSize > $1.systemSize }
        }
        
        filteredJobs = filtered
    }
    
    // MARK: - Job Management
    
    func addJob() {
        let validation = validationService.validateJob(
            customerName: newJobCustomerName,
            address: newJobAddress,
            systemSize: newJobSystemSize,
            estimatedRevenue: newJobEstimatedRevenue,
            scheduledDate: newJobScheduledDate
        )
        
        guard validation.isValid else {
            formErrors = validation.errors
            notificationService.notifyValidationErrors(validation.errors)
            return
        }
        
        Task { @MainActor in
            do {
                let job = try dataService.createJob(
                    customerName: newJobCustomerName,
                    address: newJobAddress,
                    systemSize: newJobSystemSize,
                    estimatedRevenue: newJobEstimatedRevenue,
                    notes: newJobNotes
                )
                
                if let scheduledDate = newJobScheduledDate {
                    job.scheduledDate = scheduledDate
                    try dataService.save()
                }
                
                notificationService.notifyDataSaveSuccess("Job created successfully")
                resetForm()
                showingAddJob = false
                loadJobs()
                
            } catch {
                errorMessage = "Failed to create job: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    func updateJob(_ job: SolarJob) {
        Task { @MainActor in
            do {
                try dataService.save()
                notificationService.notifyDataSaveSuccess("Job updated successfully")
                loadJobs()
            } catch {
                errorMessage = "Failed to update job: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    func deleteJob(_ job: SolarJob) {
        Task { @MainActor in
            do {
                try dataService.delete(job)
                notificationService.notifyDataSaveSuccess("Job deleted successfully")
                loadJobs()
            } catch {
                errorMessage = "Failed to delete job: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    func updateJobStatus(_ job: SolarJob, to newStatus: JobStatus) {
        // Validate status transition
        let validation = validationService.validateJobStatusTransition(
            from: job.status,
            to: newStatus
        )
        
        guard validation.isValid else {
            notificationService.notifyValidationError(validation.errors.first!)
            return
        }
        
        Task { @MainActor in
            do {
                let oldStatus = job.status
                try dataService.updateJobStatus(job, to: newStatus)
                
                notificationService.notifyJobStatusChange(job, from: oldStatus, to: newStatus)
                
                // Special handling for completed jobs
                if newStatus == .completed {
                    notificationService.notifyJobCompleted(job)
                }
                
                loadJobs()
            } catch {
                errorMessage = "Failed to update job status: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    // MARK: - Search and Filter
    
    func searchJobs(_ query: String) {
        Task { @MainActor in
            do {
                if query.isEmpty {
                    loadJobs()
                } else {
                    jobs = try dataService.searchJobs(query: query)
                    applyFilters()
                }
            } catch {
                errorMessage = "Search failed: \(error.localizedDescription)"
            }
        }
    }
    
    func clearFilters() {
        searchText = ""
        selectedStatus = nil
        sortBy = .createdDate
        sortAscending = false
        applyFilters()
    }
    
    func getJobsCount(for status: JobStatus) -> Int {
        jobs.filter { $0.status == status }.count
    }
    
    // MARK: - Form Management
    
    func resetForm() {
        newJobCustomerName = ""
        newJobAddress = ""
        newJobSystemSize = 0.0
        newJobEstimatedRevenue = 0.0
        newJobScheduledDate = nil
        newJobNotes = ""
        formErrors = []
    }
    
    func validateForm() -> Bool {
        let validation = validationService.validateJob(
            customerName: newJobCustomerName,
            address: newJobAddress,
            systemSize: newJobSystemSize,
            estimatedRevenue: newJobEstimatedRevenue,
            scheduledDate: newJobScheduledDate
        )
        
        formErrors = validation.errors
        return validation.isValid
    }
    
    func hasErrorForField(_ field: String) -> Bool {
        validationService.hasErrorForField(field, in: formErrors)
    }
    
    func getErrorsForField(_ field: String) -> [ValidationService.ValidationError] {
        validationService.getErrorsForField(field, from: formErrors)
    }
    
    // MARK: - Navigation
    
    func showJobDetail(_ job: SolarJob) {
        selectedJob = job
        showingJobDetail = true
    }
    
    func showAddJob() {
        resetForm()
        showingAddJob = true
    }
    
    // MARK: - Analytics
    
    func getJobStatistics() -> JobStatistics {
        let totalJobs = jobs.count
        let activeJobs = jobs.filter { $0.status == .inProgress }.count
        let completedJobs = jobs.filter { $0.status == .completed }.count
        let cancelledJobs = jobs.filter { $0.status == .cancelled }.count
        
        let totalRevenue = jobs.filter { $0.status == .completed }
            .reduce(0) { $0 + $1.estimatedRevenue }
        
        let pendingRevenue = jobs.filter { $0.status != .completed && $0.status != .cancelled }
            .reduce(0) { $0 + $1.estimatedRevenue }
        
        let avgSystemSize = jobs.isEmpty ? 0 : jobs.reduce(0) { $0 + $1.systemSize } / Double(jobs.count)
        
        return JobStatistics(
            totalJobs: totalJobs,
            activeJobs: activeJobs,
            completedJobs: completedJobs,
            cancelledJobs: cancelledJobs,
            totalRevenue: totalRevenue,
            pendingRevenue: pendingRevenue,
            averageSystemSize: avgSystemSize,
            completionRate: totalJobs > 0 ? Double(completedJobs) / Double(totalJobs) : 0
        )
    }
    
    func getRevenueByStatus() -> [String: Double] {
        var revenueByStatus: [String: Double] = [:]
        
        for status in JobStatus.allCases {
            let revenue = jobs.filter { $0.status == status }
                .reduce(0) { $0 + $1.estimatedRevenue }
            revenueByStatus[status.rawValue] = revenue
        }
        
        return revenueByStatus
    }
    
    func getJobsCreatedThisMonth() -> [SolarJob] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return jobs.filter { $0.createdDate >= startOfMonth }
    }
    
    // MARK: - Export
    
    func exportJobs(format: ExportService.ExportFormat) {
        Task { @MainActor in
            let result = await ExportService.shared.exportJobs(
                filteredJobs,
                format: format,
                includeDetails: true
            )
            
            if result.success {
                notificationService.showInAppNotification(
                    AppNotification(
                        title: "Export Successful",
                        message: "Jobs exported to \(result.fileName)",
                        type: .success
                    )
                )
            } else {
                notificationService.showInAppNotification(
                    AppNotification(
                        title: "Export Failed",
                        message: result.error?.localizedDescription ?? "Unknown error",
                        type: .error
                    )
                )
            }
        }
    }
}