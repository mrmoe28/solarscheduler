import Foundation
import SwiftData

@Model
final class SolarJob {
    var id = UUID()
    var customerName: String
    var address: String
    var systemSize: Double
    var status: String
    var createdDate: Date
    var scheduledDate: Date?
    
    init(customerName: String, address: String, systemSize: Double, status: String = "Pending", scheduledDate: Date? = nil) {
        self.customerName = customerName
        self.address = address
        self.systemSize = systemSize
        self.status = status
        self.createdDate = Date()
        self.scheduledDate = scheduledDate
    }
}

@Model
final class Customer {
    var id = UUID()
    var name: String
    var email: String
    var phone: String
    var address: String
    var leadStatus: String
    var createdDate: Date
    
    init(name: String, email: String, phone: String, address: String, leadStatus: String = "New Lead") {
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.leadStatus = leadStatus
        self.createdDate = Date()
    }
}

@Model
final class Equipment {
    var id = UUID()
    var name: String
    var category: String
    var brand: String
    var model: String
    var quantity: Int
    var unitPrice: Double
    var equipmentDescription: String
    var imageData: Data?
    var lowStockThreshold: Int
    var createdDate: Date
    
    init(name: String, category: String, brand: String, model: String, quantity: Int, unitPrice: Double, equipmentDescription: String = "", imageData: Data? = nil, lowStockThreshold: Int = 5) {
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
    }
}

@Model
final class Vendor {
    var id = UUID()
    var name: String
    var contactEmail: String
    var contactPhone: String
    var address: String
    var specialties: String
    var createdDate: Date
    
    init(name: String, contactEmail: String, contactPhone: String, address: String, specialties: String) {
        self.name = name
        self.contactEmail = contactEmail
        self.contactPhone = contactPhone
        self.address = address
        self.specialties = specialties
        self.createdDate = Date()
    }
}

@Model
final class Installation {
    var id = UUID()
    var jobId: UUID
    var scheduledDate: Date
    var status: String
    var crewMembers: String
    var notes: String
    var createdDate: Date
    
    init(jobId: UUID, scheduledDate: Date, status: String = "Scheduled", crewMembers: String = "", notes: String = "") {
        self.jobId = jobId
        self.scheduledDate = scheduledDate
        self.status = status
        self.crewMembers = crewMembers
        self.notes = notes
        self.createdDate = Date()
    }
}