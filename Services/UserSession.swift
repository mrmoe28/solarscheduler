import Foundation
import SwiftData
import SwiftUI
import CryptoKit

@Observable
class UserSession {
    static let shared = UserSession()
    
    // Hash password using SHA256
    private func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.map { byte in
            String(format: "%02x", byte)
        }.joined()
        return hashString
    }
    
    private(set) var currentUser: User?
    private(set) var isSignedIn = false
    
    // Use UserDefaults directly instead of @AppStorage to avoid conflicts with @Observable
    private var currentUserEmail: String {
        get { UserDefaults.standard.string(forKey: "currentUserEmail") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "currentUserEmail") }
    }
    
    private var storedIsSignedIn: Bool {
        get { UserDefaults.standard.bool(forKey: "isSignedIn") }
        set { UserDefaults.standard.set(newValue, forKey: "isSignedIn") }
    }
    
    private var modelContext: ModelContext?
    private var dataService: DataService?
    
    private init() {
        // Initialize from stored values
        isSignedIn = storedIsSignedIn
    }
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        self.dataService = DataService(modelContext: modelContext)
        if isSignedIn && !currentUserEmail.isEmpty {
            loadCurrentUser()
        }
    }
    
    func signIn(email: String, password: String) async throws {
        guard let dataService = dataService else { 
            throw NSError(domain: "UserSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "Data service not configured"])
        }
        
        do {
            // Try to find existing user
            if let existingUser = try dataService.fetchUser(by: email) {
                // Verify password
                if existingUser.verifyPassword(password) {
                    // Update existing user
                    existingUser.lastSignInDate = Date()
                    existingUser.isActive = true
                    currentUser = existingUser
                    try dataService.save()
                    
                    // Update stored values
                    currentUserEmail = email
                    storedIsSignedIn = true
                    isSignedIn = true
                } else {
                    throw NSError(domain: "UserSession", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid email or password"])
                }
            } else {
                throw NSError(domain: "UserSession", code: 3, userInfo: [NSLocalizedDescriptionKey: "User not found. Please sign up first."])
            }
        } catch {
            print("Failed to sign in user: \(error)")
            throw error
        }
    }
    
    func signUp(email: String, password: String, fullName: String, companyName: String = "") async throws {
        guard let dataService = dataService else { 
            throw NSError(domain: "UserSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "Data service not configured"])
        }
        
        // Check if user already exists
        if let _ = try dataService.fetchUser(by: email) {
            throw NSError(domain: "UserSession", code: 4, userInfo: [NSLocalizedDescriptionKey: "An account with this email already exists"])
        }
        
        // Create new user with hashed password
        let passwordHash = hashPassword(password)
        let newUser = try dataService.createUser(
            email: email,
            fullName: fullName,
            passwordHash: passwordHash,
            companyName: companyName
        )
        
        newUser.lastSignInDate = Date()
        currentUser = newUser
        try dataService.save()
        
        // Update stored values
        currentUserEmail = email
        storedIsSignedIn = true
        isSignedIn = true
    }
    
    func signOut() async {
        if let user = currentUser {
            user.lastSignInDate = Date()
            try? dataService?.save()
        }
        
        currentUser = nil
        currentUserEmail = ""
        storedIsSignedIn = false
        isSignedIn = false
    }
    
    private func loadCurrentUser() {
        guard let dataService = dataService, !currentUserEmail.isEmpty else { return }
        
        do {
            currentUser = try dataService.fetchUser(by: currentUserEmail)
            if currentUser == nil {
                // User not found, sign out
                Task {
                    await signOut()
                }
            }
        } catch {
            print("Failed to load current user: \(error)")
            Task {
                await signOut()
            }
        }
    }
    
    // MARK: - Data Access Methods
    
    func getUserJobs(status: JobStatus? = nil, limit: Int? = nil) -> [SolarJob] {
        guard let dataService = dataService, let user = currentUser else { return [] }
        
        do {
            return try dataService.fetchJobs(for: user, status: status, limit: limit)
        } catch {
            print("Failed to fetch user jobs: \(error)")
            return []
        }
    }
    
    func getUserCustomers(leadStatus: LeadStatus? = nil, limit: Int? = nil) -> [Customer] {
        guard let dataService = dataService, let user = currentUser else { return [] }
        
        do {
            return try dataService.fetchCustomers(for: user, leadStatus: leadStatus, limit: limit)
        } catch {
            print("Failed to fetch user customers: \(error)")
            return []
        }
    }
    
    func getUserEquipment(category: EquipmentCategory? = nil, lowStockOnly: Bool = false) -> [Equipment] {
        guard let dataService = dataService, let user = currentUser else { return [] }
        
        do {
            return try dataService.fetchEquipment(for: user, category: category, lowStockOnly: lowStockOnly)
        } catch {
            print("Failed to fetch user equipment: \(error)")
            return []
        }
    }
    
    func getUserInstallations(startDate: Date? = nil, endDate: Date? = nil, status: InstallationStatus? = nil) -> [Installation] {
        guard let dataService = dataService, let user = currentUser else { return [] }
        
        do {
            return try dataService.fetchInstallations(for: user, startDate: startDate, endDate: endDate, status: status)
        } catch {
            print("Failed to fetch user installations: \(error)")
            return []
        }
    }
    
    func getUserDashboardData() -> UserDashboardData? {
        guard let dataService = dataService, let user = currentUser else { return nil }
        
        do {
            return try dataService.getUserDashboardData(for: user)
        } catch {
            print("Failed to fetch user dashboard data: \(error)")
            return nil
        }
    }
    
    func getUserStatistics() -> (JobStatistics?, EquipmentStatistics?) {
        guard let dataService = dataService, let user = currentUser else { return (nil, nil) }
        
        do {
            let jobStats = try dataService.getJobStatistics(for: user)
            let equipmentStats = try dataService.getEquipmentStatistics(for: user)
            return (jobStats, equipmentStats)
        } catch {
            print("Failed to fetch user statistics: \(error)")
            return (nil, nil)
        }
    }
    
    // MARK: - Data Creation Methods
    
    func createJob(customerName: String, address: String, systemSize: Double, estimatedRevenue: Double, notes: String = "") -> SolarJob? {
        guard let dataService = dataService, let user = currentUser else { return nil }
        
        do {
            return try dataService.createJob(
                customerName: customerName,
                address: address,
                systemSize: systemSize,
                estimatedRevenue: estimatedRevenue,
                notes: notes,
                user: user
            )
        } catch {
            print("Failed to create job: \(error)")
            return nil
        }
    }
    
    func createCustomer(name: String, email: String, phone: String, address: String) -> Customer? {
        guard let dataService = dataService, let user = currentUser else { return nil }
        
        do {
            return try dataService.createCustomer(
                name: name,
                email: email,
                phone: phone,
                address: address,
                user: user
            )
        } catch {
            print("Failed to create customer: \(error)")
            return nil
        }
    }
    
    // MARK: - Account Management
    
    func deleteAccount() async {
        guard let dataService = dataService, let user = currentUser else { return }
        
        do {
            try dataService.deleteUserData(for: user)
            await signOut()
        } catch {
            print("Failed to delete user account: \(error)")
        }
    }
    
    func updateProfile(fullName: String? = nil, companyName: String? = nil) {
        guard let dataService = dataService, let user = currentUser else { return }
        
        if let fullName = fullName {
            user.fullName = fullName
        }
        if let companyName = companyName {
            user.companyName = companyName
        }
        
        do {
            try dataService.save()
        } catch {
            print("Failed to update user profile: \(error)")
        }
    }
}