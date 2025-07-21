import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct CustomersListView: View {
    @Environment(\.viewModelContainer) private var viewModelContainer
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Customer.createdDate, order: .reverse) private var customers: [Customer]
    
    @State private var viewModel: CustomersViewModel?
    
    private var currentViewModel: CustomersViewModel {
        if let vm = viewModel {
            return vm
        } else {
            let dataService = DataService(modelContext: modelContext)
            let newViewModel = CustomersViewModel(dataService: dataService)
            viewModel = newViewModel
            return newViewModel
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    // Filter Section
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(
                                title: "All",
                                isSelected: currentViewModel.selectedLeadStatus == nil
                            ) {
                                currentViewModel.updateSelectedLeadStatus(nil)
                            }
                            
                            ForEach(LeadStatus.allCases, id: \.self) { status in
                                FilterChip(
                                    title: status.rawValue,
                                    isSelected: currentViewModel.selectedLeadStatus == status,
                                    count: currentViewModel.getCustomersCount(for: status)
                                ) {
                                    currentViewModel.updateSelectedLeadStatus(currentViewModel.selectedLeadStatus == status ? nil : status)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    
                    // Customers List
                    List {
                        ForEach(currentViewModel.filteredCustomers, id: \.id) { customer in
                            Button(action: {
                                currentViewModel.showCustomerDetail(customer)
                            }) {
                                CustomerRowView(customer: customer) { newStatus in
                                    currentViewModel.updateCustomerLeadStatus(customer, to: newStatus)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .onDelete(perform: deleteCustomers)
                    }
                    .searchable(text: Binding(
                        get: { currentViewModel.searchText },
                        set: { currentViewModel.updateSearchText($0) }
                    ), prompt: "Search customers...")
                }
            }
        }
        .navigationTitle("Customers (\(currentViewModel.filteredCustomers.count))")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu("Export") {
                    Button("Export as CSV") {
                        currentViewModel.exportCustomers(format: .csv)
                    }
                    Button("Export as JSON") {
                        currentViewModel.exportCustomers(format: .json)
                    }
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: { currentViewModel.showAddCustomer() }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .sheet(isPresented: Binding(
            get: { currentViewModel.showingAddCustomer },
            set: { currentViewModel.showingAddCustomer = $0 }
        )) {
            AddCustomerView(viewModel: currentViewModel)
        }
        .sheet(isPresented: Binding(
            get: { currentViewModel.showingCustomerDetail },
            set: { currentViewModel.showingCustomerDetail = $0 }
        )) {
            if let customer = currentViewModel.selectedCustomer {
                CustomerDetailView(customer: customer)
            }
        }
        .alert("Error", isPresented: .constant(currentViewModel.errorMessage != nil)) {
            Button("OK") {
                currentViewModel.errorMessage = nil
            }
        } message: {
            Text(currentViewModel.errorMessage ?? "")
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: { currentViewModel.showAddCustomer() }) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.orange)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 100)
            .zIndex(1000)
        }
        .onAppear {
            currentViewModel.loadCustomers()
        }
        .onChange(of: currentViewModel.showingAddCustomer) { _, newValue in
            if !newValue {
                // Refresh customers list when add customer sheet is dismissed
                currentViewModel.loadCustomers()
            }
        }
    }
    
    private func deleteCustomers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let customer = currentViewModel.filteredCustomers[index]
                currentViewModel.deleteCustomer(customer)
            }
        }
    }
}

struct CustomerRowView: View {
    let customer: Customer
    let onStatusChange: ((LeadStatus) -> Void)?
    @State private var showingDetail = false
    @State private var showingDeleteAlert = false
    @State private var showShareSheet = false
    @Environment(\.modelContext) private var modelContext
    
