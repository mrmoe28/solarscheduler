import Foundation
import SwiftData

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