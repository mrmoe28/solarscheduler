import Foundation
import SwiftUI

@Observable
class EquipmentViewModel {
    private let dataService: DataService
    private let validationService: ValidationService
    private let notificationService: NotificationService
    private let userSession: UserSession
    
    // Data
    var equipment: [Equipment] = []
    var filteredEquipment: [Equipment] = []
    
    // UI State
    var isLoading = false
    var errorMessage: String?
    var searchText = ""
    var selectedCategory: EquipmentCategory?
    var showLowStockOnly = false
    var sortBy: EquipmentSortBy = .name
    var sortAscending = true
    
    // Form State
    var showingAddEquipment = false
    var showingEquipmentDetail = false
    var selectedEquipment: Equipment?
    
    // Add Equipment Form
    var newEquipmentName = ""
    var newEquipmentCategory: EquipmentCategory = .solarPanels
    var newEquipmentBrand = ""
    var newEquipmentModel = ""
    var newEquipmentQuantity = 0
    var newEquipmentUnitCost = 0.0
    var newEquipmentMinimumStock = 0
    var newEquipmentDescription = ""
    var newEquipmentImageData: Data?
    var formErrors: [ValidationService.ValidationError] = []
    
    init(dataService: DataService, validationService: ValidationService = .shared, notificationService: NotificationService = .shared, userSession: UserSession = .shared) {
        self.dataService = dataService
        self.validationService = validationService
        self.notificationService = notificationService
        self.userSession = userSession
        loadEquipment()
    }
    
    private var currentUser: User? {
        userSession.currentUser
    }
    
    // MARK: - Data Loading
    