    init(customer: Customer, onStatusChange: ((LeadStatus) -> Void)? = nil) {
        self.customer = customer
        self.onStatusChange = onStatusChange
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Main content - clickable
            Button(action: { showingDetail = true }) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(customer.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
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
                                    StatusBadge(status: customer.leadStatus.rawValue, color: customer.leadStatus.color)
                                }
                            } else {
                                StatusBadge(status: customer.leadStatus.rawValue, color: customer.leadStatus.color)
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
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Action buttons
            HStack(spacing: 16) {
                // View button
                Button(action: { showingDetail = true }) {
                    Image(systemName: "eye")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
                
                // Share button
                Button(action: { showShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                }
                
                // Delete button
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color.secondaryBackground)
        .cornerRadius(8)
        .sheet(isPresented: $showingDetail) {
            CustomerDetailView(customer: customer)
        }
        .alert("Delete Customer", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(customer)
                try? modelContext.save()
            }
        } message: {
            Text("Are you sure you want to delete this customer? This will also delete all associated jobs.")
        }
        #if os(iOS)
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(items: [customer.shareText])
        }
        #endif
    }
}

struct AddCustomerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: CustomersViewModel
    @State private var userSession = UserSession.shared
    
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
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Email Address", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone Number", text: $phone)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.phonePad)
                    
                    TextField("Address", text: $address)
                        .textFieldStyle(.roundedBorder)
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
            .onAppear {
                // Ensure UserSession is configured
                if userSession.currentUser == nil {
                    userSession.configure(with: modelContext)
                }
                print("👤 Current user: \(userSession.currentUser?.fullName ?? "None")")
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button("Save") {
                        saveCustomer()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func saveCustomer() {
        // Check if user is logged in
        guard userSession.currentUser != nil else {
            errorMessage = "You must be logged in to create a customer."
            print("❌ Error: No current user found in session")
            return
        }
        
        let customer = Customer(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            leadStatus: leadStatus,
            notes: notes
        )
        
        // Associate with current user
        customer.user = userSession.currentUser
        
        modelContext.insert(customer)
        
        do {
            try modelContext.save()
            print("✅ Customer saved successfully: \(customer.name)")
            print("👤 Associated with user: \(userSession.currentUser?.fullName ?? "Unknown")")
            dismiss()
        } catch {
            errorMessage = "Failed to save customer: \(error.localizedDescription)"
            print("❌ Failed to save customer: \(error)")
        }
    }
}

// MARK: - Customer Detail View
struct CustomerDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var customer: Customer
    @State private var showingEditCustomer = false
    @State private var showingDeleteAlert = false
    @State private var showingAddJob = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(customer.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(customer.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        StatusBadge(status: customer.leadStatus.rawValue, color: customer.leadStatus.color)
                    }
                    
                    VStack(spacing: 12) {
                        CustomerInfoRow(icon: "phone", label: "Phone", value: customer.phone)
                        CustomerInfoRow(icon: "location", label: "Address", value: customer.address)
                        CustomerInfoRow(icon: "envelope", label: "Contact Method", value: customer.preferredContactMethod.rawValue)
                        CustomerInfoRow(icon: "calendar", label: "Customer Since", value: customer.createdDate.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                .padding(20)
                .background(Color.secondaryBackground)
                .cornerRadius(12)
                
                // Lead Status Management
                VStack(alignment: .leading, spacing: 12) {
                    Text("Lead Status")
                        .font(.headline)
                    
                    Menu {
                        ForEach(LeadStatus.allCases, id: \.self) { status in
                            Button(status.rawValue) {
                                withAnimation {
                                    customer.leadStatus = status
                                    saveChanges()
                                }
                            }
                        }
                    } label: {
                        HStack {
                            StatusBadge(status: customer.leadStatus.rawValue, color: customer.leadStatus.color)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(Color.secondaryBackground)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Associated Jobs
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Associated Jobs")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Add Job") {
                            showingAddJob = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    }
                    
                    if customer.jobs.isEmpty {
                        Text("No jobs found for this customer")
                            .foregroundColor(.secondary)
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(Color.secondaryBackground)
                            .cornerRadius(12)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(customer.jobs, id: \.id) { job in
                                CustomerJobRow(job: job)
                            }
                        }
                    }
                }
                
                // Notes Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes")
                        .font(.headline)
                    
                    TextField("Add notes about this customer...", text: $customer.notes, axis: .vertical)
                        .lineLimit(3...8)
                        .padding(16)
                        .background(Color.secondaryBackground)
                        .cornerRadius(12)
                        .onChange(of: customer.notes) { _, _ in
                            saveChanges()
                        }
                }
                
                // Quick Actions
                VStack(spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 8) {
                        CustomerActionButton(
                            icon: "phone",
                            title: "Call Customer",
                            color: .green
                        ) {
                            if let url = URL(string: "tel:\(customer.phone)") {
                                #if os(iOS)
                                UIApplication.shared.open(url)
                                #elseif os(macOS)
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(customer.phone, forType: .string)
                                #endif
                            }
                        }
                        
                        CustomerActionButton(
                            icon: "envelope",
                            title: "Send Email",
                            color: .blue
                        ) {
                            if let url = URL(string: "mailto:\(customer.email)") {
                                #if os(iOS)
                                UIApplication.shared.open(url)
                                #elseif os(macOS)
                                NSWorkspace.shared.open(url)
                                #endif
                            }
                        }
                        
                        CustomerActionButton(
                            icon: "message",
                            title: "Send Text Message",
                            color: .purple
                        ) {
                            if let url = URL(string: "sms:\(customer.phone)") {
                                #if os(iOS)
                                UIApplication.shared.open(url)
                                #elseif os(macOS)
                                // SMS not available on macOS, copy number instead
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(customer.phone, forType: .string)
                                #endif
                            }
                        }
                        
                        CustomerActionButton(
                            icon: "pencil",
                            title: "Edit Customer Details",
                            color: .orange
                        ) {
                            showingEditCustomer = true
                        }
                        
                        CustomerActionButton(
                            icon: "trash",
                            title: "Delete Customer",
                            color: .red
                        ) {
                            showingDeleteAlert = true
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(20)
        }
        .navigationTitle("Customer Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditCustomer) {
            EditCustomerView(customer: customer)
        }
        .sheet(isPresented: $showingAddJob) {
            // This would open job creation for this specific customer
            Text("Add Job for \(customer.name)")
        }
        .alert("Delete Customer", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteCustomer()
            }
        } message: {
            Text("Are you sure you want to delete this customer? This will also delete all associated jobs and cannot be undone.")
        }
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save customer changes: \(error)")
        }
    }
    
    private func deleteCustomer() {
        modelContext.delete(customer)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete customer: \(error)")
        }
    }
}

