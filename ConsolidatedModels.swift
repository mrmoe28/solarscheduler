import Foundation
import SwiftData

// MARK: - Extensions
extension Double {
    var safeValue: Double {
        return self.isFinite ? self : 0.0
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

// MARK: - Equipment Model
@Model
final class Equipment {
    var id = UUID()
    var name: String
    var category: EquipmentCategory
    var brand: String
    var model: String
    var quantity: Int
    var unitPrice: Double
    var equipmentDescription: String
    var imageData: Data?
    var lowStockThreshold: Int
    var createdDate: Date
    var isActive: Bool
    var lastRestockedDate: Date?
    var supplier: String
    var warrantyMonths: Int
    
    // Computed properties
    var totalValue: Double {
        return (unitPrice.safeValue * Double(quantity))
    }
    
    var isLowStock: Bool {
        return quantity <= lowStockThreshold
    }
    
    var isOutOfStock: Bool {
        return quantity <= 0
    }
    
    var stockStatus: String {
        if isOutOfStock {
            return "Out of Stock"
        } else if isLowStock {
            return "Low Stock"
        } else {
            return "In Stock"
        }
    }
    
    var stockStatusColor: String {
        if isOutOfStock {
            return "red"
        } else if isLowStock {
            return "orange"
        } else {
            return "green"
        }
    }
    
    init(
        name: String,
        category: EquipmentCategory,
        brand: String,
        model: String,
        quantity: Int,
        unitPrice: Double,
        equipmentDescription: String = "",
        imageData: Data? = nil,
        lowStockThreshold: Int = 5,
        supplier: String = "",
        warrantyMonths: Int = 12
    ) {
        self.name = name
        self.category = category
        self.brand = brand
        self.model = model
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.equipmentDescription = equipmentDescription
        self.imageData = imageData
        self.lowStockThreshold = lowStockThreshold
        self.createdDate = Date()
        self.isActive = true
        self.supplier = supplier
        self.warrantyMonths = warrantyMonths
    }
    
    func updateStock(_ newQuantity: Int) {
        self.quantity = max(0, newQuantity)
        if newQuantity > quantity {
            self.lastRestockedDate = Date()
        }
    }
    
    func addStock(_ amount: Int) {
        updateStock(quantity + amount)
    }
    
    func removeStock(_ amount: Int) {
        updateStock(quantity - amount)
    }
}

// MARK: - Equipment Category Enum
enum EquipmentCategory: String, CaseIterable, Codable {
    case solarPanels = "Solar Panels"
    case inverters = "Inverters"
    case batteries = "Batteries"
    case mounting = "Mounting Systems"
    case wiring = "Wiring & Electrical"
    case monitoring = "Monitoring Systems"
    case tools = "Tools & Equipment"
    case safety = "Safety Equipment"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .solarPanels: return "sun.max"
        case .inverters: return "bolt.circle"
        case .batteries: return "battery.100"
        case .mounting: return "wrench"
        case .wiring: return "cable.connector"
        case .monitoring: return "chart.line.uptrend.xyaxis"
        case .tools: return "hammer"
        case .safety: return "shield"
        case .other: return "questionmark.circle"
        }
    }
    
