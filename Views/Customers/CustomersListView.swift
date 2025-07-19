import SwiftUI
import SwiftData

struct CustomersListView: View {
    @Environment(\.viewModelContainer) private var viewModelContainer
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Customer.createdDate, order: .reverse) private var customers: [Customer]
    @State private var searchText = ""
    @State private var selectedLeadStatus: LeadStatus?
    @State private var showingAddCustomer = false
    @State private var showingCustomerDetail = false
    @State private var selectedCustomer: Customer?
    @State private var errorMessage: String?
    
    // Computed property for filtered customers
    private var filteredCustomers: [Customer] {
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
        
        return filtered
    }
    
    private var viewModel: CustomersViewModel {
        viewModelContainer?.customersViewModel ?? CustomersViewModel(
            dataService: DataService(modelContext: modelContext)
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        // Filter Section
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FilterChip(
                                    title: "All",
                                    isSelected: selectedLeadStatus == nil
                                ) {
                                    selectedLeadStatus = nil
                                }
                                
                                ForEach(LeadStatus.allCases, id: \.self) { status in
                                    FilterChip(
                                        title: status.rawValue,
                                        isSelected: selectedLeadStatus == status,
                                        count: customers.filter { $0.leadStatus == status }.count
                                    ) {
                                        selectedLeadStatus = selectedLeadStatus == status ? nil : status
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        
                        // Customers List
                        List {
                            ForEach(filteredCustomers, id: \.id) { customer in
                                Button(action: {
                                    showCustomerDetail(customer)
                                }) {
                                    CustomerRowView(customer: customer) { newStatus in
                                        updateCustomerLeadStatus(customer, to: newStatus)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .onDelete(perform: deleteCustomers)
                        }
                        .searchable(text: $searchText, prompt: "Search customers...")
                    }
                }
            }
            .navigationTitle("Customers (\(filteredCustomers.count))")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu("Export") {
                        Button("Export as CSV") {
                            viewModel.exportCustomers(format: .csv)
                        }
                        Button("Export as JSON") {
                            viewModel.exportCustomers(format: .json)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCustomer = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCustomer) {
                AddCustomerView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingCustomerDetail) {
                if let customer = selectedCustomer {
                    CustomerDetailView(customer: customer)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private func deleteCustomers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let customer = filteredCustomers[index]
                modelContext.delete(customer)
                do {
                    try modelContext.save()
                } catch {
                    errorMessage = "Failed to delete customer: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func showCustomerDetail(_ customer: Customer) {
        selectedCustomer = customer
        showingCustomerDetail = true
    }
    
    private func updateCustomerLeadStatus(_ customer: Customer, to newStatus: LeadStatus) {
        customer.leadStatus = newStatus
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to update lead status: \(error.localizedDescription)"
        }
    }
}

struct CustomerRowView: View {
    let customer: Customer
    let onStatusChange: ((LeadStatus) -> Void)?
    
    init(customer: Customer, onStatusChange: ((LeadStatus) -> Void)? = nil) {
        self.customer = customer
        self.onStatusChange = onStatusChange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(customer.name)
                        .font(.headline)
                    
                    Text(customer.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let onStatusChange = onStatusChange {
                        Menu {
                            ForEach(LeadStatus.allCases, id: \.self) { status in
                                Button(status.rawValue) {
                                    onStatusChange(status)
                                }
                            }
                        } label: {
                            StatusBadge(status: customer.leadStatus.rawValue, color: Color(customer.leadStatus.color))
                        }
                    } else {
                        StatusBadge(status: customer.leadStatus.rawValue, color: Color(customer.leadStatus.color))
                    }
                }
            }
            
            HStack {
                Label(customer.phone, systemImage: "phone")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(customer.createdDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddCustomerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: CustomersViewModel
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var leadStatus: LeadStatus = .newLead
    @State private var notes = ""
    @State private var errorMessage: String?
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Customer Information") {
                    TextField("Full Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Email Address", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone Number", text: $phone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                    
                    TextField("Address", text: $address)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section("Lead Information") {
                    Picker("Lead Status", selection: $leadStatus) {
                        ForEach(LeadStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Notes") {
                    TextField("Additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Validation Errors
                if let errorMessage = errorMessage {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Customer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCustomer()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func saveCustomer() {
        let customer = Customer(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            leadStatus: leadStatus,
            notes: notes
        )
        
        modelContext.insert(customer)
        
        do {
            try modelContext.save()
            print("✅ Customer saved successfully: \(customer.name)")
            dismiss()
        } catch {
            errorMessage = "Failed to save customer: \(error.localizedDescription)"
            print("❌ Failed to save customer: \(error)")
        }
    }
}

// Placeholder views that need to be implemented
struct CustomerDetailView: View {
    let customer: Customer
    
    var body: some View {
        Text("Customer Detail: \(customer.name)")
            .navigationTitle("Customer Details")
    }
}

#Preview {
    let container = try! ModelContainer(for: Customer.self, SolarJob.self, Equipment.self, Installation.self, Vendor.self, Contract.self)
    let dataService = DataService(modelContext: container.mainContext)
    let viewModel = CustomersViewModel(dataService: dataService)
    
    return CustomersListView(viewModel: viewModel)
        .modelContainer(container)
}