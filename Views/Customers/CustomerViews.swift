import SwiftUI
import SwiftData

// MARK: - Customers View
struct CustomersView: View {
    @State private var searchText = ""
    @State private var selectedFilter: CustomerFilter = .all
    @State private var showingAddCustomer = false
    @State private var selectedCustomer: SolarCustomer?
    
    enum CustomerFilter: String, CaseIterable {
        case all = "All"
        case leads = "Leads"
        case prospects = "Prospects"
        case customers = "Customers"
        case completed = "Completed"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter header
                customerHeader
                
                // Customer list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredCustomers, id: \.id) { customer in
                            CustomerCardView(customer: customer)
                                .onTapGesture {
                                    selectedCustomer = customer
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Customers")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCustomer = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showingAddCustomer) {
                AddCustomerSheet()
            }
            .sheet(item: $selectedCustomer) { customer in
                CustomerDetailSheet(customer: customer)
            }
        }
        .searchable(text: $searchText, prompt: "Search customers...")
    }
    
    // MARK: - Customer Header
    private var customerHeader: some View {
        VStack(spacing: 16) {
            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CustomerFilter.allCases, id: \.self) { filter in
                        FilterPill(
                            title: filter.rawValue,
                            count: customerCount(for: filter),
                            isSelected: selectedFilter == filter
                        )
                        .onTapGesture {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Quick stats
            HStack(spacing: 16) {
                CustomerStatView(
                    title: "Total Customers",
                    value: "\(sampleCustomers.count)",
                    icon: "person.2.fill",
                    color: .blue
                )
                
                CustomerStatView(
                    title: "This Month",
                    value: "\(newCustomersThisMonth)",
                    icon: "person.badge.plus",
                    color: .green
                )
                
                CustomerStatView(
                    title: "Pipeline Value",
                    value: "$\(totalPipelineValue)K",
                    icon: "dollarsign.circle",
                    color: .orange
                )
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Computed Properties
    private var filteredCustomers: [SolarCustomer] {
        let filtered = sampleCustomers.filter { customer in
            switch selectedFilter {
            case .all:
                return true
            case .leads:
                return customer.status == .lead
            case .prospects:
                return customer.status == .prospect
            case .customers:
                return customer.status == .customer
            case .completed:
                return customer.status == .completed
            }
        }
        
        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { customer in
                customer.name.localizedCaseInsensitiveContains(searchText) ||
                customer.email.localizedCaseInsensitiveContains(searchText) ||
                customer.address.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func customerCount(for filter: CustomerFilter) -> Int {
        switch filter {
        case .all:
            return sampleCustomers.count
        case .leads:
            return sampleCustomers.filter { $0.status == .lead }.count
        case .prospects:
            return sampleCustomers.filter { $0.status == .prospect }.count
        case .customers:
            return sampleCustomers.filter { $0.status == .customer }.count
        case .completed:
            return sampleCustomers.filter { $0.status == .completed }.count
        }
    }
    
    private var newCustomersThisMonth: Int {
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        return sampleCustomers.filter { $0.createdDate >= startOfMonth }.count
    }
    
    private var totalPipelineValue: Int {
        sampleCustomers.reduce(0) { total, customer in
            total + customer.estimatedValue
        } / 1000
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2))
                )
        }
        .foregroundColor(isSelected ? .white : .primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(isSelected ? Color.orange : Color(.systemGray6))
        )
    }
}

// MARK: - Customer Stat View
struct CustomerStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Customer Card View
struct CustomerCardView: View {
    let customer: SolarCustomer
    
    var body: some View {
        HStack(spacing: 16) {
            // Customer avatar
            ZStack {
                Circle()
                    .fill(customer.status.color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Text(customer.initials)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(customer.status.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(customer.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("$\(customer.estimatedValue / 1000)K")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                Text(customer.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Label(customer.systemSize, systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Text(customer.lastContact.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 8) {
                // Status badge
                Text(customer.status.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(customer.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(customer.status.color.opacity(0.1))
                    .cornerRadius(6)
                
                // Priority indicator
                if customer.priority == .high {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Add Customer Sheet
struct AddCustomerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var systemSize = ""
    @State private var estimatedValue = ""
    @State private var selectedStatus: LeadStatus = .newLead
    @State private var selectedPriority: SolarCustomer.Priority = .medium
    @State private var notes = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, phone, address, systemSize, estimatedValue, notes
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !phone.isEmpty && !address.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("Add New Customer")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    // Form sections
                    VStack(spacing: 24) {
                        // Contact Information
                        FormSection(title: "Contact Information", icon: "person.fill") {
                            CustomTextField(
                                title: "Full Name",
                                text: $name,
                                placeholder: "John Doe",
                                icon: "person"
                            )
                            .focused($focusedField, equals: .name)
                            .textContentType(.name)
                            
                            CustomTextField(
                                title: "Email Address",
                                text: $email,
                                placeholder: "john.doe@email.com",
                                icon: "envelope"
                            )
                            .focused($focusedField, equals: .email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            
                            CustomTextField(
                                title: "Phone Number",
                                text: $phone,
                                placeholder: "(555) 123-4567",
                                icon: "phone"
                            )
                            .focused($focusedField, equals: .phone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                        }
                        
                        // Address Information
                        FormSection(title: "Address", icon: "location.fill") {
                            CustomTextField(
                                title: "Full Address",
                                text: $address,
                                placeholder: "123 Main St, City, State, ZIP",
                                icon: "house"
                            )
                            .focused($focusedField, equals: .address)
                            .textContentType(.fullStreetAddress)
                        }
                        
                        // Project Information
                        FormSection(title: "Project Details", icon: "sun.max.fill") {
                            CustomTextField(
                                title: "System Size",
                                text: $systemSize,
                                placeholder: "8.5 kW",
                                icon: "bolt.fill"
                            )
                            .focused($focusedField, equals: .systemSize)
                            
                            CustomTextField(
                                title: "Estimated Value",
                                text: $estimatedValue,
                                placeholder: "25000",
                                icon: "dollarsign.circle"
                            )
                            .focused($focusedField, equals: .estimatedValue)
                            .keyboardType(.numberPad)
                        }
                        
                        // Status and Priority
                        FormSection(title: "Classification", icon: "flag.fill") {
                            VStack(spacing: 16) {
                                // Status Picker
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                        Text("Customer Status")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach([LeadStatus.newLead, .contacted, .qualified], id: \.self) { status in
                                                StatusPill(
                                                    title: status.rawValue,
                                                    color: getLeadStatusColor(status),
                                                    isSelected: selectedStatus == status
                                                )
                                                .onTapGesture {
                                                    selectedStatus = status
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 2)
                                    }
                                }
                                
                                // Priority Picker
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                        Text("Priority Level")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach([SolarCustomer.Priority.low, .medium, .high], id: \.self) { priority in
                                                PriorityPill(
                                                    title: priority.rawValue,
                                                    priority: priority,
                                                    isSelected: selectedPriority == priority
                                                )
                                                .onTapGesture {
                                                    selectedPriority = priority
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 2)
                                    }
                                }
                            }
                        }
                        
                        // Notes
                        FormSection(title: "Notes", icon: "note.text") {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    Text("Additional Notes")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                TextEditor(text: $notes)
                                    .frame(minHeight: 80)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .focused($focusedField, equals: .notes)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Customer") {
                        saveCustomer()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? .orange : .secondary)
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func saveCustomer() {
        guard isFormValid else { return }
        
        let newCustomer = Customer(
            name: name,
            email: email,
            phone: phone,
            address: address,
            leadStatus: selectedStatus
        )
        
        modelContext.insert(newCustomer)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save customer: \(error)")
        }
    }
    
    private func getLeadStatusColor(_ status: LeadStatus) -> Color {
        switch status {
        case .newLead: return .blue
        case .contacted: return .orange
        case .qualified: return .yellow
        case .proposal: return .purple
        case .negotiation: return .indigo
        case .won: return .green
        case .lost: return .red
        }
    }
}

// MARK: - Customer Detail Sheet
struct CustomerDetailSheet: View {
    let customer: SolarCustomer
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Customer header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(customer.status.color.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Text(customer.initials)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(customer.status.color)
                        }
                        
                        Text(customer.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(customer.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Customer details would go here
                    Text("Customer details and project information would be displayed here")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                }
            }
        }
    }
}

// MARK: - Form Components
struct FormSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }
}

struct StatusPill: View {
    let title: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? color.opacity(0.15) : Color(.systemGray6))
        .foregroundColor(isSelected ? color : .primary)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color, lineWidth: isSelected ? 1.5 : 0)
        )
    }
}

struct PriorityPill: View {
    let title: String
    let priority: SolarCustomer.Priority
    let isSelected: Bool
    
    private var color: Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
                .foregroundColor(color)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? color.opacity(0.15) : Color(.systemGray6))
        .foregroundColor(isSelected ? color : .primary)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color, lineWidth: isSelected ? 1.5 : 0)
        )
    }
}

// MARK: - Solar Customer Model
struct SolarCustomer: Identifiable {
    let id = UUID()
    let name: String
    let email: String
    let phone: String
    let address: String
    let systemSize: String
    let estimatedValue: Int
    let status: CustomerStatus
    let priority: Priority
    let createdDate: Date
    let lastContact: Date
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first?.uppercased() ?? ""
        let lastInitial = components.count > 1 ? components[1].first?.uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }
    
    enum CustomerStatus: String, CaseIterable {
        case lead = "Lead"
        case prospect = "Prospect"
        case customer = "Customer"
        case completed = "Completed"
        
        var color: Color {
            switch self {
            case .lead: return .blue
            case .prospect: return .orange
            case .customer: return .green
            case .completed: return .purple
            }
        }
    }
    
    enum Priority: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .green
            }
        }
    }
}

