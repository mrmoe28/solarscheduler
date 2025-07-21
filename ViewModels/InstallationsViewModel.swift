import Foundation
import SwiftUI

@Observable
class InstallationsViewModel {
    private let dataService: DataService
    private let validationService: ValidationService
    private let notificationService: NotificationService
    private let userSession: UserSession
    
    // Data
    var installations: [Installation] = []
    var filteredInstallations: [Installation] = []
    var jobs: [SolarJob] = []
    
    // UI State
    var isLoading = false
    var errorMessage: String?
    var searchText = ""
    var selectedStatus: InstallationStatus?
    var selectedDateRange: DateRange = .all
    var sortBy: InstallationSortBy = .scheduledDate
    var sortAscending = true
    
    // Calendar State
    var selectedDate: Date = Date()
    var calendarDisplayMode: CalendarDisplayMode = .month
    
    // Form State
    var showingAddInstallation = false
    var showingInstallationDetail = false
    var selectedInstallation: Installation?
    
    // Add Installation Form
    var newInstallationJobId: UUID?
    var newInstallationScheduledDate = Date()
    var newInstallationEstimatedDuration: TimeInterval = 8 * 3600 // 8 hours
    var newInstallationCrewSize = 2
    var newInstallationNotes = ""
    var formErrors: [ValidationService.ValidationError] = []
    
    init(dataService: DataService, validationService: ValidationService = .shared, notificationService: NotificationService = .shared, userSession: UserSession = .shared) {
        self.dataService = dataService
        self.validationService = validationService
        self.notificationService = notificationService
        self.userSession = userSession
        loadData()
    }
    