    var color: String {
        switch self {
        case .solarPanels: return "yellow"
        case .inverters: return "blue"
        case .batteries: return "green"
        case .mounting: return "gray"
        case .wiring: return "orange"
        case .monitoring: return "purple"
        case .tools: return "brown"
        case .safety: return "red"
        case .other: return "gray"
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
    var paymentTerms: String
    var preferredContactMethod: ContactMethod
    
    // Relationships
    @Relationship(deleteRule: .nullify) var installations: [Installation] = []
    
    // Computed properties
    var displaySpecialties: String {
        return specialties.map { $0.rawValue }.joined(separator: ", ")
    }
    
    var hasEmergencyContact: Bool {
        return !emergencyContact.isEmpty
    }
    
    var ratingColor: String {
        switch rating {
        case 4.5...5.0: return "green"
        case 3.5..<4.5: return "orange"
        case 0.0..<3.5: return "red"
        default: return "gray"
        }
    }
    
    var ratingStars: String {
        let fullStars = Int(rating)
        let hasHalfStar = rating - Double(fullStars) >= 0.5
        
        var stars = String(repeating: "★", count: fullStars)
        if hasHalfStar && fullStars < 5 {
            stars += "☆"
        }
        stars += String(repeating: "☆", count: 5 - fullStars - (hasHalfStar ? 1 : 0))
        return stars
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
        paymentTerms: String = "",
        preferredContactMethod: ContactMethod = .email
    ) {
        self.name = name
        self.contactEmail = contactEmail
        self.contactPhone = contactPhone
        self.address = address
        self.specialties = specialties
        self.createdDate = Date()
        self.isActive = true
        self.rating = max(0.0, min(5.0, rating))
        self.notes = notes
        self.website = website
        self.emergencyContact = emergencyContact
        self.paymentTerms = paymentTerms
        self.preferredContactMethod = preferredContactMethod
    }
    
    func addSpecialty(_ specialty: VendorSpecialty) {
        if !specialties.contains(specialty) {
            specialties.append(specialty)
        }
    }
    
    func removeSpecialty(_ specialty: VendorSpecialty) {
        specialties.removeAll { $0 == specialty }
    }
    
    func updateRating(_ newRating: Double) {
        self.rating = max(0.0, min(5.0, newRating))
    }
}

// MARK: - Vendor Specialty Enum
enum VendorSpecialty: String, CaseIterable, Codable {
    case solarInstallation = "Solar Installation"
    case electricalWork = "Electrical Work"
    case roofing = "Roofing"
    case permitting = "Permitting"
    case inspection = "Inspection"
    case maintenance = "Maintenance"
    case design = "System Design"
    case consulting = "Consulting"
    case equipment = "Equipment Supply"
    case financing = "Financing"
    
    var icon: String {
        switch self {
        case .solarInstallation: return "sun.max"
        case .electricalWork: return "bolt"
        case .roofing: return "house"
        case .permitting: return "doc.text"
        case .inspection: return "magnifyingglass"
        case .maintenance: return "wrench"
        case .design: return "pencil.and.ruler"
        case .consulting: return "person.2"
        case .equipment: return "cube.box"
        case .financing: return "dollarsign.circle"
        }
    }
    
    var color: String {
        switch self {
        case .solarInstallation: return "yellow"
        case .electricalWork: return "blue"
        case .roofing: return "brown"
        case .permitting: return "green"
        case .inspection: return "purple"
        case .maintenance: return "orange"
        case .design: return "pink"
        case .consulting: return "indigo"
        case .equipment: return "gray"
        case .financing: return "green"
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
    var equipmentUsed: String
    var weatherConditions: String
    var customersPresent: Bool
    var issuesEncountered: String
    var photosData: [Data]
    var completionNotes: String
    
    // Relationships
    @Relationship var job: SolarJob?
    @Relationship var assignedVendor: Vendor?
    
    // Computed properties
    var duration: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }
    
    var durationString: String {
        guard let duration = duration else { return "Not tracked" }
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    var isOverdue: Bool {
        return status != .completed && Date() > scheduledDate
    }
    
    var daysUntilInstallation: Int {
        return Calendar.current.dateComponents([.day], from: Date(), to: scheduledDate).day ?? 0
    }
    
    var hasIssues: Bool {
        return !issuesEncountered.isEmpty
    }
    
    var hasPhotos: Bool {
        return !photosData.isEmpty
    }
    
    init(
        scheduledDate: Date,
        status: InstallationStatus = .scheduled,
        crewMembers: String = "",
        notes: String = "",
        weatherConditions: String = "",
        customersPresent: Bool = false
    ) {
        self.scheduledDate = scheduledDate
        self.status = status
        self.crewMembers = crewMembers
        self.notes = notes
        self.createdDate = Date()
        self.weatherConditions = weatherConditions
        self.customersPresent = customersPresent
        self.equipmentUsed = ""
        self.issuesEncountered = ""
        self.photosData = []
        self.completionNotes = ""
    }
    
    func startInstallation() {
        status = .inProgress
        startTime = Date()
    }
    
    func completeInstallation(completionNotes: String = "") {
        status = .completed
        endTime = Date()
        self.completionNotes = completionNotes
    }
    
    func addIssue(_ issue: String) {
        if issuesEncountered.isEmpty {
            issuesEncountered = issue
        } else {
            issuesEncountered += "; \(issue)"
        }
    }
    
    func addPhoto(_ photoData: Data) {
        photosData.append(photoData)
    }
}

// MARK: - Installation Status Enum
enum InstallationStatus: String, CaseIterable, Codable {
    case scheduled = "Scheduled"
    case confirmed = "Confirmed"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case postponed = "Postponed"
    case requiresFollowUp = "Requires Follow-up"
    
    var color: String {
        switch self {
        case .scheduled: return "blue"
        case .confirmed: return "green"
        case .inProgress: return "orange"
        case .completed: return "green"
        case .cancelled: return "red"
        case .postponed: return "yellow"
        case .requiresFollowUp: return "purple"
        }
    }
    
    var icon: String {
        switch self {
        case .scheduled: return "calendar"
        case .confirmed: return "checkmark.circle"
        case .inProgress: return "hammer"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        case .postponed: return "clock"
        case .requiresFollowUp: return "exclamationmark.triangle"
        }
    }
}

// MARK: - Contract Model
@Model
final class Contract {
    var id = UUID()
    var contractNumber: String
    var title: String
    var description: String
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
        description: String = "",
        totalAmount: Double,
        status: ContractStatus = .draft,
        terms: String = "",
        paymentSchedule: String = ""
    ) {
        self.contractNumber = contractNumber
        self.title = title
        self.description = description
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