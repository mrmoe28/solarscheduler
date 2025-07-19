import Foundation
import SwiftData

@Model
final class Vendor {
    var id = UUID()
    var name: String
    var contactEmail: String
    var contactPhone: String
    var address: String
    var specialties: [VendorSpecialty]
    var createdDate: Date
    var isActive: Bool
    var rating: Double
    var notes: String
    var website: String
    var emergencyContact: String
    var insuranceDetails: String
    var licenseNumber: String
    
    // Relationships
    @Relationship(deleteRule: .nullify) var installations: [Installation] = []
    
    // Computed properties
    var specialtiesString: String {
        specialties.map { $0.rawValue }.joined(separator: ", ")
    }
    
    var completedInstallations: Int {
        installations.filter { $0.status == .completed }.count
    }
    
    init(
        name: String,
        contactEmail: String,
        contactPhone: String,
        address: String,
        specialties: [VendorSpecialty] = [],
        rating: Double = 0.0,
        notes: String = "",
        website: String = "",
        emergencyContact: String = "",
        insuranceDetails: String = "",
        licenseNumber: String = ""
    ) {
        self.name = name
        self.contactEmail = contactEmail
        self.contactPhone = contactPhone
        self.address = address
        self.specialties = specialties
        self.createdDate = Date()
        self.isActive = true
        self.rating = rating
        self.notes = notes
        self.website = website
        self.emergencyContact = emergencyContact
        self.insuranceDetails = insuranceDetails
        self.licenseNumber = licenseNumber
    }
    
    func updateRating(_ newRating: Double) {
        rating = max(0.0, min(5.0, newRating))
    }
    
    func addSpecialty(_ specialty: VendorSpecialty) {
        if !specialties.contains(specialty) {
            specialties.append(specialty)
        }
    }
    
    func removeSpecialty(_ specialty: VendorSpecialty) {
        specialties.removeAll { $0 == specialty }
    }
}

// MARK: - Vendor Specialty Enum
enum VendorSpecialty: String, CaseIterable, Codable {
    case installation = "Installation"
    case maintenance = "Maintenance"
    case electrical = "Electrical Work"
    case roofing = "Roofing"
    case permitting = "Permitting"
    case inspection = "Inspection"
    case cleanup = "Site Cleanup"
    case emergency = "Emergency Repairs"
    
    var icon: String {
        switch self {
        case .installation: return "hammer"
        case .maintenance: return "wrench"
        case .electrical: return "bolt"
        case .roofing: return "house"
        case .permitting: return "doc.text"
        case .inspection: return "checkmark.shield"
        case .cleanup: return "trash"
        case .emergency: return "exclamationmark.triangle"
        }
    }
}