import Foundation
import SwiftUI

class ExportService {
    static let shared = ExportService()
    
    private init() {}
    
    // MARK: - Export Formats
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
        case pdf = "PDF"
        case txt = "TXT"
        
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            case .pdf: return "pdf"
            case .txt: return "txt"
            }
        }
        
        var mimeType: String {
            switch self {
            case .csv: return "text/csv"
            case .json: return "application/json"
            case .pdf: return "application/pdf"
            case .txt: return "text/plain"
            }
        }
    }
    
    // MARK: - Export Types
    
    enum ExportType: String, CaseIterable {
        case jobs = "Jobs"
        case customers = "Customers"
        case equipment = "Equipment"
        case installations = "Installations"
        case businessReport = "Business Report"
        case fullBackup = "Full Backup"
    }
    
    // MARK: - Export Results
    
    struct ExportResult {
        let success: Bool
        let fileURL: URL?
        let fileName: String
        let format: ExportFormat
        let error: ExportError?
    }
    
    enum ExportError: Error, LocalizedError {
        case dataNotFound
        case fileCreationFailed
        case encodingFailed
        case permissionDenied
        case diskSpaceInsufficient
        case unknownError(String)
        
        var errorDescription: String? {
            switch self {
            case .dataNotFound:
                return "No data found to export"
            case .fileCreationFailed:
                return "Failed to create export file"
            case .encodingFailed:
                return "Failed to encode data"
            case .permissionDenied:
                return "Permission denied to write file"
            case .diskSpaceInsufficient:
                return "Insufficient disk space"
            case .unknownError(let message):
                return message
            }
        }
    }
    
    // MARK: - Jobs Export
    
    func exportJobs(
        _ jobs: [SolarJob],
        format: ExportFormat,
        includeDetails: Bool = true
    ) async -> ExportResult {
        let fileName = "solar_jobs_\(Date().formatted(date: .abbreviated, time: .omitted).replacingOccurrences(of: "/", with: "-")).\(format.fileExtension)"
        
        do {
            let content: String
            
            switch format {
            case .csv:
                content = try generateJobsCSV(jobs, includeDetails: includeDetails)
            case .json:
                content = try generateJobsJSON(jobs, includeDetails: includeDetails)
            case .txt:
                content = try generateJobsTXT(jobs, includeDetails: includeDetails)
            case .pdf:
                // PDF generation would require additional framework
                return ExportResult(
                    success: false,
                    fileURL: nil,
                    fileName: fileName,
                    format: format,
                    error: .unknownError("PDF export not yet implemented")
                )
            }
            
            let fileURL = try await saveToFile(content: content, fileName: fileName)
            
            return ExportResult(
                success: true,
                fileURL: fileURL,
                fileName: fileName,
                format: format,
                error: nil
            )
            
        } catch {
            return ExportResult(
                success: false,
                fileURL: nil,
                fileName: fileName,
                format: format,
                error: .unknownError(error.localizedDescription)
            )
        }
    }
    
    // MARK: - Customers Export
    
    func exportCustomers(
        _ customers: [Customer],
        format: ExportFormat,
        includeJobHistory: Bool = true
    ) async -> ExportResult {
        let fileName = "customers_\(Date().formatted(date: .abbreviated, time: .omitted).replacingOccurrences(of: "/", with: "-")).\(format.fileExtension)"
        
        do {
            let content: String
            
            switch format {
            case .csv:
                content = try generateCustomersCSV(customers, includeJobHistory: includeJobHistory)
            case .json:
                content = try generateCustomersJSON(customers, includeJobHistory: includeJobHistory)
            case .txt:
                content = try generateCustomersTXT(customers, includeJobHistory: includeJobHistory)
            case .pdf:
                return ExportResult(
                    success: false,
                    fileURL: nil,
                    fileName: fileName,
                    format: format,
                    error: .unknownError("PDF export not yet implemented")
                )
            }
            
            let fileURL = try await saveToFile(content: content, fileName: fileName)
            
            return ExportResult(
                success: true,
                fileURL: fileURL,
                fileName: fileName,
                format: format,
                error: nil
            )
            
        } catch {
            return ExportResult(
                success: false,
                fileURL: nil,
                fileName: fileName,
                format: format,
                error: .unknownError(error.localizedDescription)
            )
        }
    }
    
    // MARK: - Equipment Export
    
    func exportEquipment(
        _ equipment: [Equipment],
        format: ExportFormat
    ) async -> ExportResult {
        let fileName = "equipment_inventory_\(Date().formatted(date: .abbreviated, time: .omitted).replacingOccurrences(of: "/", with: "-")).\(format.fileExtension)"
        
        do {
            let content: String
            
            switch format {
            case .csv:
                content = try generateEquipmentCSV(equipment)
            case .json:
                content = try generateEquipmentJSON(equipment)
            case .txt:
                content = try generateEquipmentTXT(equipment)
            case .pdf:
                return ExportResult(
                    success: false,
                    fileURL: nil,
                    fileName: fileName,
                    format: format,
                    error: .unknownError("PDF export not yet implemented")
                )
            }
            
            let fileURL = try await saveToFile(content: content, fileName: fileName)
            
            return ExportResult(
                success: true,
                fileURL: fileURL,
                fileName: fileName,
                format: format,
                error: nil
            )
            
        } catch {
            return ExportResult(
                success: false,
                fileURL: nil,
                fileName: fileName,
                format: format,
                error: .unknownError(error.localizedDescription)
            )
        }
    }
    
    // MARK: - Business Report Export
    
    func exportBusinessReport(
        jobs: [SolarJob],
        customers: [Customer],
        equipment: [Equipment],
        installations: [Installation],
        format: ExportFormat
    ) async -> ExportResult {
        let fileName = "business_report_\(Date().formatted(date: .abbreviated, time: .omitted).replacingOccurrences(of: "/", with: "-")).\(format.fileExtension)"
        
        do {
            let content: String
            
            switch format {
            case .csv:
                content = try generateBusinessReportCSV(jobs: jobs, customers: customers, equipment: equipment, installations: installations)
            case .json:
                content = try generateBusinessReportJSON(jobs: jobs, customers: customers, equipment: equipment, installations: installations)
            case .txt:
                content = try generateBusinessReportTXT(jobs: jobs, customers: customers, equipment: equipment, installations: installations)
            case .pdf:
                return ExportResult(
                    success: false,
                    fileURL: nil,
                    fileName: fileName,
                    format: format,
                    error: .unknownError("PDF export not yet implemented")
                )
            }
            
            let fileURL = try await saveToFile(content: content, fileName: fileName)
            
            return ExportResult(
                success: true,
                fileURL: fileURL,
                fileName: fileName,
                format: format,
                error: nil
            )
            
        } catch {
            return ExportResult(
                success: false,
                fileURL: nil,
                fileName: fileName,
                format: format,
                error: .unknownError(error.localizedDescription)
            )
        }
    }
    
    // MARK: - CSV Generation
    
    private func generateJobsCSV(_ jobs: [SolarJob], includeDetails: Bool) throws -> String {
        var csv = "Customer Name,Address,System Size (kW),Status,Created Date,Scheduled Date,Estimated Revenue,Notes\n"
        
        for job in jobs {
            let scheduledDate = job.scheduledDate?.formatted(date: .abbreviated, time: .omitted) ?? ""
            let notes = includeDetails ? job.notes.replacingOccurrences(of: "\n", with: " ") : ""
            
            csv += "\"\(job.customerName)\",\"\(job.address)\",\(job.systemSize),\(job.status.rawValue),\(job.createdDate.formatted(date: .abbreviated, time: .omitted)),\"\(scheduledDate)\",\(job.estimatedRevenue),\"\(notes)\"\n"
        }
        
        return csv
    }
    
    private func generateCustomersCSV(_ customers: [Customer], includeJobHistory: Bool) throws -> String {
        var csv = "Name,Email,Phone,Address,Lead Status,Created Date,Total Jobs,Total Revenue\n"
        
        for customer in customers {
            let totalJobs = customer.jobs?.count ?? 0
            let totalRevenue = customer.jobs?.reduce(0) { $0 + $1.estimatedRevenue } ?? 0
            
            csv += "\"\(customer.name)\",\"\(customer.email)\",\"\(customer.phone)\",\"\(customer.address)\",\(customer.leadStatus.rawValue),\(customer.createdDate.formatted(date: .abbreviated, time: .omitted)),\(totalJobs),\(totalRevenue)\n"
        }
        
        return csv
    }
    
    private func generateEquipmentCSV(_ equipment: [Equipment]) throws -> String {
        var csv = "Name,Category,Brand,Model,Quantity,Unit Cost,Minimum Stock,Total Value,Low Stock\n"
        
        for item in equipment {
            let totalValue = item.unitCost * Double(item.quantity)
            let lowStock = item.isLowStock ? "Yes" : "No"
            
            csv += "\"\(item.name)\",\(item.category.rawValue),\"\(item.brand)\",\"\(item.model)\",\(item.quantity),\(item.unitCost),\(item.minimumStock),\(totalValue),\(lowStock)\n"
        }
        
        return csv
    }
    
    // MARK: - JSON Generation
    
    private func generateJobsJSON(_ jobs: [SolarJob], includeDetails: Bool) throws -> String {
        let jobsData = jobs.map { job in
            var data: [String: Any] = [
                "id": job.id.uuidString,
                "customerName": job.customerName,
                "address": job.address,
                "systemSize": job.systemSize,
                "status": job.status.rawValue,
                "createdDate": job.createdDate.ISO8601Format(),
                "estimatedRevenue": job.estimatedRevenue
            ]
            
            if let scheduledDate = job.scheduledDate {
                data["scheduledDate"] = scheduledDate.ISO8601Format()
            }
            
            if includeDetails && !job.notes.isEmpty {
                data["notes"] = job.notes
            }
            
            return data
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: jobsData, options: .prettyPrinted)
        return String(data: jsonData, encoding: .utf8) ?? ""
    }
    
    private func generateCustomersJSON(_ customers: [Customer], includeJobHistory: Bool) throws -> String {
        let customersData = customers.map { customer in
            var data: [String: Any] = [
                "id": customer.id.uuidString,
                "name": customer.name,
                "email": customer.email,
                "phone": customer.phone,
                "address": customer.address,
                "leadStatus": customer.leadStatus.rawValue,
                "createdDate": customer.createdDate.ISO8601Format()
            ]
            
            if includeJobHistory, let jobs = customer.jobs {
                data["totalJobs"] = jobs.count
                data["totalRevenue"] = jobs.reduce(0) { $0 + $1.estimatedRevenue }
            }
            
            return data
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: customersData, options: .prettyPrinted)
        return String(data: jsonData, encoding: .utf8) ?? ""
    }
    
    private func generateEquipmentJSON(_ equipment: [Equipment]) throws -> String {
        let equipmentData = equipment.map { item in
            [
                "id": item.id.uuidString,
                "name": item.name,
                "category": item.category.rawValue,
                "brand": item.brand,
                "model": item.model,
                "quantity": item.quantity,
                "unitCost": item.unitCost,
                "minimumStock": item.minimumStock,
                "totalValue": item.totalValue,
                "isLowStock": item.isLowStock
            ]
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: equipmentData, options: .prettyPrinted)
        return String(data: jsonData, encoding: .utf8) ?? ""
    }
    
    // MARK: - Text Generation
    
    private func generateJobsTXT(_ jobs: [SolarJob], includeDetails: Bool) throws -> String {
        var txt = "SOLAR JOBS REPORT\n"
        txt += "Generated: \(Date().formatted(date: .complete, time: .shortened))\n"
        txt += "Total Jobs: \(jobs.count)\n\n"
        txt += String(repeating: "=", count: 80) + "\n\n"
        
        for job in jobs {
            txt += "Customer: \(job.customerName)\n"
            txt += "Address: \(job.address)\n"
            txt += "System Size: \(job.systemSize) kW\n"
            txt += "Status: \(job.status.rawValue)\n"
            txt += "Created: \(job.createdDate.formatted(date: .abbreviated, time: .omitted))\n"
            
            if let scheduledDate = job.scheduledDate {
                txt += "Scheduled: \(scheduledDate.formatted(date: .abbreviated, time: .omitted))\n"
            }
            
            txt += "Estimated Revenue: $\(job.estimatedRevenue.safeValue, specifier: "%.2f")\n"
            
            if includeDetails && !job.notes.isEmpty {
                txt += "Notes: \(job.notes)\n"
            }
            
            txt += "\n" + String(repeating: "-", count: 40) + "\n\n"
        }
        
        return txt
    }
    
    private func generateCustomersTXT(_ customers: [Customer], includeJobHistory: Bool) throws -> String {
        var txt = "CUSTOMERS REPORT\n"
        txt += "Generated: \(Date().formatted(date: .complete, time: .shortened))\n"
        txt += "Total Customers: \(customers.count)\n\n"
        txt += String(repeating: "=", count: 80) + "\n\n"
        
        for customer in customers {
            txt += "Name: \(customer.name)\n"
            txt += "Email: \(customer.email)\n"
            txt += "Phone: \(customer.phone)\n"
            txt += "Address: \(customer.address)\n"
            txt += "Lead Status: \(customer.leadStatus.rawValue)\n"
            txt += "Created: \(customer.createdDate.formatted(date: .abbreviated, time: .omitted))\n"
            
            if includeJobHistory, let jobs = customer.jobs {
                txt += "Total Jobs: \(jobs.count)\n"
                txt += "Total Revenue: $\(jobs.reduce(0) { $0 + $1.estimatedRevenue.safeValue }, specifier: "%.2f")\n"
            }
            
            txt += "\n" + String(repeating: "-", count: 40) + "\n\n"
        }
        
        return txt
    }
    
    private func generateEquipmentTXT(_ equipment: [Equipment]) throws -> String {
        var txt = "EQUIPMENT INVENTORY REPORT\n"
        txt += "Generated: \(Date().formatted(date: .complete, time: .shortened))\n"
        txt += "Total Items: \(equipment.count)\n\n"
        txt += String(repeating: "=", count: 80) + "\n\n"
        
        for item in equipment {
            txt += "Name: \(item.name)\n"
            txt += "Category: \(item.category.rawValue)\n"
            txt += "Brand: \(item.brand)\n"
            txt += "Model: \(item.model)\n"
            txt += "Quantity: \(item.quantity)\n"
            txt += "Unit Cost: $\(item.unitPrice.safeValue, specifier: "%.2f")\n"
            txt += "Minimum Stock: \(item.minimumStock)\n"
            txt += "Total Value: $\(item.totalValue.safeValue, specifier: "%.2f")\n"
            txt += "Low Stock: \(item.isLowStock ? "Yes" : "No")\n"
            txt += "\n" + String(repeating: "-", count: 40) + "\n\n"
        }
        
        return txt
    }
    
    // MARK: - Business Report Generation
    
    private func generateBusinessReportTXT(jobs: [SolarJob], customers: [Customer], equipment: [Equipment], installations: [Installation]) throws -> String {
        var txt = "BUSINESS REPORT\n"
        txt += "Generated: \(Date().formatted(date: .complete, time: .shortened))\n\n"
        txt += String(repeating: "=", count: 80) + "\n\n"
        
        // Summary
        txt += "SUMMARY\n"
        txt += "Total Jobs: \(jobs.count)\n"
        txt += "Total Customers: \(customers.count)\n"
        txt += "Total Equipment Items: \(equipment.count)\n"
        txt += "Total Installations: \(installations.count)\n\n"
        
        // Job Statistics
        let completedJobs = jobs.filter { $0.status == .completed }
        let totalRevenue = completedJobs.reduce(0) { $0 + $1.estimatedRevenue }
        let pendingRevenue = jobs.filter { $0.status != .completed && $0.status != .cancelled }.reduce(0) { $0 + $1.estimatedRevenue }
        
        txt += "JOB STATISTICS\n"
        txt += "Completed Jobs: \(completedJobs.count)\n"
        txt += "Active Jobs: \(jobs.filter { $0.status == .inProgress }.count)\n"
        txt += "Pending Jobs: \(jobs.filter { $0.status == .pending }.count)\n"
        txt += "Total Revenue: $\(totalRevenue.safeValue, specifier: "%.2f")\n"
        txt += "Pending Revenue: $\(pendingRevenue.safeValue, specifier: "%.2f")\n\n"
        
        // Equipment Statistics
        let lowStockItems = equipment.filter { $0.isLowStock }
        let totalEquipmentValue = equipment.reduce(0) { $0 + $1.totalValue }
        
        txt += "EQUIPMENT STATISTICS\n"
        txt += "Total Equipment Value: $\(totalEquipmentValue.safeValue, specifier: "%.2f")\n"
        txt += "Low Stock Items: \(lowStockItems.count)\n"
        txt += "Out of Stock Items: \(equipment.filter { $0.quantity == 0 }.count)\n\n"
        
        return txt
    }
    
    private func generateBusinessReportJSON(jobs: [SolarJob], customers: [Customer], equipment: [Equipment], installations: [Installation]) throws -> String {
        let completedJobs = jobs.filter { $0.status == .completed }
        let totalRevenue = completedJobs.reduce(0) { $0 + $1.estimatedRevenue }
        let pendingRevenue = jobs.filter { $0.status != .completed && $0.status != .cancelled }.reduce(0) { $0 + $1.estimatedRevenue }
        let lowStockItems = equipment.filter { $0.isLowStock }
        let totalEquipmentValue = equipment.reduce(0) { $0 + $1.totalValue }
        
        let reportData: [String: Any] = [
            "generatedDate": Date().ISO8601Format(),
            "summary": [
                "totalJobs": jobs.count,
                "totalCustomers": customers.count,
                "totalEquipmentItems": equipment.count,
                "totalInstallations": installations.count
            ],
            "jobStatistics": [
                "completedJobs": completedJobs.count,
                "activeJobs": jobs.filter { $0.status == .inProgress }.count,
                "pendingJobs": jobs.filter { $0.status == .pending }.count,
                "totalRevenue": totalRevenue,
                "pendingRevenue": pendingRevenue
            ],
            "equipmentStatistics": [
                "totalValue": totalEquipmentValue,
                "lowStockItems": lowStockItems.count,
                "outOfStockItems": equipment.filter { $0.quantity == 0 }.count
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: reportData, options: .prettyPrinted)
        return String(data: jsonData, encoding: .utf8) ?? ""
    }
    
    private func generateBusinessReportCSV(jobs: [SolarJob], customers: [Customer], equipment: [Equipment], installations: [Installation]) throws -> String {
        let completedJobs = jobs.filter { $0.status == .completed }
        let totalRevenue = completedJobs.reduce(0) { $0 + $1.estimatedRevenue }
        let pendingRevenue = jobs.filter { $0.status != .completed && $0.status != .cancelled }.reduce(0) { $0 + $1.estimatedRevenue }
        let lowStockItems = equipment.filter { $0.isLowStock }
        let totalEquipmentValue = equipment.reduce(0) { $0 + $1.totalValue }
        
        var csv = "Metric,Value\n"
        csv += "Generated Date,\(Date().formatted(date: .complete, time: .shortened))\n"
        csv += "Total Jobs,\(jobs.count)\n"
        csv += "Total Customers,\(customers.count)\n"
        csv += "Total Equipment Items,\(equipment.count)\n"
        csv += "Total Installations,\(installations.count)\n"
        csv += "Completed Jobs,\(completedJobs.count)\n"
        csv += "Active Jobs,\(jobs.filter { $0.status == .inProgress }.count)\n"
        csv += "Pending Jobs,\(jobs.filter { $0.status == .pending }.count)\n"
        csv += "Total Revenue,\(totalRevenue)\n"
        csv += "Pending Revenue,\(pendingRevenue)\n"
        csv += "Total Equipment Value,\(totalEquipmentValue)\n"
        csv += "Low Stock Items,\(lowStockItems.count)\n"
        csv += "Out of Stock Items,\(equipment.filter { $0.quantity == 0 }.count)\n"
        
        return csv
    }
    
    // MARK: - File Management
    
    private func saveToFile(content: String, fileName: String) async throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    func getExportsDirectory() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("Exports")
    }
    
    func createExportsDirectory() throws {
        let exportsDirectory = getExportsDirectory()
        try FileManager.default.createDirectory(at: exportsDirectory, withIntermediateDirectories: true)
    }
    
    func deleteExportFile(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
    
    func getExportFiles() throws -> [URL] {
        let exportsDirectory = getExportsDirectory()
        let files = try FileManager.default.contentsOfDirectory(at: exportsDirectory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
        return files.sorted { url1, url2 in
            let date1 = try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
            let date2 = try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
            return date1 ?? Date.distantPast > date2 ?? Date.distantPast
        }
    }
}