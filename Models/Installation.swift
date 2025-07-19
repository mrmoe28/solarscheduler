import Foundation
import SwiftData

@Model
final class Installation {
    var id = UUID()
    var scheduledDate: Date
    var status: InstallationStatus
    var crewMembers: String
    var notes: String
    var createdDate: Date
    var startTime: Date?
    var endTime: Date?
    var weatherConditions: String
    var completionPercentage: Int
    var qualityCheckPassed: Bool
    
    // Relationships
    @Relationship var job: SolarJob?
    @Relationship var assignedVendor: Vendor?
    
    // Computed properties
    var duration: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }
    
    var isOverdue: Bool {
        status != .completed && Date() > scheduledDate
    }
    
    init(
        scheduledDate: Date,
        status: InstallationStatus = .scheduled,
        crewMembers: String = "",
        notes: String = "",
        weatherConditions: String = "",
        completionPercentage: Int = 0
    ) {
        self.scheduledDate = scheduledDate
        self.status = status
        self.crewMembers = crewMembers
        self.notes = notes
        self.createdDate = Date()
        self.weatherConditions = weatherConditions
        self.completionPercentage = completionPercentage
        self.qualityCheckPassed = false
    }
    
    func markAsStarted() {
        status = .inProgress
        startTime = Date()
    }
    
    func markAsCompleted() {
        status = .completed
        endTime = Date()
        completionPercentage = 100
    }
    
    func updateProgress(_ percentage: Int) {
        completionPercentage = min(100, max(0, percentage))
        if completionPercentage == 100 && status == .inProgress {
            markAsCompleted()
        }
    }
}

// MARK: - Installation Status Enum
enum InstallationStatus: String, CaseIterable, Codable {
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case completed = "Completed"
    case postponed = "Postponed"
    case cancelled = "Cancelled"
    case onHold = "On Hold"
    
    var color: String {
        switch self {
        case .scheduled: return "blue"
        case .inProgress: return "orange"
        case .completed: return "green"
        case .postponed: return "yellow"
        case .cancelled: return "red"
        case .onHold: return "gray"
        }
    }
    
    var icon: String {
        switch self {
        case .scheduled: return "calendar"
        case .inProgress: return "hammer"
        case .completed: return "checkmark.circle"
        case .postponed: return "clock"
        case .cancelled: return "xmark.circle"
        case .onHold: return "pause.circle"
        }
    }
}