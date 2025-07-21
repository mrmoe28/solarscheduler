import Foundation
import UserNotifications
import SwiftUI

// MARK: - Platform-specific imports
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@Observable
class NotificationService {
    static let shared = NotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var isAuthorized = false
    
    // In-app notifications
    var activeNotifications: [AppNotification] = []
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            isAuthorized = granted
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Local Notifications
    
    func scheduleInstallationReminder(
        for installation: Installation,
        hoursBeforeInstallation: Double = 24
    ) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Installation Reminder"
        content.body = "Installation scheduled for \(installation.scheduledDate.formatted(date: .abbreviated, time: .shortened))"
        content.sound = .default
        content.badge = 1
        
        let triggerDate = Calendar.current.date(
            byAdding: .hour,
            value: -Int(hoursBeforeInstallation),
            to: installation.scheduledDate
        ) ?? installation.scheduledDate
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "installation_\(installation.id)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func scheduleEquipmentLowStockAlert(for equipment: Equipment) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Low Stock Alert"
        content.body = "\(equipment.name) is running low. Only \(equipment.quantity) remaining."
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "lowstock_\(equipment.id)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling low stock notification: \(error)")
            }
        }
    }
    
    func scheduleJobStatusUpdate(for job: SolarJob, newStatus: JobStatus) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Job Status Update"
        content.body = "Job for \(job.customerName) is now \(newStatus.rawValue)"
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "jobstatus_\(job.id)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling job status notification: \(error)")
            }
        }
    }
    
    // MARK: - In-App Notifications
    
    func showInAppNotification(_ notification: AppNotification) {
        activeNotifications.append(notification)
        
        // Auto-dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + notification.duration) {
            self.dismissNotification(notification)
        }
    }
    
    func dismissNotification(_ notification: AppNotification) {
        activeNotifications.removeAll { $0.id == notification.id }
    }
    
    func dismissAllNotifications() {
        activeNotifications.removeAll()
    }
    
    // MARK: - Business Logic Notifications
    
    func notifyLowStockItems(_ items: [Equipment]) {
        for item in items {
            let notification = AppNotification(
                title: "Low Stock Alert",
                message: "\(item.name) is running low (\(item.quantity) remaining)",
                type: .warning,
                duration: 5.0,
                actionTitle: "Reorder",
                action: {
                    // Handle reorder action
                    print("Reorder \(item.name)")
                }
            )
            showInAppNotification(notification)
        }
    }
    
    func notifyOverdueInstallations(_ installations: [Installation]) {
        for installation in installations {
            let notification = AppNotification(
                title: "Overdue Installation",
                message: "Installation was scheduled for \(installation.scheduledDate.formatted(date: .abbreviated, time: .shortened))",
                type: .error,
                duration: 10.0,
                actionTitle: "Reschedule",
                action: {
                    // Handle reschedule action
                    print("Reschedule installation \(installation.id)")
                }
            )
            showInAppNotification(notification)
        }
    }
    
    func notifyJobStatusChange(_ job: SolarJob, from oldStatus: JobStatus, to newStatus: JobStatus) {
        let notification = AppNotification(
            title: "Job Status Updated",
            message: "\(job.customerName)'s job is now \(newStatus.rawValue)",
            type: .info,
            duration: 3.0
        )
        showInAppNotification(notification)
    }
    
    func notifyNewCustomer(_ customer: Customer) {
        let notification = AppNotification(
            title: "New Customer Added",
            message: "\(customer.name) has been added to your customer list",
            type: .success,
            duration: 3.0
        )
        showInAppNotification(notification)
    }
    
    func notifyJobCompleted(_ job: SolarJob) {
        let notification = AppNotification(
            title: "Job Completed",
            message: "\(job.customerName)'s installation is complete! Revenue: $\(String(format: "%.0f", job.estimatedRevenue.safeValue))",
            type: .success,
            duration: 5.0
        )
        showInAppNotification(notification)
    }
    
    func notifyValidationError(_ error: ValidationService.ValidationError) {
        let notification = AppNotification(
            title: "Validation Error",
            message: error.message,
            type: .error,
            duration: 4.0
        )
        showInAppNotification(notification)
    }
    
    func notifyValidationErrors(_ errors: [ValidationService.ValidationError]) {
        let errorMessages = errors.map { $0.message }.joined(separator: "\n")
        let notification = AppNotification(
            title: "Validation Errors",
            message: errorMessages,
            type: .error,
            duration: 6.0
        )
        showInAppNotification(notification)
    }
    
    func notifyDataSaveSuccess(_ message: String = "Data saved successfully") {
        let notification = AppNotification(
            title: "Success",
            message: message,
            type: .success,
            duration: 2.0
        )
        showInAppNotification(notification)
    }
    
    func notifyDataSaveError(_ error: Error) {
        let notification = AppNotification(
            title: "Save Error",
            message: "Failed to save data: \(error.localizedDescription)",
            type: .error,
            duration: 5.0
        )
        showInAppNotification(notification)
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount(_ count: Int) {
        guard isAuthorized else { return }
        
        notificationCenter.setBadgeCount(count) { error in
            if let error = error {
                print("Error updating badge count: \(error)")
            }
        }
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
    
    // MARK: - Notification Management
    
    func cancelNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
}

// MARK: - Supporting Types

struct AppNotification: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let type: NotificationType
    let duration: TimeInterval
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        message: String,
        type: NotificationType,
        duration: TimeInterval = 3.0,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.type = type
        self.duration = duration
        self.actionTitle = actionTitle
        self.action = action
    }
    
    static func == (lhs: AppNotification, rhs: AppNotification) -> Bool {
        lhs.id == rhs.id
    }
}

enum NotificationType {
    case info
    case success
    case warning
    case error
    
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
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        }
    }
}

// MARK: - In-App Notification View

struct InAppNotificationView: View {
    let notification: AppNotification
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: notification.type.icon)
                .foregroundColor(notification.type.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            if let actionTitle = notification.actionTitle {
                Button(actionTitle) {
                    notification.action?()
                    onDismiss()
                }
                .font(.caption)
                .buttonStyle(.borderedProminent)
            }
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.secondarySystemBackground)
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.horizontal)
    }
}

// MARK: - Notification Overlay

struct NotificationOverlay: View {
    @State private var notificationService = NotificationService.shared
    
    var body: some View {
        VStack {
            ForEach(notificationService.activeNotifications) { notification in
                InAppNotificationView(notification: notification) {
                    notificationService.dismissNotification(notification)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: notificationService.activeNotifications)
    }
}