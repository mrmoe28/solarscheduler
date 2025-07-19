import SwiftUI
import SwiftData

struct AddJobView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var customers: [Customer]
    
    // Form state
    @State private var customerName = ""
    @State private var selectedCustomer: Customer?
    @State private var address = ""
    @State private var systemSize = ""
    @State private var selectedStatus: JobStatus = .pending
    @State private var scheduledDate = Date()
    @State private var hasScheduledDate = false
    @State private var estimatedRevenue = ""
    @State private var notes = ""
    
    // UI state
    @State private var showingCustomerPicker = false
    @State private var isNewCustomer = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Editing mode
    let jobToEdit: SolarJob?
    
    init(jobToEdit: SolarJob? = nil) {
        self.jobToEdit = jobToEdit
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Customer Section
                Section("Customer Information") {
                    // Customer selection toggle
                    Picker("Customer Type", selection: $isNewCustomer) {
                        Text("New Customer").tag(true)
                        Text("Existing Customer").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if isNewCustomer {
                        TextField("Customer Name", text: $customerName)
                            .textContentType(.name)
                    } else {
                        HStack {
                            Text("Customer")
                            Spacer()
                            if let selectedCustomer = selectedCustomer {
                                Text(selectedCustomer.name)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Select Customer")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingCustomerPicker = true
                        }
                    }
                    
                    TextField("Installation Address", text: $address, axis: .vertical)
                        .textContentType(.fullStreetAddress)
                        .lineLimit(2...4)
                }
                
                // System Details
                Section("System Details") {
                    HStack {
                        TextField("System Size", text: $systemSize)
                            .keyboardType(.decimalPad)
                        Text("kW")
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(JobStatus.allCases, id: \.self) { status in
                            Label(status.rawValue, systemImage: statusIcon(for: status))
                                .tag(status)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Scheduling
                Section("Scheduling") {
                    Toggle("Schedule Installation Date", isOn: $hasScheduledDate)
                    
                    if hasScheduledDate {
                        DatePicker("Scheduled Date", selection: $scheduledDate, in: Date()..., displayedComponents: [.date])
                            .datePickerStyle(GraphicalDatePickerStyle())
                    }
                }
                
                // Financial
                Section("Financial Information") {
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("Estimated Revenue", text: $estimatedRevenue)
                            .keyboardType(.decimalPad)
                    }
                }
                
                // Additional Information
                Section("Additional Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle(jobToEdit == nil ? "New Solar Job" : "Edit Job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(jobToEdit == nil ? "Create" : "Save") {
                        saveJob()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                loadJobData()
            }
            .sheet(isPresented: $showingCustomerPicker) {
                CustomerPickerView(selectedCustomer: $selectedCustomer)
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        let hasCustomer = isNewCustomer ? !customerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : selectedCustomer != nil
        let hasAddress = !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasSystemSize = !systemSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && Double(systemSize) != nil
        
        return hasCustomer && hasAddress && hasSystemSize
    }
    
    private func statusIcon(for status: JobStatus) -> String {
        switch status {
        case .pending: return "clock"
        case .approved: return "checkmark.circle"
        case .inProgress: return "hammer"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        case .onHold: return "pause.circle"
        }
    }
    
    private func loadJobData() {
        guard let job = jobToEdit else { return }
        
        // Load existing job data for editing
        if let customer = job.customer {
            selectedCustomer = customer
            isNewCustomer = false
        } else {
            customerName = job.customerName
            isNewCustomer = true
        }
        
        address = job.address
        systemSize = String(job.systemSize)
        selectedStatus = job.status
        
        if let scheduledDate = job.scheduledDate {
            self.scheduledDate = scheduledDate
            hasScheduledDate = true
        }
        
        estimatedRevenue = job.estimatedRevenue > 0 ? String(job.estimatedRevenue) : ""
        notes = job.notes
    }
    
    private func saveJob() {
        guard isFormValid else {
            alertMessage = "Please fill in all required fields."
            showingAlert = true
            return
        }
        
        guard let systemSizeValue = Double(systemSize) else {
            alertMessage = "Please enter a valid system size."
            showingAlert = true
            return
        }
        
        let revenueValue = Double(estimatedRevenue) ?? 0.0
        
        do {
            if let jobToEdit = jobToEdit {
                // Update existing job
                updateExistingJob(jobToEdit, systemSize: systemSizeValue, revenue: revenueValue)
            } else {
                // Create new job
                createNewJob(systemSize: systemSizeValue, revenue: revenueValue)
            }
            
            try modelContext.save()
            dismiss()
            
        } catch {
            alertMessage = "Failed to save job: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func updateExistingJob(_ job: SolarJob, systemSize: Double, revenue: Double) {
        if isNewCustomer {
            job.customerName = customerName.trimmingCharacters(in: .whitespacesAndNewlines)
            job.customer = nil
        } else {
            job.customer = selectedCustomer
            job.customerName = selectedCustomer?.name ?? ""
        }
        
        job.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        job.systemSize = systemSize
        job.status = selectedStatus
        job.scheduledDate = hasScheduledDate ? scheduledDate : nil
        job.estimatedRevenue = revenue
        job.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func createNewJob(systemSize: Double, revenue: Double) {
        let job = SolarJob(
            customerName: isNewCustomer ? customerName.trimmingCharacters(in: .whitespacesAndNewlines) : selectedCustomer?.name ?? "",
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            systemSize: systemSize,
            status: selectedStatus,
            scheduledDate: hasScheduledDate ? scheduledDate : nil,
            estimatedRevenue: revenue,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        if !isNewCustomer, let selectedCustomer = selectedCustomer {
            job.customer = selectedCustomer
        }
        
        modelContext.insert(job)
    }
}

// MARK: - Customer Picker View

struct CustomerPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var customers: [Customer]
    @Binding var selectedCustomer: Customer?
    @State private var searchText = ""
    
    var filteredCustomers: [Customer] {
        if searchText.isEmpty {
            return customers
        } else {
            return customers.filter { customer in
                customer.name.localizedCaseInsensitiveContains(searchText) ||
                customer.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCustomers) { customer in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(customer.name)
                                .font(.headline)
                            
                            Text(customer.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if !customer.address.isEmpty {
                                Text(customer.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        if selectedCustomer?.id == customer.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCustomer = customer
                        dismiss()
                    }
                }
            }
            .navigationTitle("Select Customer")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search customers")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if filteredCustomers.isEmpty {
                    ContentUnavailableView(
                        "No Customers Found",
                        systemImage: "person.slash",
                        description: Text(searchText.isEmpty ? "No customers available. Add customers first." : "No customers match your search.")
                    )
                }
            }
        }
    }
}

#Preview {
    AddJobView()
        .modelContainer(for: [SolarJob.self, Customer.self])
}

#Preview("Edit Mode") {
    let job = SolarJob(
        customerName: "John Doe",
        address: "123 Main St, Anytown, USA",
        systemSize: 10.5,
        estimatedRevenue: 25000.0,
        notes: "Sample job for preview"
    )
    
    return AddJobView(jobToEdit: job)
        .modelContainer(for: [SolarJob.self, Customer.self])
}