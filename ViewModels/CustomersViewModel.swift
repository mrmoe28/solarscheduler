import Foundation
import SwiftUI

@Observable
class CustomersViewModel: ObservableObject {
    private let dataService: DataService
    private let validationService: ValidationService
    private let notificationService: NotificationService
    private let userSession: UserSession
    
    // Data
    var customers: [Customer] = []
    var filteredCustomers: [Customer] = []
    
    // UI State
    var isLoading = false
    var errorMessage: String?
    var searchText = ""
    var selectedLeadStatus: LeadStatus?
    var sortBy: CustomerSortBy = .name
    var sortAscending = true
    
    // Form State
    var showingAddCustomer = false
    var showingCustomerDetail = false
    var selectedCustomer: Customer?
    
    // Add Customer Form
    var newCustomerName = ""
    var newCustomerEmail = ""
    var newCustomerPhone = ""
    var newCustomerAddress = ""
    var newCustomerLeadStatus: LeadStatus = .newLead
    var newCustomerNotes = ""
    var formErrors: [ValidationService.ValidationError] = []
    
    init(dataService: DataService, validationService: ValidationService = .shared, notificationService: NotificationService = .shared, userSession: UserSession = .shared) {
        self.dataService = dataService
        self.validationService = validationService
        self.notificationService = notificationService
        self.userSession = userSession
        loadCustomers()
    }
    
    private var currentUser: User? {
        userSession.currentUser
    }
    
    // MARK: - Data Loading
    
    func loadCustomers() {
        Task { @MainActor in
            isLoading = true
            errorMessage = nil
            
            guard let user = currentUser else {
                errorMessage = "No user signed in"
                isLoading = false
                return
            }
            
            do {
                customers = try dataService.fetchCustomers(
                    for: user,
                    sortBy: sortBy,
                    ascending: sortAscending
                )
                applyFilters()
            } catch {
                errorMessage = "Failed to load customers: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
            
            isLoading = false
        }
    }
    
    private func applyFilters() {
        var filtered = customers
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText) ||
                $0.phone.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply lead status filter
        if let leadStatus = selectedLeadStatus {
            filtered = filtered.filter { $0.leadStatus == leadStatus }
        }
        
        // Apply sorting
        switch sortBy {
        case .name:
            filtered.sort { sortAscending ? $0.name < $1.name : $0.name > $1.name }
        case .createdDate:
            filtered.sort { sortAscending ? $0.createdDate < $1.createdDate : $0.createdDate > $1.createdDate }
        case .leadStatus:
            filtered.sort { sortAscending ? $0.leadStatus.rawValue < $1.leadStatus.rawValue : $0.leadStatus.rawValue > $1.leadStatus.rawValue }
        }
        
        filteredCustomers = filtered
    }
    
    // MARK: - Customer Management
    