// MARK: - Sample Customer Data
private let sampleCustomers: [SolarCustomer] = [
    SolarCustomer(
        name: "John & Sarah Johnson",
        email: "john.johnson@email.com",
        phone: "(555) 123-4567",
        address: "123 Oak Street, Sunnyville, CA",
        systemSize: "8.5 kW",
        estimatedValue: 25000,
        status: .customer,
        priority: .medium,
        createdDate: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date(),
        lastContact: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
    ),
    SolarCustomer(
        name: "Michael Chen",
        email: "m.chen@business.com",
        phone: "(555) 234-5678",
        address: "456 Business Blvd, Commerce City, CA",
        systemSize: "25.0 kW",
        estimatedValue: 75000,
        status: .prospect,
        priority: .high,
        createdDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
        lastContact: Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date()
    ),
    SolarCustomer(
        name: "Emily Wilson",
        email: "emily.wilson@gmail.com",
        phone: "(555) 345-6789",
        address: "789 Maple Ave, Green Valley, CA",
        systemSize: "12.3 kW",
        estimatedValue: 35000,
        status: .lead,
        priority: .medium,
        createdDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
        lastContact: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    ),
    SolarCustomer(
        name: "Robert & Lisa Davis",
        email: "davis.family@email.com",
        phone: "(555) 456-7890",
        address: "321 Pine Road, Solar Heights, CA",
        systemSize: "6.8 kW",
        estimatedValue: 20000,
        status: .completed,
        priority: .low,
        createdDate: Calendar.current.date(byAdding: .day, value: -45, to: Date()) ?? Date(),
        lastContact: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    ),
    SolarCustomer(
        name: "Sofia Martinez",
        email: "sofia.martinez@company.com",
        phone: "(555) 567-8901",
        address: "654 Corporate Drive, Business Park, CA",
        systemSize: "18.2 kW",
        estimatedValue: 55000,
        status: .customer,
        priority: .high,
        createdDate: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
        lastContact: Calendar.current.date(byAdding: .hour, value: -12, to: Date()) ?? Date()
    ),
    SolarCustomer(
        name: "David Thompson",
        email: "d.thompson@email.com",
        phone: "(555) 678-9012",
        address: "987 Solar Street, Renewable City, CA",
        systemSize: "10.5 kW",
        estimatedValue: 30000,
        status: .prospect,
        priority: .medium,
        createdDate: Calendar.current.date(byAdding: .day, value: -8, to: Date()) ?? Date(),
        lastContact: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
    )
]