
import Foundation
import SwiftData

@Observable
class DataService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - User Operations
    
    func createUser(
        email: String,
        fullName: String,
        passwordHash: String,
        companyName: String = ""
    ) throws -> User {
        let user = User(
            email: email,
            fullName: fullName,
            passwordHash: passwordHash,
            companyName: companyName
        )
        
        modelContext.insert(user)
        try save()
        return user
    }
    
    func fetchUser(by email: String) throws -> User? {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { user in
                user.email == email
            }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func fetchAllUsers() throws -> [User] {
        let descriptor = FetchDescriptor<User>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
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
        notes: String = "",
        user: User
    ) throws -> SolarJob {
        let job = SolarJob(
            customerName: customerName,
            address: address,
            systemSize: systemSize,
            estimatedRevenue: estimatedRevenue,
            notes: notes
        )
        
        job.user = user
        modelContext.insert(job)
        try save()
        return job
    }
    
    func fetchJobs(
        for user: User,
        status: JobStatus? = nil,
        sortBy: SortBy = .createdDate,
        ascending: Bool = false,
        limit: Int? = nil
    ) throws -> [SolarJob] {
        var descriptor = FetchDescriptor<SolarJob>()
        
        // Apply sorting first
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
        
        // Fetch all jobs and filter
        let allJobs = try modelContext.fetch(descriptor)
        
        // Filter by user and status
        var filteredJobs = allJobs.filter { job in
            guard let jobUser = job.user else { return false }
            return jobUser.id == user.id
        }
        
        if let status = status {
            filteredJobs = filteredJobs.filter { $0.status == status }
        }
        
        // Apply limit
        if let limit = limit {
            return Array(filteredJobs.prefix(limit))
        }
        
        return filteredJobs
    }
    
    func updateJobStatus(_ job: SolarJob, to status: JobStatus) throws {
        job.status = status
        try save()
    }
    
    func searchJobs(for user: User, query: String) throws -> [SolarJob] {
        // Fetch all jobs for the user first
        let descriptor = FetchDescriptor<SolarJob>()
        let allJobs = try modelContext.fetch(descriptor)
        
        // Filter by user and search query
        return allJobs.filter { job in
            guard let jobUser = job.user else { return false }
            guard jobUser.id == user.id else { return false }
            
            return job.customerName.localizedCaseInsensitiveContains(query) ||
                   job.address.localizedCaseInsensitiveContains(query) ||
                   job.notes.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - Customer Operations
    
    func createCustomer(
        name: String,
        email: String,
        phone: String,
        address: String,
        user: User
    ) throws -> Customer {
        let customer = Customer(
            name: name,
            email: email,
            phone: phone,
            address: address
        )
        
        customer.user = user
        modelContext.insert(customer)
        try save()
        return customer
    }
    
    func fetchCustomers(
        for user: User,
        leadStatus: LeadStatus? = nil,
        sortBy: CustomerSortBy = .name,
        ascending: Bool = true,
        limit: Int? = nil
    ) throws -> [Customer] {
        var descriptor = FetchDescriptor<Customer>()
        
        // Apply sorting
        switch sortBy {
        case .name:
            descriptor.sortBy = [SortDescriptor(\.name, order: ascending ? .forward : .reverse)]
        case .createdDate:
            descriptor.sortBy = [SortDescriptor(\.createdDate, order: ascending ? .forward : .reverse)]
        case .leadStatus:
            descriptor.sortBy = [SortDescriptor(\.leadStatus.rawValue, order: ascending ? .forward : .reverse)]
        }
        
        // Fetch all customers and filter
        let allCustomers = try modelContext.fetch(descriptor)
        
        // Filter by user and lead status
        var filteredCustomers = allCustomers.filter { customer in
            guard let customerUser = customer.user else { return false }
            return customerUser.id == user.id
        }
        
        if let leadStatus = leadStatus {
            filteredCustomers = filteredCustomers.filter { $0.leadStatus == leadStatus }
        }
        
        // Apply limit
        if let limit = limit {
            return Array(filteredCustomers.prefix(limit))
        }
        
        return filteredCustomers
    }
    
    func searchCustomers(for user: User, query: String) throws -> [Customer] {
        // Fetch all customers
        let descriptor = FetchDescriptor<Customer>()
        let allCustomers = try modelContext.fetch(descriptor)
        
        // Filter by user and search query
        return allCustomers.filter { customer in
            guard let customerUser = customer.user else { return false }
            guard customerUser.id == user.id else { return false }
            
            return customer.name.localizedCaseInsensitiveContains(query) ||
                   customer.email.localizedCaseInsensitiveContains(query) ||
                   customer.phone.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - Equipment Operations
    
    func createEquipment(
        name: String,
        category: EquipmentCategory,
        brand: String,
        model: String,
        manufacturer: String = "",
        quantity: Int,
        unitPrice: Double,
        unitCost: Double? = nil,
        minimumStock: Int,
        user: User
    ) throws -> Equipment {
        let equipment = Equipment(
            name: name,
            category: category,
            brand: brand,
            model: model,
            manufacturer: manufacturer,
            quantity: quantity,
            unitPrice: unitPrice,
            unitCost: unitCost,
            lowStockThreshold: minimumStock,
            minimumStock: minimumStock
        )
        
        equipment.user = user
        modelContext.insert(equipment)
        try save()
        return equipment
    }
    
    func fetchEquipment(
        for user: User,
        category: EquipmentCategory? = nil,
        lowStockOnly: Bool = false,
        sortBy: EquipmentSortBy = .name,
        ascending: Bool = true
    ) throws -> [Equipment] {
        var descriptor = FetchDescriptor<Equipment>()
        
        // Apply sorting
        switch sortBy {
        case .name:
            descriptor.sortBy = [SortDescriptor(\.name, order: ascending ? .forward : .reverse)]
        case .quantity:
            descriptor.sortBy = [SortDescriptor(\.quantity, order: ascending ? .forward : .reverse)]
        case .unitCost:
            descriptor.sortBy = [SortDescriptor(\.unitCost, order: ascending ? .forward : .reverse)]
        case .category:
            descriptor.sortBy = [SortDescriptor(\.category.rawValue, order: ascending ? .forward : .reverse)]
        }
        
        // Fetch all equipment and filter
        let allEquipment = try modelContext.fetch(descriptor)
        
        // Filter by category and stock level
        var filteredEquipment = allEquipment
        
        if let category = category {
            filteredEquipment = filteredEquipment.filter { $0.category == category }
        }
        
        if lowStockOnly {
            filteredEquipment = filteredEquipment.filter { $0.quantity <= $0.lowStockThreshold }
        }
        
        // Note: Equipment filtering by user will be added when user relationship is added to model
        
        return filteredEquipment
    }
    
    func updateEquipmentQuantity(_ equipment: Equipment, newQuantity: Int) throws {
        equipment.quantity = newQuantity
        try save()
    }
    
    // MARK: - Installation Operations
    
    func createInstallation(
        job: SolarJob,
        scheduledDate: Date,
        crewMembers: String = "",
        notes: String = "",
        estimatedDuration: TimeInterval = 8 * 3600,
        user: User
    ) throws -> Installation {
        let installation = Installation(
            scheduledDate: scheduledDate,
            crewMembers: crewMembers,
            notes: notes,
            estimatedDuration: estimatedDuration
        )
        
        installation.job = job
        installation.user = user
        modelContext.insert(installation)
        try save()
        return installation
    }
    
    func fetchInstallations(
        for user: User,
        startDate: Date? = nil,
        endDate: Date? = nil,
        status: InstallationStatus? = nil,
        sortBy: InstallationSortBy = .scheduledDate,
        ascending: Bool = true
    ) throws -> [Installation] {
        var descriptor = FetchDescriptor<Installation>()
        
        // Apply sorting
        switch sortBy {
        case .scheduledDate:
            descriptor.sortBy = [SortDescriptor(\.scheduledDate, order: ascending ? .forward : .reverse)]
        case .status:
            descriptor.sortBy = [SortDescriptor(\.status.rawValue, order: ascending ? .forward : .reverse)]
        case .crewMembers:
            descriptor.sortBy = [SortDescriptor(\.crewMembers, order: ascending ? .forward : .reverse)]
        }
        
        // Fetch all installations and filter
        let allInstallations = try modelContext.fetch(descriptor)
        
        // Filter by user, date range, and status
        return allInstallations.filter { installation in
            guard let installationUser = installation.user else { return false }
            guard installationUser.id == user.id else { return false }
            
            if let startDate = startDate, installation.scheduledDate < startDate {
                return false
            }
            
            if let endDate = endDate, installation.scheduledDate > endDate {
                return false
            }
            
            if let status = status, installation.status != status {
                return false
            }
            
            return true
        }
    }
    
    // MARK: - Analytics Operations
    
    func getJobStatistics(for user: User) throws -> JobStatistics {
        let jobs = try fetchJobs(for: user)
        
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
    
    func getEquipmentStatistics(for user: User) throws -> EquipmentStatistics {
        let equipment = try fetchEquipment(for: user)
        
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
    
    // MARK: - Utility Methods
    
    func deleteUserData(for user: User) throws {
        // Delete all user's data
        let jobs = try fetchJobs(for: user)
        let customers = try fetchCustomers(for: user)
        let equipment = try fetchEquipment(for: user)
        let installations = try fetchInstallations(for: user)
        
        for job in jobs {
            modelContext.delete(job)
        }
        for customer in customers {
            modelContext.delete(customer)
        }
        for item in equipment {
            modelContext.delete(item)
        }
        for installation in installations {
            modelContext.delete(installation)
        }
        
        modelContext.delete(user)
        try save()
    }
    
    func getUserDashboardData(for user: User) throws -> UserDashboardData {
        let jobs = try fetchJobs(for: user, limit: 10)
        let customers = try fetchCustomers(for: user, limit: 10)
        let installations = try fetchInstallations(for: user)
        let lowStockEquipment = try fetchEquipment(for: user, lowStockOnly: true)
        
        return UserDashboardData(
            recentJobs: jobs,
            recentCustomers: customers,
            upcomingInstallations: installations,
            lowStockEquipment: lowStockEquipment
        )
    }
    
    func transferDataToUser(from oldUser: User, to newUser: User) throws {
        let jobs = try fetchJobs(for: oldUser)
        let customers = try fetchCustomers(for: oldUser)
        let equipment = try fetchEquipment(for: oldUser)
        let installations = try fetchInstallations(for: oldUser)
        
        // Transfer ownership
        for job in jobs {
            job.user = newUser
        }
        for customer in customers {
            customer.user = newUser
        }
        for item in equipment {
            item.user = newUser
        }
        for installation in installations {
            installation.user = newUser
        }
        
        try save()
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
    case crewMembers
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

struct UserDashboardData {
    let recentJobs: [SolarJob]
    let recentCustomers: [Customer]
    let upcomingInstallations: [Installation]
    let lowStockEquipment: [Equipment]
}
