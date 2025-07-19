import Foundation
import SwiftData

@Model
final class SolarJob {
    var id = UUID()
    var customerName: String
    var address: String
    var systemSize: Double
    var status: JobStatus
    var createdDate: Date
    var scheduledDate: Date?
    var estimatedRevenue: Double
    var notes: String
    
    // Relationships
    @Relationship(deleteRule: .cascade) var installations: [Installation] = []
    @Relationship var customer: Customer?
    @Relationship var contracts: [Contract] = []
    
    init(
        customerName: String,
        address: String,
        systemSize: Double,
        status: JobStatus = .pending,
        scheduledDate: Date? = nil,
        estimatedRevenue: Double = 0.0,
        notes: String = ""
    ) {
        self.customerName = customerName
        self.address = address
        self.systemSize = systemSize
        self.status = status
        self.createdDate = Date()
        self.scheduledDate = scheduledDate
        self.estimatedRevenue = estimatedRevenue
        self.notes = notes
    }
}

// MARK: - Job Status Enum
enum JobStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case approved = "Approved" 
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case onHold = "On Hold"
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .approved: return "blue"
        case .inProgress: return "purple"
        case .completed: return "green"
        case .cancelled: return "red"
        case .onHold: return "gray"
        }
    }
}