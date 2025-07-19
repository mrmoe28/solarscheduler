import Foundation
import SwiftData

@Observable
class DataService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Generic CRUD Operations
    
    func save() throws {
        try modelContext.save()
    }
    
    func delete<T: PersistentModel>(_ model: T) throws {
        modelContext.delete(model)
        try save()
    }
    
    func fetch<T: PersistentModel>(_ type: T.Type, descriptor: FetchDescriptor<T>? = nil) throws -> [T] {
        let fetchDescriptor = descriptor ?? FetchDescriptor<T>()
        return try modelContext.fetch(fetchDescriptor)
    }
    
    // MARK: - SolarJob Operations
    
    func createJob(
        customerName: String,
        address: String,
        systemSize: Double,
        estimatedRevenue: Double,
        notes: String = ""
    ) throws -> SolarJob {
        let job = SolarJob(
            customerName: customerName,
            address: address,
            systemSize: systemSize,
            estimatedRevenue: estimatedRevenue,
            notes: notes
        )
        
        modelContext.insert(job)
        try save()
        return job
    }
    
    func fetchJobs(
        status: JobStatus? = nil,
        sortBy: SortBy = .createdDate,
        ascending: Bool = false,
        limit: Int? = nil
    ) throws -> [SolarJob] {
        var descriptor = FetchDescriptor<SolarJob>()
        
        // Apply status filter
        if let status = status {
            descriptor.predicate = #Predicate<SolarJob> { job in
                job.status == status
            }
        }
        
        // Apply sorting
        switch sortBy {
        case .createdDate:
            descriptor.sortBy = [SortDescriptor(\.createdDate, order: ascending ? .forward : .reverse)]
        case .customerName:
            descriptor.sortBy = [SortDescriptor(\.customerName, order: ascending ? .forward : .reverse)]
        case .revenue:
            descriptor.sortBy = [SortDescriptor(\.estimatedRevenue, order: ascending ? .forward : .reverse)]
        case .systemSize:
            descriptor.sortBy = [SortDescriptor(\.systemSize, order: ascending ? .forward : .reverse)]
        }
        
        // Apply limit
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        
        return try fetch(SolarJob.self, descriptor: descriptor)
    }
    
    func updateJobStatus(_ job: SolarJob, to status: JobStatus) throws {
        job.status = status
        try save()
    }
    
    func searchJobs(query: String) throws -> [SolarJob] {
        let descriptor = FetchDescriptor<SolarJob>(
            predicate: #Predicate<SolarJob> { job in
                job.customerName.localizedStandardContains(query) ||
                job.address.localizedStandardContains(query) ||
                job.notes.localizedStandardContains(query)
            }
        )
        return try fetch(SolarJob.self, descriptor: descriptor)
    }
    
    // MARK: - Customer Operations
    
    func createCustomer(
        name: String,
        email: String,
        phone: String,
        address: String
    ) throws -> Customer {
        let customer = Customer(
            name: name,
            email: email,
            phone: phone,
            address: address
        )
        
        modelContext.insert(customer)
        try save()
        return customer
    }
    
    func fetchCustomers(
        leadStatus: LeadStatus? = nil,
        sortBy: CustomerSortBy = .name,
        ascending: Bool = true,
        limit: Int? = nil
    ) throws -> [Customer] {
        var descriptor = FetchDescriptor<Customer>()
        
        // Apply lead status filter
        if let leadStatus = leadStatus {
            descriptor.predicate = #Predicate<Customer> { customer in
                customer.leadStatus == leadStatus
            }
        }
        
        // Apply sorting
        switch sortBy {
        case .name:
            descriptor.sortBy = [SortDescriptor(\.name, order: ascending ? .forward : .reverse)]
        case .createdDate:
            descriptor.sortBy = [SortDescriptor(\.createdDate, order: ascending ? .forward : .reverse)]
        case .leadStatus:
            descriptor.sortBy = [SortDescriptor(\.leadStatus, order: ascending ? .forward : .reverse)]
        }
        
        // Apply limit
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        
        return try fetch(Customer.self, descriptor: descriptor)
    }
    
    func searchCustomers(query: String) throws -> [Customer] {
        let descriptor = FetchDescriptor<Customer>(
            predicate: #Predicate<Customer> { customer in
                customer.name.localizedStandardContains(query) ||
                customer.email.localizedStandardContains(query) ||
                customer.phone.localizedStandardContains(query)
            }
        )
        return try fetch(Customer.self, descriptor: descriptor)
    }
    
    // MARK: - Equipment Operations
    
    func createEquipment(
        name: String,
        category: EquipmentCategory,
        brand: String,
        model: String,
        quantity: Int,
        unitPrice: Double,
        minimumStock: Int
    ) throws -> Equipment {
        let equipment = Equipment(
            name: name,
            category: category,
            brand: brand,
            model: model,
            quantity: quantity,
            unitPrice: unitPrice,
            lowStockThreshold: minimumStock
        )
        
        modelContext.insert(equipment)
        try save()
        return equipment
    }
    
    func fetchEquipment(
        category: EquipmentCategory? = nil,
        lowStockOnly: Bool = false,
        sortBy: EquipmentSortBy = .name,
        ascending: Bool = true
    ) throws -> [Equipment] {
        var descriptor = FetchDescriptor<Equipment>()
        
        // Build predicate
        var predicates: [Predicate<Equipment>] = []
        
        if let category = category {
            predicates.append(#Predicate<Equipment> { equipment in
                equipment.category == category
            })
        }
        
        if lowStockOnly {
            predicates.append(#Predicate<Equipment> { equipment in
                equipment.quantity <= equipment.lowStockThreshold
            })
        }
        
        if !predicates.isEmpty {
            descriptor.predicate = predicates.reduce(predicates.first!) { result, predicate in
                #Predicate<Equipment> { equipment in
                    @Predicate { equipment in result } &&
                    @Predicate { equipment in predicate }
                }
            }
        }
        
        // Apply sorting
        switch sortBy {
        case .name:
            descriptor.sortBy = [SortDescriptor(\.name, order: ascending ? .forward : .reverse)]
        case .quantity:
            descriptor.sortBy = [SortDescriptor(\.quantity, order: ascending ? .forward : .reverse)]
        case .unitCost:
            descriptor.sortBy = [SortDescriptor(\.unitPrice, order: ascending ? .forward : .reverse)]
        case .category:
            descriptor.sortBy = [SortDescriptor(\.category, order: ascending ? .forward : .reverse)]
        }
        
        return try fetch(Equipment.self, descriptor: descriptor)
    }
    
    func updateEquipmentQuantity(_ equipment: Equipment, newQuantity: Int) throws {
        equipment.quantity = newQuantity
        try save()
    }
    
    // MARK: - Installation Operations
    
    func createInstallation(
        job: SolarJob,
        scheduledDate: Date,
        estimatedDuration: TimeInterval,
        crewSize: Int,
        notes: String = ""
    ) throws -> Installation {
        let installation = Installation(
            scheduledDate: scheduledDate,
            estimatedDuration: estimatedDuration,
            crewSize: crewSize,
            notes: notes
        )
        
        installation.job = job
        modelContext.insert(installation)
        try save()
        return installation
    }
    
    func fetchInstallations(
        startDate: Date? = nil,
        endDate: Date? = nil,
        status: InstallationStatus? = nil,
        sortBy: InstallationSortBy = .scheduledDate,
        ascending: Bool = true
    ) throws -> [Installation] {
        var descriptor = FetchDescriptor<Installation>()
        
        // Build predicate
        var predicates: [Predicate<Installation>] = []
        
        if let startDate = startDate {
            predicates.append(#Predicate<Installation> { installation in
                installation.scheduledDate >= startDate
            })
        }
        
        if let endDate = endDate {
            predicates.append(#Predicate<Installation> { installation in
                installation.scheduledDate <= endDate
            })
        }
        
        if let status = status {
            predicates.append(#Predicate<Installation> { installation in
                installation.status == status
            })
        }
        
        if !predicates.isEmpty {
            descriptor.predicate = predicates.reduce(predicates.first!) { result, predicate in
                #Predicate<Installation> { installation in
                    @Predicate { installation in result } &&
                    @Predicate { installation in predicate }
                }
            }
        }
        
        // Apply sorting
        switch sortBy {
        case .scheduledDate:
            descriptor.sortBy = [SortDescriptor(\.scheduledDate, order: ascending ? .forward : .reverse)]
        case .status:
            descriptor.sortBy = [SortDescriptor(\.status, order: ascending ? .forward : .reverse)]
        case .crewSize:
            descriptor.sortBy = [SortDescriptor(\.crewSize, order: ascending ? .forward : .reverse)]
        }
        
        return try fetch(Installation.self, descriptor: descriptor)
    }
    
    // MARK: - Analytics Operations
    
    func getJobStatistics() throws -> JobStatistics {
        let jobs = try fetchJobs()
        
        let totalJobs = jobs.count
        let activeJobs = jobs.filter { $0.status == .inProgress }.count
        let completedJobs = jobs.filter { $0.status == .completed }.count
        let cancelledJobs = jobs.filter { $0.status == .cancelled }.count
        
        let totalRevenue = jobs.filter { $0.status == .completed }
            .reduce(0) { $0 + $1.estimatedRevenue }
        
        let pendingRevenue = jobs.filter { $0.status != .completed && $0.status != .cancelled }
            .reduce(0) { $0 + $1.estimatedRevenue }
        
        let avgSystemSize = jobs.isEmpty ? 0 : jobs.reduce(0) { $0 + $1.systemSize } / Double(jobs.count)
        
        return JobStatistics(
            totalJobs: totalJobs,
            activeJobs: activeJobs,
            completedJobs: completedJobs,
            cancelledJobs: cancelledJobs,
            totalRevenue: totalRevenue,
            pendingRevenue: pendingRevenue,
            averageSystemSize: avgSystemSize,
            completionRate: totalJobs > 0 ? Double(completedJobs) / Double(totalJobs) : 0
        )
    }
    
    func getEquipmentStatistics() throws -> EquipmentStatistics {
        let equipment = try fetchEquipment()
        
        let totalItems = equipment.count
        let totalValue = equipment.reduce(0) { $0 + ($1.unitPrice * Double($1.quantity)) }
        let lowStockItems = equipment.filter { $0.isLowStock }
        let outOfStockItems = equipment.filter { $0.quantity == 0 }
        
        return EquipmentStatistics(
            totalItems: totalItems,
            totalValue: totalValue,
            lowStockCount: lowStockItems.count,
            outOfStockCount: outOfStockItems.count,
            lowStockItems: lowStockItems
        )
    }
}

// MARK: - Supporting Types

enum SortBy {
    case createdDate
    case customerName
    case revenue
    case systemSize
}

enum CustomerSortBy {
    case name
    case createdDate
    case leadStatus
}

enum EquipmentSortBy {
    case name
    case quantity
    case unitCost
    case category
}

enum InstallationSortBy {
    case scheduledDate
    case status
    case crewSize
}

struct JobStatistics {
    let totalJobs: Int
    let activeJobs: Int
    let completedJobs: Int
    let cancelledJobs: Int
    let totalRevenue: Double
    let pendingRevenue: Double
    let averageSystemSize: Double
    let completionRate: Double
}

struct EquipmentStatistics {
    let totalItems: Int
    let totalValue: Double
    let lowStockCount: Int
    let outOfStockCount: Int
    let lowStockItems: [Equipment]
}