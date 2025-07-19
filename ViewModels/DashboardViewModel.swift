import Foundation
import SwiftData
import SwiftUI

enum TimeFilter: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case thisYear = "This Year"
}

@Observable
class DashboardViewModel {
    private let dataService: DataService
    private let notificationService: NotificationService
    
    // Dashboard metrics
    var totalJobs: Int = 0
    var activeJobs: Int = 0
    var completedJobs: Int = 0
    var totalRevenue: Double = 0
    var pendingRevenue: Double = 0
    var totalCustomers: Int = 0
    var lowStockItemsCount: Int = 0
    
    // Recent activity
    var recentJobs: [SolarJob] = []
    var upcomingInstallations: [Installation] = []
    var lowStockEquipment: [Equipment] = []
    
    // UI State
    var isLoading = false
    var errorMessage: String?
    var alerts: [DashboardAlert] = []
    var currentTimeFilter: TimeFilter = .today
    
    init(dataService: DataService, notificationService: NotificationService = .shared) {
        self.dataService = dataService
        self.notificationService = notificationService
        refreshData()
    }
    
    func refreshData() {
        Task { @MainActor in
            isLoading = true
            errorMessage = nil
            
            do {
                // Get comprehensive statistics
                let jobStats = try dataService.getJobStatistics()
                let equipmentStats = try dataService.getEquipmentStatistics()
                
                // Update metrics
                totalJobs = jobStats.totalJobs
                activeJobs = jobStats.activeJobs
                completedJobs = jobStats.completedJobs
                totalRevenue = jobStats.totalRevenue
                pendingRevenue = jobStats.pendingRevenue
                totalCustomers = try dataService.fetchCustomers().count
                lowStockItemsCount = equipmentStats.lowStockCount
                
                // Update recent activity
                recentJobs = try dataService.fetchJobs(limit: 5)
                upcomingInstallations = try dataService.fetchInstallations(
                    startDate: Date(),
                    sortBy: .scheduledDate,
                    ascending: true
                )
                lowStockEquipment = equipmentStats.lowStockItems
                
                // Update alerts
                updateAlerts()
                
                // Send notifications for critical items
                if !lowStockEquipment.isEmpty {
                    notificationService.notifyLowStockItems(lowStockEquipment)
                }
                
                let overdueInstallations = upcomingInstallations.filter { $0.isOverdue }
                if !overdueInstallations.isEmpty {
                    notificationService.notifyOverdueInstallations(overdueInstallations)
                }
                
            } catch {
                errorMessage = "Failed to refresh data: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
            
            isLoading = false
        }
    }
    
    private func updateAlerts() {
        alerts.removeAll()
        
        // Low stock alerts
        if lowStockItemsCount > 0 {
            alerts.append(DashboardAlert(
                type: .lowStock,
                title: "Low Stock Alert",
                message: "\(lowStockItemsCount) items are running low",
                priority: .high
            ))
        }
        
        // Overdue installations
        let overdueInstallations = upcomingInstallations.filter { $0.isOverdue }
        if !overdueInstallations.isEmpty {
            alerts.append(DashboardAlert(
                type: .overdueInstallation,
                title: "Overdue Installations",
                message: "\(overdueInstallations.count) installations are overdue",
                priority: .high
            ))
        }
        
        // Revenue milestone alerts
        if totalRevenue > 100000 {
            alerts.append(DashboardAlert(
                type: .milestone,
                title: "Revenue Milestone",
                message: "Congratulations! You've reached $\(totalRevenue.safeValue, specifier: "%.0f") in revenue",
                priority: .medium
            ))
        }
    }
    
    // MARK: - Business Logic Methods
    
    func getJobsCompletionRate() -> Double {
        guard totalJobs > 0 else { return 0.0 }
        let rate = Double(completedJobs) / Double(totalJobs)
        return rate.isNaN || rate.isInfinite ? 0.0 : rate
    }
    
    func getRevenueGrowthTrend() -> Double {
        // Simplified calculation - would implement proper date-based growth in production
        let currentMonth = totalRevenue
        let lastMonth = totalRevenue * 0.85 // Placeholder
        
        guard lastMonth > 0 else { return 0.0 }
        let trend = (currentMonth - lastMonth) / lastMonth
        return trend.isNaN || trend.isInfinite ? 0.0 : trend
    }
    
    func getCriticalAlerts() -> [DashboardAlert] {
        return alerts.filter { $0.priority == .high }
    }
    
    func getAverageJobValue() -> Double {
        guard totalJobs > 0 else { return 0.0 }
        let average = (totalRevenue + pendingRevenue) / Double(totalJobs)
        return average.isNaN || average.isInfinite ? 0.0 : average
    }
    
    func getMonthlyRevenue() -> Double {
        // This would be calculated based on actual date ranges in production
        let monthly = totalRevenue / 12.0 // Simplified
        return monthly.isNaN || monthly.isInfinite ? 0.0 : monthly
    }
    
    func getEquipmentUtilization() -> Double {
        let totalEquipmentValue = lowStockEquipment.reduce(0) { $0 + $1.totalValue }
        guard totalEquipmentValue > 0 else { return 0.0 }
        let utilization = (totalRevenue / totalEquipmentValue) * 100
        return utilization.isNaN || utilization.isInfinite ? 0.0 : utilization
    }
    
    // MARK: - Action Methods
    
    func markJobAsCompleted(_ job: SolarJob) {
        Task {
            do {
                try dataService.updateJobStatus(job, to: .completed)
                notificationService.notifyJobCompleted(job)
                refreshData()
            } catch {
                errorMessage = "Failed to update job status: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    func reorderEquipment(_ equipment: Equipment) {
        // This would integrate with a purchasing system in production
        notificationService.showInAppNotification(
            AppNotification(
                title: "Reorder Initiated",
                message: "Reorder request for \(equipment.name) has been logged",
                type: .info
            )
        )
    }
    
    func dismissAlert(_ alert: DashboardAlert) {
        alerts.removeAll { $0.id == alert.id }
    }
    
    func updateTimeFilter(_ filter: TimeFilter) {
        currentTimeFilter = filter
        refreshData()
    }
    
    private func getDateRange(for filter: TimeFilter) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch filter {
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
        case .thisYear:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let endOfYear = calendar.dateInterval(of: .year, for: now)?.end ?? now
            return (startOfYear, endOfYear)
        }
    }
}

// MARK: - Supporting Types

struct DashboardAlert: Identifiable {
    let id = UUID()
    let type: AlertType
    let title: String
    let message: String
    let priority: Priority
    let timestamp: Date
    
    init(type: AlertType, title: String, message: String, priority: Priority) {
        self.type = type
        self.title = title
        self.message = message
        self.priority = priority
        self.timestamp = Date()
    }
    
    enum AlertType {
        case lowStock
        case overdueInstallation
        case newLead
        case paymentDue
        case milestone
        case systemError
    }
    
    enum Priority {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .orange
            case .high: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "info.circle"
            case .medium: return "exclamationmark.triangle"
            case .high: return "exclamationmark.octagon"
            }
        }
    }
}