    private var currentUser: User? {
        userSession.currentUser
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        Task { @MainActor in
            isLoading = true
            errorMessage = nil
            
            guard let user = currentUser else {
                errorMessage = "No user signed in"
                isLoading = false
                return
            }
            
            do {
                // Load installations
                installations = try dataService.fetchInstallations(
                    for: user,
                    sortBy: sortBy,
                    ascending: sortAscending
                )
                
                // Load jobs for installation creation
                jobs = try dataService.fetchJobs(for: user)
                
                applyFilters()
            } catch {
                errorMessage = "Failed to load installations: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
            
            isLoading = false
        }
    }
    
    private func applyFilters() {
        var filtered = installations
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { installation in
                installation.notes.localizedCaseInsensitiveContains(searchText) ||
                installation.job?.customerName.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply status filter
        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }
        
        // Apply date range filter
        let dateRange = getDateRange(for: selectedDateRange)
        if let startDate = dateRange.startDate, let endDate = dateRange.endDate {
            filtered = filtered.filter { installation in
                installation.scheduledDate >= startDate && installation.scheduledDate <= endDate
            }
        }
        
        // Apply sorting
        switch sortBy {
        case .scheduledDate:
            filtered.sort { sortAscending ? $0.scheduledDate < $1.scheduledDate : $0.scheduledDate > $1.scheduledDate }
        case .status:
            filtered.sort { sortAscending ? $0.status.rawValue < $1.status.rawValue : $0.status.rawValue > $1.status.rawValue }
        case .crewMembers:
            filtered.sort { installation1, installation2 in
                let crew1 = installation1.crewMembers.split(separator: ",").count
                let crew2 = installation2.crewMembers.split(separator: ",").count
                return sortAscending ? crew1 < crew2 : crew1 > crew2
            }
        }
        
        filteredInstallations = filtered
    }
    
    private func getDateRange(for range: DateRange) -> (startDate: Date?, endDate: Date?) {
        let calendar = Calendar.current
        let now = Date()
        
        switch range {
        case .all:
            return (nil, nil)
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return (startOfDay, endOfDay)
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
            return (startOfWeek, endOfWeek)
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
            return (startOfMonth, endOfMonth)
        case .nextWeek:
            let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now)!
            let startOfNextWeek = calendar.dateInterval(of: .weekOfYear, for: nextWeek)?.start ?? nextWeek
            let endOfNextWeek = calendar.dateInterval(of: .weekOfYear, for: nextWeek)?.end ?? nextWeek
            return (startOfNextWeek, endOfNextWeek)
        case .nextMonth:
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: now)!
            let startOfNextMonth = calendar.dateInterval(of: .month, for: nextMonth)?.start ?? nextMonth
            let endOfNextMonth = calendar.dateInterval(of: .month, for: nextMonth)?.end ?? nextMonth
            return (startOfNextMonth, endOfNextMonth)
        }
    }
    
    // MARK: - Installation Management
    
    func addInstallation() {
        let validation = validationService.validateInstallation(
            scheduledDate: newInstallationScheduledDate,
            estimatedDuration: newInstallationEstimatedDuration,
            crewSize: newInstallationCrewSize
        )
        
        guard validation.isValid else {
            formErrors = validation.errors
            notificationService.notifyValidationErrors(validation.errors)
            return
        }
        
        guard let jobId = newInstallationJobId,
              let job = jobs.first(where: { $0.id == jobId }) else {
            notificationService.showInAppNotification(
                AppNotification(
                    title: "Invalid Job",
                    message: "Please select a valid job for this installation",
                    type: .error
                )
            )
            return
        }
        
        guard let user = currentUser else {
            errorMessage = "No user signed in"
            return
        }
        
        Task { @MainActor in
            do {
                let installation = try dataService.createInstallation(
                    job: job,
                    scheduledDate: newInstallationScheduledDate,
                    crewMembers: "Crew \(newInstallationCrewSize)",
                    notes: newInstallationNotes,
                    estimatedDuration: newInstallationEstimatedDuration,
                    user: user
                )
                
                // Schedule reminder notification
                notificationService.scheduleInstallationReminder(
                    for: installation,
                    hoursBeforeInstallation: 24
                )
                
                notificationService.notifyDataSaveSuccess("Installation scheduled successfully")
                resetForm()
                showingAddInstallation = false
                loadData()
                
            } catch {
                errorMessage = "Failed to schedule installation: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    func updateInstallation(_ installation: Installation) {
        Task { @MainActor in
            do {
                try dataService.save()
                notificationService.notifyDataSaveSuccess("Installation updated successfully")
                loadData()
            } catch {
                errorMessage = "Failed to update installation: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    func deleteInstallation(_ installation: Installation) {
        Task { @MainActor in
            do {
                try dataService.delete(installation)
                notificationService.notifyDataSaveSuccess("Installation deleted successfully")
                loadData()
            } catch {
                errorMessage = "Failed to delete installation: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    func updateInstallationStatus(_ installation: Installation, to newStatus: InstallationStatus) {
        Task { @MainActor in
            do {
                installation.status = newStatus
                
                // Update completion date if completed
                if newStatus == .completed {
                    installation.endTime = Date()
                }
                
                try dataService.save()
                
                notificationService.showInAppNotification(
                    AppNotification(
                        title: "Installation Status Updated",
                        message: "Installation is now \(newStatus.rawValue)",
                        type: .info
                    )
                )
                
                loadData()
            } catch {
                errorMessage = "Failed to update installation status: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    func rescheduleInstallation(_ installation: Installation, to newDate: Date) {
        let validation = validationService.validateInstallation(
            scheduledDate: newDate,
            estimatedDuration: 8.0, // Default 8 hours
            crewSize: 2 // Default crew size
        )
        
        guard validation.isValid else {
            notificationService.notifyValidationError(validation.errors.first!)
            return
        }
        
        Task { @MainActor in
            do {
                installation.scheduledDate = newDate
                installation.status = .scheduled
                try dataService.save()
                
                // Update reminder notification
                notificationService.scheduleInstallationReminder(
                    for: installation,
                    hoursBeforeInstallation: 24
                )
                
                notificationService.showInAppNotification(
                    AppNotification(
                        title: "Installation Rescheduled",
                        message: "New date: \(newDate.formatted(date: .abbreviated, time: .shortened))",
                        type: .info
                    )
                )
                
                loadData()
            } catch {
                errorMessage = "Failed to reschedule installation: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    // MARK: - Calendar Functions
    
    func getInstallations(for date: Date) -> [Installation] {
        let calendar = Calendar.current
        return installations.filter { installation in
            calendar.isDate(installation.scheduledDate, inSameDayAs: date)
        }
    }
    
    func getInstallationsInRange(from startDate: Date, to endDate: Date) -> [Installation] {
        return installations.filter { installation in
            installation.scheduledDate >= startDate && installation.scheduledDate <= endDate
        }
    }
    
    func hasInstallations(on date: Date) -> Bool {
        return !getInstallations(for: date).isEmpty
    }
    
    func getInstallationCount(for date: Date) -> Int {
        return getInstallations(for: date).count
    }
    
    // MARK: - Search and Filter
    
    func searchInstallations(_ query: String) {
        searchText = query
        applyFilters()
    }
    
    func clearFilters() {
        searchText = ""
        selectedStatus = nil
        selectedDateRange = .all
        sortBy = .scheduledDate
        sortAscending = true
        applyFilters()
    }
    
    // MARK: - Manual Filter Updates
    
    func updateSearchText(_ text: String) {
        searchText = text
        Task { @MainActor in
            applyFilters()
        }
    }
    
    func updateSelectedStatus(_ status: InstallationStatus?) {
        selectedStatus = status
        Task { @MainActor in
            applyFilters()
        }
    }
    
    func updateSelectedDateRange(_ range: DateRange) {
        selectedDateRange = range
        Task { @MainActor in
            applyFilters()
        }
    }
    
    func updateSortBy(_ sort: InstallationSortBy) {
        sortBy = sort
        Task { @MainActor in
            applyFilters()
        }
    }
    
    func updateSortAscending(_ ascending: Bool) {
        sortAscending = ascending
        Task { @MainActor in
            applyFilters()
        }
    }
    
    func getInstallationsCount(for status: InstallationStatus) -> Int {
        installations.filter { $0.status == status }.count
    }
    
    // MARK: - Form Management
    
    func resetForm() {
        newInstallationJobId = nil
        newInstallationScheduledDate = Date()
        newInstallationEstimatedDuration = 8 * 3600 // 8 hours
        newInstallationCrewSize = 2
        newInstallationNotes = ""
        formErrors = []
    }
    
    func clearFormErrors() {
        formErrors = []
    }
    
    func validateForm() -> Bool {
        let validation = validationService.validateInstallation(
            scheduledDate: newInstallationScheduledDate,
            estimatedDuration: newInstallationEstimatedDuration,
            crewSize: newInstallationCrewSize
        )
        
        formErrors = validation.errors
        
        // Additional validation for job selection
        if newInstallationJobId == nil {
            formErrors.append(ValidationService.ValidationError(
                field: "job",
                message: "Please select a job for this installation",
                code: .required
            ))
        }
        
        return formErrors.isEmpty
    }
    
    func hasErrorForField(_ field: String) -> Bool {
        validationService.hasErrorForField(field, in: formErrors)
    }
    
    func getErrorsForField(_ field: String) -> [ValidationService.ValidationError] {
        validationService.getErrorsForField(field, from: formErrors)
    }
    
    // MARK: - Navigation
    
    func showInstallationDetail(_ installation: Installation) {
        selectedInstallation = installation
        showingInstallationDetail = true
    }
    
    func showAddInstallation() {
        resetForm()
        showingAddInstallation = true
    }
    
    // MARK: - Analytics
    
    func getInstallationStatistics() -> InstallationStatistics {
        let totalInstallations = installations.count
        let scheduledInstallations = installations.filter { $0.status == .scheduled }.count
        let inProgressInstallations = installations.filter { $0.status == .inProgress }.count
        let completedInstallations = installations.filter { $0.status == .completed }.count
        let cancelledInstallations = installations.filter { $0.status == .cancelled }.count
        let overdueInstallations = installations.filter { $0.isOverdue }.count
        
        let completionRate = totalInstallations > 0 ? Double(completedInstallations) / Double(totalInstallations) : 0
        
        return InstallationStatistics(
            totalInstallations: totalInstallations,
            scheduledInstallations: scheduledInstallations,
            inProgressInstallations: inProgressInstallations,
            completedInstallations: completedInstallations,
            cancelledInstallations: cancelledInstallations,
            overdueInstallations: overdueInstallations,
            completionRate: completionRate
        )
    }
    
    func getInstallationsByStatus() -> [String: Int] {
        var installationsByStatus: [String: Int] = [:]
        
        for status in InstallationStatus.allCases {
            installationsByStatus[status.rawValue] = installations.filter { $0.status == status }.count
        }
        
        return installationsByStatus
    }
    
    func getUpcomingInstallations() -> [Installation] {
        let now = Date()
        return installations.filter { installation in
            installation.scheduledDate > now && installation.status == .scheduled
        }.sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    func getOverdueInstallations() -> [Installation] {
        return installations.filter { $0.isOverdue }
    }
    
    func getTodaysInstallations() -> [Installation] {
        return getInstallations(for: Date())
    }
    
    func getThisWeeksInstallations() -> [Installation] {
        let calendar = Calendar.current
        let now = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return []
        }
        
        return getInstallationsInRange(from: weekInterval.start, to: weekInterval.end)
    }
    
    // MARK: - Business Logic
    
    func canScheduleInstallation(for job: SolarJob) -> Bool {
        // Check if job has any existing installations
        let existingInstallations = installations.filter { $0.job?.id == job.id }
        
        // Don't allow scheduling if there's already a scheduled or in-progress installation
        return !existingInstallations.contains { installation in
            installation.status == .scheduled || installation.status == .inProgress
        }
    }
    
    func getAvailableJobs() -> [SolarJob] {
        return jobs.filter { job in
            // Include pending and approved jobs that can be scheduled
            (job.status == .pending || job.status == .approved) && canScheduleInstallation(for: job)
        }
    }
    
    func getCrewUtilization() -> Double {
        let totalCrewDays = installations.filter { $0.status == .scheduled || $0.status == .inProgress }
            .reduce(0) { total, installation in 
                // Parse crew size from crewMembers string, default to 2
                let crewSize = installation.crewMembers.split(separator: ",").count
                return total + max(crewSize, 1)
            }
        
        // This would be calculated against available crew in production
        let availableCrewDays = 10 // Assume 10 crew members available
        
        return totalCrewDays > 0 ? Double(totalCrewDays) / Double(availableCrewDays) : 0
    }
    
    func getAverageInstallationDuration() -> TimeInterval {
        let completedInstallations = installations.filter { $0.status == .completed }
        guard !completedInstallations.isEmpty else { return 0 }
        
        let totalDuration = completedInstallations.reduce(0.0) { total, installation in 
            return total + (installation.duration ?? 8.0 * 3600) // Use actual duration or default 8 hours
        }
        return totalDuration / Double(completedInstallations.count)
    }
}

// MARK: - Supporting Types

enum DateRange: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case nextWeek = "Next Week"
    case nextMonth = "Next Month"
}

enum CalendarDisplayMode {
    case month
    case week
    case day
}

struct InstallationStatistics {
    let totalInstallations: Int
    let scheduledInstallations: Int
    let inProgressInstallations: Int
    let completedInstallations: Int
    let cancelledInstallations: Int
    let overdueInstallations: Int
    let completionRate: Double
}