import Foundation

class ValidationService {
    static let shared = ValidationService()
    
    private init() {}
    
    // MARK: - Validation Result Types
    
    struct ValidationResult {
        let isValid: Bool
        let errors: [ValidationError]
        
        static var valid: ValidationResult {
            ValidationResult(isValid: true, errors: [])
        }
        
        static func invalid(_ errors: [ValidationError]) -> ValidationResult {
            ValidationResult(isValid: false, errors: errors)
        }
        
        static func invalid(_ error: ValidationError) -> ValidationResult {
            ValidationResult(isValid: false, errors: [error])
        }
    }
    
    struct ValidationError {
        let field: String
        let message: String
        let code: ValidationErrorCode
    }
    
    enum ValidationErrorCode {
        case required
        case invalidFormat
        case outOfRange
        case businessRule
        case duplicate
    }
    
    // MARK: - Job Validation
    
    func validateJob(
        customerName: String,
        address: String,
        systemSize: Double,
        estimatedRevenue: Double,
        scheduledDate: Date? = nil
    ) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Customer name validation
        if customerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "customerName",
                message: "Customer name is required",
                code: .required
            ))
        } else if customerName.count < 2 {
            errors.append(ValidationError(
                field: "customerName",
                message: "Customer name must be at least 2 characters",
                code: .outOfRange
            ))
        } else if customerName.count > 100 {
            errors.append(ValidationError(
                field: "customerName",
                message: "Customer name cannot exceed 100 characters",
                code: .outOfRange
            ))
        }
        
        // Address validation
        if address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "address",
                message: "Address is required",
                code: .required
            ))
        } else if address.count < 10 {
            errors.append(ValidationError(
                field: "address",
                message: "Address must be at least 10 characters",
                code: .outOfRange
            ))
        } else if address.count > 200 {
            errors.append(ValidationError(
                field: "address",
                message: "Address cannot exceed 200 characters",
                code: .outOfRange
            ))
        }
        
        // System size validation
        if systemSize <= 0 {
            errors.append(ValidationError(
                field: "systemSize",
                message: "System size must be greater than 0",
                code: .outOfRange
            ))
        } else if systemSize > 1000 {
            errors.append(ValidationError(
                field: "systemSize",
                message: "System size cannot exceed 1000 kW",
                code: .outOfRange
            ))
        } else if systemSize < 0.1 {
            errors.append(ValidationError(
                field: "systemSize",
                message: "System size must be at least 0.1 kW",
                code: .outOfRange
            ))
        }
        
        // Revenue validation
        if estimatedRevenue < 0 {
            errors.append(ValidationError(
                field: "estimatedRevenue",
                message: "Estimated revenue cannot be negative",
                code: .outOfRange
            ))
        } else if estimatedRevenue > 1000000 {
            errors.append(ValidationError(
                field: "estimatedRevenue",
                message: "Estimated revenue cannot exceed $1,000,000",
                code: .outOfRange
            ))
        }
        
        // Scheduled date validation
        if let scheduledDate = scheduledDate {
            let calendar = Calendar.current
            if scheduledDate < calendar.startOfDay(for: Date()) {
                errors.append(ValidationError(
                    field: "scheduledDate",
                    message: "Scheduled date cannot be in the past",
                    code: .businessRule
                ))
            }
            
            // Check if it's a weekend (optional business rule)
            let weekday = calendar.component(.weekday, from: scheduledDate)
            if weekday == 1 || weekday == 7 { // Sunday or Saturday
                // This could be a warning rather than an error
                // For now, we'll allow weekend scheduling
            }
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
    
    // MARK: - Customer Validation
    
    func validateCustomer(
        name: String,
        email: String,
        phone: String,
        address: String
    ) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Name validation
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "name",
                message: "Customer name is required",
                code: .required
            ))
        } else if name.count < 2 {
            errors.append(ValidationError(
                field: "name",
                message: "Name must be at least 2 characters",
                code: .outOfRange
            ))
        } else if name.count > 100 {
            errors.append(ValidationError(
                field: "name",
                message: "Name cannot exceed 100 characters",
                code: .outOfRange
            ))
        }
        
        // Email validation
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "email",
                message: "Email is required",
                code: .required
            ))
        } else if !isValidEmail(email) {
            errors.append(ValidationError(
                field: "email",
                message: "Please enter a valid email address",
                code: .invalidFormat
            ))
        }
        
        // Phone validation
        if phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "phone",
                message: "Phone number is required",
                code: .required
            ))
        } else if !isValidPhone(phone) {
            errors.append(ValidationError(
                field: "phone",
                message: "Please enter a valid phone number",
                code: .invalidFormat
            ))
        }
        
        // Address validation
        if address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "address",
                message: "Address is required",
                code: .required
            ))
        } else if address.count < 10 {
            errors.append(ValidationError(
                field: "address",
                message: "Address must be at least 10 characters",
                code: .outOfRange
            ))
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
    
    // MARK: - Equipment Validation
    
    func validateEquipment(
        name: String,
        brand: String,
        model: String,
        quantity: Int,
        unitCost: Double,
        minimumStock: Int
    ) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Name validation
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "name",
                message: "Equipment name is required",
                code: .required
            ))
        } else if name.count < 2 {
            errors.append(ValidationError(
                field: "name",
                message: "Equipment name must be at least 2 characters",
                code: .outOfRange
            ))
        }
        
        // Brand validation
        if brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "brand",
                message: "Brand is required",
                code: .required
            ))
        }
        
        // Model validation
        if model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(
                field: "model",
                message: "Model is required",
                code: .required
            ))
        }
        
        // Quantity validation
        if quantity < 0 {
            errors.append(ValidationError(
                field: "quantity",
                message: "Quantity cannot be negative",
                code: .outOfRange
            ))
        } else if quantity > 10000 {
            errors.append(ValidationError(
                field: "quantity",
                message: "Quantity cannot exceed 10,000",
                code: .outOfRange
            ))
        }
        
        // Unit cost validation
        if unitCost < 0 {
            errors.append(ValidationError(
                field: "unitCost",
                message: "Unit cost cannot be negative",
                code: .outOfRange
            ))
        } else if unitCost > 100000 {
            errors.append(ValidationError(
                field: "unitCost",
                message: "Unit cost cannot exceed $100,000",
                code: .outOfRange
            ))
        }
        
        // Minimum stock validation
        if minimumStock < 0 {
            errors.append(ValidationError(
                field: "minimumStock",
                message: "Minimum stock cannot be negative",
                code: .outOfRange
            ))
        } else if minimumStock > quantity {
            errors.append(ValidationError(
                field: "minimumStock",
                message: "Minimum stock cannot exceed current quantity",
                code: .businessRule
            ))
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
    
    // MARK: - Installation Validation
    
    func validateInstallation(
        scheduledDate: Date,
        estimatedDuration: TimeInterval,
        crewSize: Int
    ) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Scheduled date validation
        let calendar = Calendar.current
        if scheduledDate < calendar.startOfDay(for: Date()) {
            errors.append(ValidationError(
                field: "scheduledDate",
                message: "Scheduled date cannot be in the past",
                code: .businessRule
            ))
        }
        
        // Check if it's too far in the future (1 year)
        let oneYearFromNow = calendar.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        if scheduledDate > oneYearFromNow {
            errors.append(ValidationError(
                field: "scheduledDate",
                message: "Scheduled date cannot be more than 1 year in the future",
                code: .businessRule
            ))
        }
        
        // Duration validation (in seconds)
        if estimatedDuration <= 0 {
            errors.append(ValidationError(
                field: "estimatedDuration",
                message: "Estimated duration must be greater than 0",
                code: .outOfRange
            ))
        } else if estimatedDuration > 86400 * 30 { // 30 days in seconds
            errors.append(ValidationError(
                field: "estimatedDuration",
                message: "Estimated duration cannot exceed 30 days",
                code: .outOfRange
            ))
        }
        
        // Crew size validation
        if crewSize <= 0 {
            errors.append(ValidationError(
                field: "crewSize",
                message: "Crew size must be at least 1",
                code: .outOfRange
            ))
        } else if crewSize > 20 {
            errors.append(ValidationError(
                field: "crewSize",
                message: "Crew size cannot exceed 20",
                code: .outOfRange
            ))
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
    
    // MARK: - Business Rules
    
    func validateJobStatusTransition(from currentStatus: JobStatus, to newStatus: JobStatus) -> ValidationResult {
        let validTransitions: [JobStatus: [JobStatus]] = [
            .pending: [.approved, .cancelled],
            .approved: [.inProgress, .onHold, .cancelled],
            .inProgress: [.completed, .onHold, .cancelled],
            .onHold: [.inProgress, .cancelled],
            .completed: [], // No transitions from completed
            .cancelled: [] // No transitions from cancelled
        ]
        
        guard let allowedTransitions = validTransitions[currentStatus] else {
            return .invalid(ValidationError(
                field: "status",
                message: "Invalid current status",
                code: .businessRule
            ))
        }
        
        if !allowedTransitions.contains(newStatus) {
            return .invalid(ValidationError(
                field: "status",
                message: "Cannot change status from \(currentStatus.rawValue) to \(newStatus.rawValue)",
                code: .businessRule
            ))
        }
        
        return .valid
    }
    
    func validateEquipmentUsage(equipment: Equipment, requestedQuantity: Int) -> ValidationResult {
        if requestedQuantity <= 0 {
            return .invalid(ValidationError(
                field: "quantity",
                message: "Requested quantity must be greater than 0",
                code: .outOfRange
            ))
        }
        
        if requestedQuantity > equipment.quantity {
            return .invalid(ValidationError(
                field: "quantity",
                message: "Insufficient stock. Available: \(equipment.quantity), Requested: \(requestedQuantity)",
                code: .businessRule
            ))
        }
        
        return .valid
    }
    
    // MARK: - Helper Methods
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        // Remove all non-digit characters
        let digitsOnly = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Check if it's a valid US phone number (10 digits)
        if digitsOnly.count == 10 {
            return true
        }
        
        // Check if it's a valid international format (with country code)
        if digitsOnly.count >= 10 && digitsOnly.count <= 15 {
            return true
        }
        
        return false
    }
    
    // MARK: - Utility Methods
    
    func formatValidationErrors(_ errors: [ValidationError]) -> String {
        errors.map { "• \($0.message)" }.joined(separator: "\n")
    }
    
    func getErrorsForField(_ field: String, from errors: [ValidationError]) -> [ValidationError] {
        errors.filter { $0.field == field }
    }
    
    func hasErrorForField(_ field: String, in errors: [ValidationError]) -> Bool {
        errors.contains { $0.field == field }
    }
}