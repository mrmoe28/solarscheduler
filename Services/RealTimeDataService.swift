import SwiftUI
import Combine
import Foundation

// MARK: - Real-Time Data Service

class RealTimeDataService: ObservableObject {
    @Published var isConnected = false
    @Published var lastUpdateTime = Date()
    @Published var dataQuality: DataQuality = .good
    @Published var systemStatus: SystemStatus = .normal
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    enum DataQuality: String, CaseIterable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .poor: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .excellent: return "wifi"
            case .good: return "wifi"
            case .fair: return "wifi.exclamationmark"
            case .poor: return "wifi.slash"
            }
        }
    }
    
    enum SystemStatus: String, CaseIterable {
        case normal = "Normal"
        case maintenance = "Maintenance"
        case warning = "Warning"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .normal: return .green
            case .maintenance: return .blue
            case .warning: return .orange
            case .critical: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .normal: return "checkmark.circle.fill"
            case .maintenance: return "wrench.and.screwdriver.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "xmark.circle.fill"
            }
        }
    }
    
    init() {
        startRealTimeUpdates()
    }
    
    deinit {
        stopRealTimeUpdates()
    }
    
    private func startRealTimeUpdates() {
        // Simulate connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isConnected = true
        }
        
        // Update every 5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.updateData()
        }
    }
    
    private func stopRealTimeUpdates() {
        timer?.invalidate()
        timer = nil
        isConnected = false
    }
    
    private func updateData() {
        lastUpdateTime = Date()
        
        // Simulate varying data quality
        let qualityOptions: [DataQuality] = [.excellent, .good, .fair]
        dataQuality = qualityOptions.randomElement() ?? .good
        
        // Simulate system status changes
        let statusOptions: [SystemStatus] = [.normal, .normal, .normal, .maintenance, .warning]
        systemStatus = statusOptions.randomElement() ?? .normal
    }
    
    func forceRefresh() {
        updateData()
    }
}

// MARK: - Performance Metrics Service

class PerformanceMetricsService: ObservableObject {
    @Published var energyProduction: Double = 0.0
    @Published var efficiency: Double = 0.0
    @Published var dailyGoal: Double = 100.0
    @Published var weeklyTrend: [Double] = []
    
    private var timer: Timer?
    
    init() {
        generateMockData()
        startPerformanceUpdates()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func startPerformanceUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            self.updatePerformanceData()
        }
    }
    
    private func generateMockData() {
        // Generate realistic solar panel performance data
        let baseProduction = Double.random(in: 75...95)
        energyProduction = baseProduction
        efficiency = baseProduction / 100.0
        
        // Generate weekly trend data (7 days)
        weeklyTrend = (0..<7).map { _ in
            Double.random(in: 70...100)
        }
    }
    
    private func updatePerformanceData() {
        // Simulate fluctuating energy production
        let variance = Double.random(in: -5...5)
        energyProduction = max(0, min(100, energyProduction + variance))
        efficiency = energyProduction / 100.0
        
        // Update weekly trend (add new data, remove old)
        if weeklyTrend.count >= 7 {
            weeklyTrend.removeFirst()
        }
        weeklyTrend.append(energyProduction)
    }
}

// MARK: - Enhanced Notification Service

class EnhancedNotificationService: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    
    struct AppNotification: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let message: String
        let type: NotificationType
        let timestamp: Date
        var isRead: Bool = false
        
        enum NotificationType {
            case info, success, warning, error
            
            var color: Color {
                switch self {
                case .info: return .blue
                case .success: return .green
                case .warning: return .orange
                case .error: return .red
                }
            }
            
            var icon: String {
                switch self {
                case .info: return "info.circle.fill"
                case .success: return "checkmark.circle.fill"
                case .warning: return "exclamationmark.triangle.fill"
                case .error: return "xmark.circle.fill"
                }
            }
        }
    }
    
    init() {
        generateSampleNotifications()
    }
    
    private func generateSampleNotifications() {
        let sampleNotifications = [
            AppNotification(
                title: "System Online",
                message: "Solar panel system successfully connected",
                type: .success,
                timestamp: Date().addingTimeInterval(-300)
            ),
            AppNotification(
                title: "Performance Alert",
                message: "Energy production is 15% below average",
                type: .warning,
                timestamp: Date().addingTimeInterval(-600)
            ),
            AppNotification(
                title: "Maintenance Reminder",
                message: "Scheduled maintenance due in 3 days",
                type: .info,
                timestamp: Date().addingTimeInterval(-1200)
            )
        ]
        
        notifications = sampleNotifications
        updateUnreadCount()
    }
    
    func addNotification(title: String, message: String, type: AppNotification.NotificationType) {
        let notification = AppNotification(
            title: title,
            message: message,
            type: type,
            timestamp: Date()
        )
        notifications.insert(notification, at: 0)
        updateUnreadCount()
    }
    
    func markAsRead(notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            updateUnreadCount()
        }
    }
    
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        updateUnreadCount()
    }
    
    func clearNotifications() {
        notifications.removeAll()
        updateUnreadCount()
    }
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
}

// MARK: - App Analytics Service

class AppAnalyticsService: ObservableObject {
    @Published var sessionDuration: TimeInterval = 0
    @Published var screenViews: [String: Int] = [:]
    @Published var userActions: [String: Int] = [:]
    
    private var sessionStartTime = Date()
    private var timer: Timer?
    
    init() {
        startSession()
    }
    
    deinit {
        endSession()
    }
    
    private func startSession() {
        sessionStartTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.sessionDuration = Date().timeIntervalSince(self.sessionStartTime)
        }
    }
    
    private func endSession() {
        timer?.invalidate()
        timer = nil
    }
    
    func trackScreenView(_ screenName: String) {
        screenViews[screenName, default: 0] += 1
    }
    
    func trackUserAction(_ action: String) {
        userActions[action, default: 0] += 1
    }
    
    func getTopScreens() -> [(String, Int)] {
        screenViews.sorted { $0.value > $1.value }
    }
    
    func getTopActions() -> [(String, Int)] {
        userActions.sorted { $0.value > $1.value }
    }
}