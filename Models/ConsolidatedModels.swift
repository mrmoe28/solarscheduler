import Foundation
import SwiftData
import CryptoKit
import SwiftUI

// MARK: - User Model
@Model
final class User {
    var id = UUID()
    var email: String
    var fullName: String
    var companyName: String?
    var phoneNumber: String?
    var profileImageData: Data?
    var passwordHash: String
    var createdDate: Date
    var lastSignInDate: Date?
    var isActive: Bool
    
    // Relationships
    @Relationship(deleteRule: .cascade) var jobs: [SolarJob] = []
    @Relationship(deleteRule: .cascade) var customers: [Customer] = []
    @Relationship(deleteRule: .cascade) var installations: [Installation] = []
    @Relationship(deleteRule: .cascade) var equipment: [Equipment] = []
    @Relationship(deleteRule: .cascade) var vendors: [Vendor] = []
    @Relationship(deleteRule: .cascade) var contracts: [Contract] = []
    
    init(
        email: String,
        fullName: String,
        passwordHash: String,
        companyName: String = ""
    ) {
        self.email = email
        self.fullName = fullName
        self.passwordHash = passwordHash
        self.companyName = companyName
        self.createdDate = Date()
        self.isActive = true
    }
    
    // Verify password by comparing hashes
    func verifyPassword(_ password: String) -> Bool {
        let inputData = Data(password.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.map { byte in
            String(format: "%02x", byte)
        }.joined()
        return hashString == self.passwordHash
    }
}

// MARK: - SolarJob Model
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
    
    // Site Visit properties
    var siteVisitDate: Date?
    var siteVisitNotes: String?
    var sitePhotos: [Data]?
    
    // Relationships
    @Relationship(deleteRule: .cascade) var installations: [Installation] = []
    @Relationship var customer: Customer?
    @Relationship var contracts: [Contract] = []
    @Relationship var user: User?
    
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
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .blue
        case .inProgress: return .purple
        case .completed: return .green
        case .cancelled: return .red
        case .onHold: return .gray
        }
    }
}

