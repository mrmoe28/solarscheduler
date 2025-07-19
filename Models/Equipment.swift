import Foundation
import SwiftData

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
    var lastUpdated: Date
    var isActive: Bool
    var warrantyPeriod: Int // in months
    var supplier: String
    
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
        quantity: Int,
        unitPrice: Double,
        equipmentDescription: String = "",
        imageData: Data? = nil,
        lowStockThreshold: Int = 5,
        warrantyPeriod: Int = 12,
        supplier: String = ""
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
    case panels = "Solar Panels"
    case inverters = "Inverters"
    case mounting = "Mounting Systems"
    case electrical = "Electrical Components"
    case batteries = "Battery Storage"
    case monitoring = "Monitoring Systems"
    case tools = "Installation Tools"
    case safety = "Safety Equipment"
    
    var icon: String {
        switch self {
        case .panels: return "rectangle.3.group"
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