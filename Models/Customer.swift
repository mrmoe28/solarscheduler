import Foundation
import SwiftData

@Model
final class Customer {
    var id = UUID()
    var name: String
    var email: String
    var phone: String
    var address: String
    var leadStatus: LeadStatus
    var createdDate: Date
    var lastContactDate: Date?
    var notes: String
    var preferredContactMethod: ContactMethod
    
    // Relationships
    @Relationship(deleteRule: .cascade) var jobs: [SolarJob] = []
    @Relationship(deleteRule: .cascade) var contracts: [Contract] = []
    
    init(
        name: String,
        email: String,
        phone: String,
        address: String,
        leadStatus: LeadStatus = .newLead,
        notes: String = "",
        preferredContactMethod: ContactMethod = .email
    ) {
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.leadStatus = leadStatus
        self.createdDate = Date()
        self.notes = notes
        self.preferredContactMethod = preferredContactMethod
    }
}

// MARK: - Lead Status Enum
enum LeadStatus: String, CaseIterable, Codable {
    case newLead = "New Lead"
    case contacted = "Contacted"
    case qualified = "Qualified"
    case proposal = "Proposal Sent"
    case negotiation = "Negotiation"
    case won = "Won"
    case lost = "Lost"
    
    var color: String {
        switch self {
        case .newLead: return "blue"
        case .contacted: return "orange"
        case .qualified: return "yellow"
        case .proposal: return "purple"
        case .negotiation: return "indigo"
        case .won: return "green"
        case .lost: return "red"
        }
    }
}

// MARK: - Contact Method Enum
enum ContactMethod: String, CaseIterable, Codable {
    case email = "Email"
    case phone = "Phone"
    case text = "Text"
    case inPerson = "In Person"
}

// MARK: - Custom Identifiable Extension for SwiftUI Updates
extension Customer: Identifiable {
    // Custom ID that includes key properties to ensure SwiftUI updates
    public var customId: String {
        "\(id.uuidString)_\(name)_\(email)_\(leadStatus.rawValue)_\(createdDate.timeIntervalSince1970)"
    }
}