// MARK: - Customer Model
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
    @Relationship var user: User?
    
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
    
    var color: Color {
        switch self {
        case .newLead: return .blue
        case .contacted: return .orange
        case .qualified: return .yellow
        case .proposal: return .purple
        case .negotiation: return .indigo
        case .won: return .green
        case .lost: return .red
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

// MARK: - Equipment Model
@Model
final class Equipment {
    var id = UUID()
    var name: String
    var category: EquipmentCategory
    var brand: String
    var model: String
    var manufacturer: String
    var quantity: Int
    var unitPrice: Double
    var unitCost: Double
    var equipmentDescription: String
    var imageData: Data?
    var lowStockThreshold: Int
    var minimumStock: Int
    var createdDate: Date
    var lastUpdated: Date
    var isActive: Bool
    var warrantyPeriod: Int // in months
    var supplier: String
    
    // Relationships
    @Relationship var user: User?
    
    // Computed properties
    var isLowStock: Bool {
        quantity <= lowStockThreshold
    }
    
    var totalValue: Double {
        let calculatedValue = Double(quantity) * unitPrice
        return calculatedValue.safeValue
    }
    
    init(
        name: String,
        category: EquipmentCategory,
        brand: String,
        model: String,
        manufacturer: String = "",
        quantity: Int,
        unitPrice: Double,
        unitCost: Double? = nil,
        equipmentDescription: String = "",
        imageData: Data? = nil,
        lowStockThreshold: Int = 5,
        minimumStock: Int? = nil,
        warrantyPeriod: Int = 12,
        supplier: String = ""
    ) {
        self.name = name
        self.category = category
        self.brand = brand
        self.model = model
        self.manufacturer = manufacturer
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.unitCost = unitCost ?? unitPrice
        self.equipmentDescription = equipmentDescription
        self.imageData = imageData
        self.lowStockThreshold = lowStockThreshold
        self.minimumStock = minimumStock ?? lowStockThreshold
        self.createdDate = Date()
        self.lastUpdated = Date()
        self.isActive = true
        self.warrantyPeriod = warrantyPeriod
        self.supplier = supplier
    }
    
    func updateQuantity(_ newQuantity: Int) {
        quantity = newQuantity
        lastUpdated = Date()
    }
    
    func adjustStock(by amount: Int) {
        quantity = max(0, quantity + amount)
        lastUpdated = Date()
    }
}

// MARK: - Equipment Category Enum
enum EquipmentCategory: String, CaseIterable, Codable {
    case solarPanels = "Solar Panels"
    case inverters = "Inverters"
    case mounting = "Mounting Systems"
    case electrical = "Electrical Components"
    case batteries = "Battery Storage"
    case monitoring = "Monitoring Systems"
    case tools = "Installation Tools"
    case safety = "Safety Equipment"
    
    var icon: String {
        switch self {
        case .solarPanels: return "rectangle.3.group"
        case .inverters: return "cpu"
        case .mounting: return "hammer"
        case .electrical: return "bolt"
        case .batteries: return "battery.100"
        case .monitoring: return "chart.line.uptrend.xyaxis"
        case .tools: return "wrench.and.screwdriver"
        case .safety: return "shield"
        }
    }
}

// MARK: - Vendor Model
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
    
    var shareText: String {
        """
        Contractor: \(name)
        Email: \(contactEmail)
        Phone: \(contactPhone)
        Address: \(address)
        Specialties: \(specialtiesString)
        Rating: \(rating)/5.0
        License: \(licenseNumber.isEmpty ? "N/A" : licenseNumber)
        """
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

// MARK: - Installation Model
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
    var estimatedDuration: TimeInterval
    var weatherConditions: String
    var completionPercentage: Int
    var qualityCheckPassed: Bool
    
    // Relationships
    @Relationship var job: SolarJob?
    @Relationship var assignedVendor: Vendor?
    @Relationship var user: User?
    
    // Computed properties
    var duration: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }
    
    var isOverdue: Bool {
        status != .completed && Date() > scheduledDate
    }
    
    var crewSize: Int {
        // Parse crew size from crewMembers string (e.g., "Crew 3" -> 3)
        let components = crewMembers.split(separator: " ")
        if let lastComponent = components.last, let size = Int(lastComponent) {
            return size
        }
        // Fallback: count commas in crew member names + 1
        return crewMembers.split(separator: ",").count
    }
    
    init(
        scheduledDate: Date,
        status: InstallationStatus = .scheduled,
        crewMembers: String = "",
        notes: String = "",
        estimatedDuration: TimeInterval = 8 * 3600, // Default 8 hours
        weatherConditions: String = "",
        completionPercentage: Int = 0
    ) {
        self.scheduledDate = scheduledDate
        self.status = status
        self.crewMembers = crewMembers
        self.notes = notes
        self.createdDate = Date()
        self.estimatedDuration = estimatedDuration
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

// MARK: - Contract Model
@Model
final class Contract {
    var id = UUID()
    var contractNumber: String
    var title: String
    var contractDescription: String
    var totalAmount: Double
    var paidAmount: Double
    var status: ContractStatus
    var signedDate: Date?
    var startDate: Date?
    var completionDate: Date?
    var createdDate: Date
    var terms: String
    var paymentSchedule: String
    var documentData: Data?
    var isActive: Bool
    
    // Relationships
    @Relationship var customer: Customer?
    @Relationship var job: SolarJob?
    
    // Computed properties
    var remainingAmount: Double {
        totalAmount - paidAmount
    }
    
    var paymentProgress: Double {
        guard totalAmount > 0 else { return 0 }
        return paidAmount / totalAmount
    }
    
    var isOverdue: Bool {
        guard let completion = completionDate else { return false }
        return status != .completed && Date() > completion
    }
    
    var daysUntilCompletion: Int? {
        guard let completion = completionDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: completion).day
    }
    
    init(
        contractNumber: String,
        title: String,
        contractDescription: String = "",
        totalAmount: Double,
        status: ContractStatus = .draft,
        terms: String = "",
        paymentSchedule: String = ""
    ) {
        self.contractNumber = contractNumber
        self.title = title
        self.contractDescription = contractDescription
        self.totalAmount = totalAmount
        self.paidAmount = 0.0
        self.status = status
        self.createdDate = Date()
        self.terms = terms
        self.paymentSchedule = paymentSchedule
        self.isActive = true
    }
    
    func addPayment(_ amount: Double) {
        paidAmount = min(totalAmount, paidAmount + amount)
        if paidAmount >= totalAmount {
            status = .completed
        }
    }
    
    func sign() {
        status = .signed
        signedDate = Date()
    }
    
    func activate() {
        guard status == .signed else { return }
        status = .active
        startDate = Date()
    }
    
    func complete() {
        status = .completed
        completionDate = Date()
    }
    
    func cancel() {
        status = .cancelled
        isActive = false
    }
}

// MARK: - Contract Status Enum
enum ContractStatus: String, CaseIterable, Codable {
    case draft = "Draft"
    case pendingSignature = "Pending Signature"
    case signed = "Signed"
    case active = "Active"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case onHold = "On Hold"
    
    var color: String {
        switch self {
        case .draft: return "gray"
        case .pendingSignature: return "orange"
        case .signed: return "blue"
        case .active: return "purple"
        case .completed: return "green"
        case .cancelled: return "red"
        case .onHold: return "yellow"
        }
    }
    
    var icon: String {
        switch self {
        case .draft: return "doc"
        case .pendingSignature: return "signature"
        case .signed: return "doc.text"
        case .active: return "play.circle"
        case .completed: return "checkmark.circle"
        case .cancelled: return "xmark.circle"
        case .onHold: return "pause.circle"
        }
    }
}