    func addCustomer() {
        let validation = validationService.validateCustomer(
            name: newCustomerName,
            email: newCustomerEmail,
            phone: newCustomerPhone,
            address: newCustomerAddress
        )
        
        guard validation.isValid else {
            formErrors = validation.errors
            notificationService.notifyValidationErrors(validation.errors)
            return
        }
        
        guard let user = currentUser else {
            errorMessage = "No user signed in"
            return
        }
        
        Task { @MainActor in
            do {
                let customer = try dataService.createCustomer(
                    name: newCustomerName,
                    email: newCustomerEmail,
                    phone: newCustomerPhone,
                    address: newCustomerAddress,
                    user: user
                )
                
                customer.leadStatus = newCustomerLeadStatus
                customer.notes = newCustomerNotes
                try dataService.save()
                
                notificationService.notifyNewCustomer(customer)
                resetForm()
                showingAddCustomer = false
                loadCustomers()
                
            } catch {
                errorMessage = "Failed to create customer: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    func updateCustomer(_ customer: Customer) {
        Task { @MainActor in
            do {
                try dataService.save()
                notificationService.notifyDataSaveSuccess("Customer updated successfully")
                loadCustomers()
            } catch {
                errorMessage = "Failed to update customer: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    func deleteCustomer(_ customer: Customer) {
        Task { @MainActor in
            do {
                try dataService.delete(customer)
                notificationService.notifyDataSaveSuccess("Customer deleted successfully")
                loadCustomers()
            } catch {
                errorMessage = "Failed to delete customer: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    func updateCustomerLeadStatus(_ customer: Customer, to newStatus: LeadStatus) {
        Task { @MainActor in
            do {
                customer.leadStatus = newStatus
                try dataService.save()
                
                notificationService.showInAppNotification(
                    AppNotification(
                        title: "Lead Status Updated",
                        message: "\(customer.name) is now \(newStatus.rawValue)",
                        type: .info
                    )
                )
                
                loadCustomers()
            } catch {
                errorMessage = "Failed to update lead status: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    // MARK: - Search and Filter
    
    func searchCustomers(_ query: String) {
        Task { @MainActor in
            guard let user = currentUser else {
                errorMessage = "No user signed in"
                return
            }
            
            do {
                if query.isEmpty {
                    loadCustomers()
                } else {
                    customers = try dataService.searchCustomers(for: user, query: query)
                    applyFilters()
                }
            } catch {
                errorMessage = "Search failed: \(error.localizedDescription)"
            }
        }
    }
    
    func clearFilters() {
        searchText = ""
        selectedLeadStatus = nil
        sortBy = .name
        sortAscending = true
        applyFilters()
    }
    
    // MARK: - Manual Filter Updates
    
    func updateSearchText(_ text: String) {
        searchText = text
        Task { @MainActor in
            applyFilters()
        }
    }
    
    func updateSelectedLeadStatus(_ status: LeadStatus?) {
        selectedLeadStatus = status
        Task { @MainActor in
            applyFilters()
        }
    }
    
    func updateSortBy(_ sort: CustomerSortBy) {
        sortBy = sort
        Task { @MainActor in
            applyFilters()
        }
    }
    
    func updateSortAscending(_ ascending: Bool) {
        sortAscending = ascending
        Task { @MainActor in
            applyFilters()
        }
    }
    
    func getCustomersCount(for leadStatus: LeadStatus) -> Int {
        customers.filter { $0.leadStatus == leadStatus }.count
    }
    
    // MARK: - Form Management
    
    func resetForm() {
        newCustomerName = ""
        newCustomerEmail = ""
        newCustomerPhone = ""
        newCustomerAddress = ""
        newCustomerLeadStatus = .newLead
        newCustomerNotes = ""
        formErrors = []
    }
    
    func validateForm() -> Bool {
        let validation = validationService.validateCustomer(
            name: newCustomerName,
            email: newCustomerEmail,
            phone: newCustomerPhone,
            address: newCustomerAddress
        )
        
        formErrors = validation.errors
        return validation.isValid
    }
    
    func hasErrorForField(_ field: String) -> Bool {
        validationService.hasErrorForField(field, in: formErrors)
    }
    
    func getErrorsForField(_ field: String) -> [ValidationService.ValidationError] {
        validationService.getErrorsForField(field, from: formErrors)
    }
    
    // MARK: - Navigation
    
    func showCustomerDetail(_ customer: Customer) {
        selectedCustomer = customer
        showingCustomerDetail = true
    }
    
    func showAddCustomer() {
        resetForm()
        showingAddCustomer = true
    }
    
    // MARK: - Analytics
    
    func getCustomerStatistics() -> CustomerStatistics {
        let totalCustomers = customers.count
        let newLeads = customers.filter { $0.leadStatus == .newLead }.count
        let qualifiedLeads = customers.filter { $0.leadStatus == .qualified }.count
        let proposalSent = customers.filter { $0.leadStatus == .proposal }.count
        let closedWon = customers.filter { $0.leadStatus == .won }.count
        let closedLost = customers.filter { $0.leadStatus == .lost }.count
        
        let conversionRate = totalCustomers > 0 ? Double(closedWon) / Double(totalCustomers) : 0
        
        return CustomerStatistics(
            totalCustomers: totalCustomers,
            newLeads: newLeads,
            qualifiedLeads: qualifiedLeads,
            proposalSent: proposalSent,
            closedWon: closedWon,
            closedLost: closedLost,
            conversionRate: conversionRate
        )
    }
    
    func getCustomersByLeadStatus() -> [String: Int] {
        var customersByStatus: [String: Int] = [:]
        
        for status in LeadStatus.allCases {
            customersByStatus[status.rawValue] = customers.filter { $0.leadStatus == status }.count
        }
        
        return customersByStatus
    }
    
    func getCustomersCreatedThisMonth() -> [Customer] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return customers.filter { $0.createdDate >= startOfMonth }
    }
    
    func getTopCustomersByRevenue() -> [Customer] {
        return customers.compactMap { customer in
            let totalRevenue = customer.jobs.reduce(0) { $0 + $1.estimatedRevenue }
            return totalRevenue > 0 ? customer : nil
        }.sorted { customer1, customer2 in
            let revenue1 = customer1.jobs.reduce(0) { $0 + $1.estimatedRevenue }
            let revenue2 = customer2.jobs.reduce(0) { $0 + $1.estimatedRevenue }
            return revenue1 > revenue2
        }
    }
    
    // MARK: - Business Logic
    
    func canDeleteCustomer(_ customer: Customer) -> Bool {
        // Don't allow deletion if customer has active jobs
        let jobs = customer.jobs
        guard !jobs.isEmpty else { return true }
        return !jobs.contains { $0.status == .inProgress || $0.status == .pending }
    }
    
    func getCustomerTotalRevenue(_ customer: Customer) -> Double {
        return customer.jobs.reduce(0) { $0 + $1.estimatedRevenue }
    }
    
    func getCustomerJobCount(_ customer: Customer) -> Int {
        return customer.jobs.count
    }
    
    func getCustomerActiveJobCount(_ customer: Customer) -> Int {
        return customer.jobs.filter { $0.status == .inProgress || $0.status == .pending }.count
    }
    
    // MARK: - Export
    
    func exportCustomers(format: ExportService.ExportFormat) {
        Task { @MainActor in
            let result = await ExportService.shared.exportCustomers(
                filteredCustomers,
                format: format,
                includeJobHistory: true
            )
            
            if result.success {
                notificationService.showInAppNotification(
                    AppNotification(
                        title: "Export Successful",
                        message: "Customers exported to \(result.fileName)",
                        type: .success
                    )
                )
            } else {
                notificationService.showInAppNotification(
                    AppNotification(
                        title: "Export Failed",
                        message: result.error?.localizedDescription ?? "Unknown error",
                        type: .error
                    )
                )
            }
        }
    }
}

// MARK: - Supporting Types

struct CustomerStatistics {
    let totalCustomers: Int
    let newLeads: Int
    let qualifiedLeads: Int
    let proposalSent: Int
    let closedWon: Int
    let closedLost: Int
    let conversionRate: Double
}