// MARK: - Customer Info Row
struct CustomerInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Customer Job Row
struct CustomerJobRow: View {
    let job: SolarJob
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(job.address)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(job.systemSize, specifier: "%.1f") kW • $\(job.estimatedRevenue, specifier: "%.0f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            StatusBadge(status: job.status.rawValue, color: job.status.color)
        }
        .padding(12)
        .background(Color.secondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Customer Action Button
struct CustomerActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color.secondaryBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Customer View
struct EditCustomerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var customer: Customer
    
    @State private var name: String
    @State private var email: String
    @State private var phone: String
    @State private var address: String
    @State private var leadStatus: LeadStatus
    @State private var preferredContactMethod: ContactMethod
    @State private var notes: String
    
    init(customer: Customer) {
        self.customer = customer
        self._name = State(initialValue: customer.name)
        self._email = State(initialValue: customer.email)
        self._phone = State(initialValue: customer.phone)
        self._address = State(initialValue: customer.address)
        self._leadStatus = State(initialValue: customer.leadStatus)
        self._preferredContactMethod = State(initialValue: customer.preferredContactMethod)
        self._notes = State(initialValue: customer.notes)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Full Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Address", text: $address)
                }
                
                Section("Lead Information") {
                    Picker("Lead Status", selection: $leadStatus) {
                        ForEach(LeadStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    
                    Picker("Preferred Contact", selection: $preferredContactMethod) {
                        ForEach(ContactMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Customer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !phone.isEmpty && !address.isEmpty
    }
    
    private func saveChanges() {
        customer.name = name
        customer.email = email
        customer.phone = phone
        customer.address = address
        customer.leadStatus = leadStatus
        customer.preferredContactMethod = preferredContactMethod
        customer.notes = notes
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save customer: \(error)")
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Customer.self, SolarJob.self, Equipment.self, Installation.self, Vendor.self, Contract.self)
    
    CustomersListView()
        .modelContainer(container)
}

// MARK: - Customer Extensions
extension Customer {
    var shareText: String {
        """
        Customer: \(name)
        Email: \(email)
        Phone: \(phone)
        Address: \(address)
        Lead Status: \(leadStatus.rawValue)
        """
    }
}

// MARK: - Activity View Controller for iOS
#if os(iOS)
import UIKit

struct ActivityViewController: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