    func loadEquipment() {
        Task { @MainActor in
            isLoading = true
            errorMessage = nil
            
            guard let user = currentUser else {
                errorMessage = "No user signed in"
                isLoading = false
                return
            }
            
            do {
                equipment = try dataService.fetchEquipment(
                    for: user,
                    sortBy: sortBy,
                    ascending: sortAscending
                )
                applyFilters()
            } catch {
                errorMessage = "Failed to load equipment: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
            
            isLoading = false
        }
    }
    
    private func applyFilters() {
        var filtered = equipment
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.brand.localizedCaseInsensitiveContains(searchText) ||
                $0.model.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply low stock filter
        if showLowStockOnly {
            filtered = filtered.filter { $0.isLowStock }
        }
        
        // Apply sorting
        switch sortBy {
        case .name:
            filtered.sort { sortAscending ? $0.name < $1.name : $0.name > $1.name }
        case .quantity:
            filtered.sort { sortAscending ? $0.quantity < $1.quantity : $0.quantity > $1.quantity }
        case .unitCost:
            filtered.sort { sortAscending ? $0.unitPrice < $1.unitPrice : $0.unitPrice > $1.unitPrice }
        case .category:
            filtered.sort { sortAscending ? $0.category.rawValue < $1.category.rawValue : $0.category.rawValue > $1.category.rawValue }
        }
        
        filteredEquipment = filtered
    }
    
    // MARK: - Equipment Management
    
    func addEquipment() {
        let validation = validationService.validateEquipment(
            name: newEquipmentName,
            brand: newEquipmentBrand,
            model: newEquipmentModel,
            quantity: newEquipmentQuantity,
            unitCost: newEquipmentUnitCost,
            minimumStock: newEquipmentMinimumStock
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
                let equipment = try dataService.createEquipment(
                    name: newEquipmentName,
                    category: newEquipmentCategory,
                    brand: newEquipmentBrand,
                    model: newEquipmentModel,
                    manufacturer: newEquipmentBrand,
                    quantity: newEquipmentQuantity,
                    unitPrice: newEquipmentUnitCost,
                    unitCost: newEquipmentUnitCost,
                    minimumStock: newEquipmentMinimumStock,
                    user: user
                )
                
                equipment.equipmentDescription = newEquipmentDescription
                equipment.imageData = newEquipmentImageData
                try dataService.save()
                
                notificationService.notifyDataSaveSuccess("Equipment added successfully")
                resetForm()
                showingAddEquipment = false
                loadEquipment()
                
            } catch {
                errorMessage = "Failed to add equipment: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    func updateEquipment(_ equipment: Equipment) {
        Task { @MainActor in
            do {
                try dataService.save()
                notificationService.notifyDataSaveSuccess("Equipment updated successfully")
                loadEquipment()
            } catch {
                errorMessage = "Failed to update equipment: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    func updateEquipmentWithImage(
        _ equipment: Equipment,
        name: String,
        manufacturer: String,
        model: String,
        category: String,
        minimumStock: Int,
        unitPrice: Double,
        description: String,
        imageData: Data?
    ) {
        Task { @MainActor in
            do {
                equipment.name = name
                equipment.manufacturer = manufacturer
                equipment.model = model
                equipment.brand = manufacturer
                
                // Convert category string to enum
                if let equipmentCategory = EquipmentCategory.allCases.first(where: { $0.rawValue == category }) {
                    equipment.category = equipmentCategory
                }
                
                equipment.minimumStock = minimumStock
                equipment.unitPrice = unitPrice
                equipment.equipmentDescription = description
                equipment.imageData = imageData
                
                try dataService.save()
                notificationService.notifyDataSaveSuccess("Equipment updated successfully")
                loadEquipment()
            } catch {
                errorMessage = "Failed to update equipment: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    func deleteEquipment(_ equipment: Equipment) {
        Task { @MainActor in
            do {
                try dataService.delete(equipment)
                notificationService.notifyDataSaveSuccess("Equipment deleted successfully")
                loadEquipment()
            } catch {
                errorMessage = "Failed to delete equipment: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    func updateEquipmentQuantity(_ equipment: Equipment, newQuantity: Int) {
        let _ = validationService.validateEquipmentUsage(
            equipment: equipment,
            requestedQuantity: abs(equipment.quantity - newQuantity)
        )
        
        // Allow quantity updates even if it goes below minimum stock
        guard newQuantity >= 0 else {
            notificationService.showInAppNotification(
                AppNotification(
                    title: "Invalid Quantity",
                    message: "Quantity cannot be negative",
                    type: .error
                )
            )
            return
        }
        
        Task { @MainActor in
            do {
                try dataService.updateEquipmentQuantity(equipment, newQuantity: newQuantity)
                
                // Notify if equipment is now low stock
                if equipment.isLowStock {
                    notificationService.scheduleEquipmentLowStockAlert(for: equipment)
                }
                
                notificationService.notifyDataSaveSuccess("Quantity updated successfully")
                loadEquipment()
            } catch {
                errorMessage = "Failed to update quantity: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    func adjustStock(_ equipment: Equipment, adjustment: Int, reason: String = "") {
        let newQuantity = equipment.quantity + adjustment
        
        guard newQuantity >= 0 else {
            notificationService.showInAppNotification(
                AppNotification(
                    title: "Invalid Stock Adjustment",
                    message: "Adjustment would result in negative stock",
                    type: .error
                )
            )
            return
        }
        
        Task { @MainActor in
            do {
                try dataService.updateEquipmentQuantity(equipment, newQuantity: newQuantity)
                
                let message = adjustment > 0 ? "Stock increased by \(adjustment)" : "Stock decreased by \(abs(adjustment))"
                notificationService.showInAppNotification(
                    AppNotification(
                        title: "Stock Adjusted",
                        message: "\(equipment.name): \(message)",
                        type: .info
                    )
                )
                
                loadEquipment()
            } catch {
                errorMessage = "Failed to adjust stock: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    // MARK: - Stock Management
    
    func getLowStockItems() -> [Equipment] {
        return equipment.filter { $0.isLowStock }
    }
    
    func getOutOfStockItems() -> [Equipment] {
        return equipment.filter { $0.quantity == 0 }
    }
    
    func reorderEquipment(_ equipment: Equipment, quantity: Int = 0) {
        let reorderQuantity = quantity > 0 ? quantity : (equipment.minimumStock * 2)
        
        // This would integrate with a purchasing system in production
        notificationService.showInAppNotification(
            AppNotification(
                title: "Reorder Initiated",
                message: "Reorder request for \(reorderQuantity) units of \(equipment.name)",
                type: .info,
                actionTitle: "View Orders"
            )
        )
        
        // For now, we'll simulate adding stock
        // In production, this would create a purchase order
        Task { @MainActor in
            do {
                let newQuantity = equipment.quantity + reorderQuantity
                try dataService.updateEquipmentQuantity(equipment, newQuantity: newQuantity)
                
                notificationService.notifyDataSaveSuccess("Stock replenished: \(equipment.name)")
                loadEquipment()
            } catch {
                errorMessage = "Failed to reorder equipment: \(error.localizedDescription)"
                notificationService.notifyDataSaveError(error)
            }
        }
    }
    
    // MARK: - Search and Filter
    
    func searchEquipment(_ query: String) {
        searchText = query
        applyFilters()
    }
    
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        showLowStockOnly = false
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
    
    func updateSelectedCategory(_ category: EquipmentCategory?) {
        selectedCategory = category
        Task { @MainActor in
            applyFilters()
        }
    }
    
    func updateShowLowStockOnly(_ show: Bool) {
        showLowStockOnly = show
        Task { @MainActor in
            applyFilters()
        }
    }
    
    func updateSortBy(_ sort: EquipmentSortBy) {
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
    
    func getEquipmentCount(for category: EquipmentCategory) -> Int {
        equipment.filter { $0.category == category }.count
    }
    
    func getLowStockCount() -> Int {
        equipment.filter { $0.isLowStock }.count
    }
    
    // MARK: - Form Management
    
    func resetForm() {
        newEquipmentName = ""
        newEquipmentCategory = .solarPanels
        newEquipmentBrand = ""
        newEquipmentModel = ""
        newEquipmentQuantity = 0
        newEquipmentUnitCost = 0.0
        newEquipmentMinimumStock = 0
        newEquipmentDescription = ""
        newEquipmentImageData = nil
        formErrors = []
    }
    
    func validateForm() -> Bool {
        let validation = validationService.validateEquipment(
            name: newEquipmentName,
            brand: newEquipmentBrand,
            model: newEquipmentModel,
            quantity: newEquipmentQuantity,
            unitCost: newEquipmentUnitCost,
            minimumStock: newEquipmentMinimumStock
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
    
    func showEquipmentDetail(_ equipment: Equipment) {
        selectedEquipment = equipment
        showingEquipmentDetail = true
    }
    
    func showAddEquipment() {
        resetForm()
        showingAddEquipment = true
    }
    
    // MARK: - Analytics
    
    func getEquipmentStatistics() -> EquipmentStatistics {
        let totalItems = equipment.count
        let totalValue = equipment.reduce(0) { $0 + $1.totalValue.safeValue }
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
    
    func getEquipmentByCategory() -> [String: Int] {
        var equipmentByCategory: [String: Int] = [:]
        
        for category in EquipmentCategory.allCases {
            equipmentByCategory[category.rawValue] = equipment.filter { $0.category == category }.count
        }
        
        return equipmentByCategory
    }
    
    func getValueByCategory() -> [String: Double] {
        var valueByCategory: [String: Double] = [:]
        
        for category in EquipmentCategory.allCases {
            let value = equipment.filter { $0.category == category }
                .reduce(0) { $0 + $1.totalValue.safeValue }
            valueByCategory[category.rawValue] = value
        }
        
        return valueByCategory
    }
    
    func getMostValuableEquipment() -> [Equipment] {
        return equipment.sorted { $0.totalValue.safeValue > $1.totalValue.safeValue }
    }
    
    func getEquipmentTurnoverRate() -> Double {
        // This would be calculated based on usage history in production
        // For now, return a simplified calculation
        let totalValue = equipment.reduce(0) { $0 + $1.totalValue.safeValue }
        let lowStockValue = equipment.filter { $0.isLowStock }
            .reduce(0) { $0 + $1.totalValue.safeValue }
        
        let rate = totalValue > 0 ? (lowStockValue / totalValue) * 100 : 0
        return rate.safeValue
    }
    
    // MARK: - Business Logic
    
    func canDeleteEquipment(_ equipment: Equipment) -> Bool {
        // Don't allow deletion if equipment is currently in use
        // This would check against active jobs in production
        return equipment.quantity == 0
    }
    
    func getEquipmentUsageHistory(_ equipment: Equipment) -> [EquipmentUsage] {
        // This would return actual usage history in production
        // For now, return empty array
        return []
    }
    
    func predictReorderDate(_ equipment: Equipment) -> Date? {
        // This would use actual usage patterns in production
        // For now, return a simple calculation
        guard equipment.quantity > 0 else { return Date() }
        
        let daysUntilReorder = equipment.quantity / max(1, equipment.minimumStock) * 30
        return Calendar.current.date(byAdding: .day, value: daysUntilReorder, to: Date())
    }
    
    // MARK: - Export
    
    func exportEquipment(format: ExportService.ExportFormat) {
        Task { @MainActor in
            let result = await ExportService.shared.exportEquipment(
                filteredEquipment,
                format: format
            )
            
            if result.success {
                notificationService.showInAppNotification(
                    AppNotification(
                        title: "Export Successful",
                        message: "Equipment exported to \(result.fileName)",
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

struct EquipmentUsage {
    let id = UUID()
    let date: Date
    let quantity: Int
    let jobId: UUID?
    let reason: String
    let type: UsageType
    
    enum UsageType {
        case used
        case received
        case adjusted
        case returned
    }
}