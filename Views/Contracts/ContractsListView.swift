import SwiftUI
import SwiftData

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct ContractsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contracts: [Contract]
    @State private var searchText = ""
    @State private var selectedFilter: ContractFilter = .all
    @State private var showingAddContract = false
    @State private var selectedContract: Contract?
    @State private var showingContractDetail = false
    
    private var filteredContracts: [Contract] {
        var result = contracts
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .draft:
            result = result.filter { $0.status == .draft }
        case .pending:
            result = result.filter { $0.status == .pendingSignature }
        case .active:
            result = result.filter { $0.status == .active }
        case .completed:
            result = result.filter { $0.status == .completed }
        case .cancelled:
            result = result.filter { $0.status == .cancelled }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { contract in
                contract.title.localizedCaseInsensitiveContains(searchText) ||
                (contract.customer?.name ?? "").localizedCaseInsensitiveContains(searchText) ||
                contract.contractNumber.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result.sorted { $0.createdDate > $1.createdDate }
    }
    
    var body: some View {
        VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 12) {
                    SearchBar(text: $searchText)
                    ContractFilterBar(selectedFilter: $selectedFilter)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                if filteredContracts.isEmpty {
                    EmptyContractsView(
                        searchText: searchText,
                        selectedFilter: selectedFilter
                    ) {
                        showingAddContract = true
                    }
                } else {
                    ContractsList(
                        contracts: filteredContracts,
                        onContractTap: { contract in
                            selectedContract = contract
                            showingContractDetail = true
                        }
                    )
                }
                
                Spacer()
            }
            .navigationTitle("Contracts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddContract = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
            }
        .sheet(isPresented: $showingAddContract) {
            AddContractView()
        }
        .sheet(item: $selectedContract) { contract in
            ContractDetailView(contract: contract)
        }
    }
}

// MARK: - Contract Filter

enum ContractFilter: String, CaseIterable {
    case all = "All"
    case draft = "Draft"
    case pending = "Pending"
    case active = "Active"
    case completed = "Completed"
    case cancelled = "Cancelled"
    
    var color: Color {
        switch self {
        case .all: return .primary
        case .draft: return .gray
        case .pending: return .orange
        case .active: return .blue
        case .completed: return .green
        case .cancelled: return .red
        }
    }
}

// MARK: - Contract Filter Bar

struct ContractFilterBar: View {
    @Binding var selectedFilter: ContractFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ContractFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        color: filter.color
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? color : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(color, lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Contract Loading View

struct ContractLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.orange)
            
            Text("Loading contracts...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty Contracts View

struct EmptyContractsView: View {
    let searchText: String
    let selectedFilter: ContractFilter
    let onAddContract: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isEmpty ? "doc.badge.plus" : "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.orange.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(isEmpty ? "No Contracts Yet" : "No Results Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(isEmpty ? 
                     "Create your first contract to get started" : 
                     "Try adjusting your search or filter")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if isEmpty {
                Button(action: onAddContract) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Create Contract")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(25)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var isEmpty: Bool {
        searchText.isEmpty && selectedFilter == .all
    }
}

// MARK: - Contracts List

struct ContractsList: View {
    let contracts: [Contract]
    let onContractTap: (Contract) -> Void
    
    var body: some View {
        List {
            ForEach(contracts, id: \.id) { contract in
                ContractRowView(contract: contract)
                    .onTapGesture {
                        onContractTap(contract)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Contract Row View

struct ContractRowView: View {
    let contract: Contract
    @State private var showingDetail = false
    @State private var showingDeleteAlert = false
    @State private var showShareSheet = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(contract.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(contract.customer?.name ?? "Unknown Customer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: { showingDetail = true }) {
                        Image(systemName: "eye")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                    }
                    
                    Button(action: { showingDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
            // Details
            HStack {
                ContractDetailItem(
                    icon: "number",
                    value: contract.contractNumber
                )
                
                Spacer()
                
                ContractDetailItem(
                    icon: "dollarsign.circle",
                    value: "$\(Int(contract.totalAmount))"
                )
                
                Spacer()
                
                ContractDetailItem(
                    icon: "calendar",
                    value: contract.createdDate.formatted(date: .abbreviated, time: .omitted)
                )
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            // Status badge
            HStack {
                Spacer()
                ContractStatusBadge(status: contract.status)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingDetail) {
            ContractDetailView(contract: contract)
        }
        .alert("Delete Contract", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteContract()
            }
        } message: {
            Text("Are you sure you want to delete this contract?")
        }
        #if os(iOS)
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(items: [createContractShareText()])
        }
        #endif
    }
    
    private func deleteContract() {
        modelContext.delete(contract)
        try? modelContext.save()
    }
    
    private func createContractShareText() -> String {
        """
        Contract: \(contract.title)
        Contract #: \(contract.contractNumber)
        Customer: \(contract.customer?.name ?? "Unknown")
        Total Amount: $\(Int(contract.totalAmount))
        Status: \(contract.status.rawValue)
        Created: \(contract.createdDate.formatted())
        """
    }
}

struct ContractDetailItem: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.orange)
            Text(value)
        }
    }
}

struct ContractStatusBadge: View {
    let status: ContractStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(status.color))
            .cornerRadius(8)
    }
}

// MARK: - Add Contract View

struct AddContractView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var customers: [Customer]
    
    @State private var title = ""
    @State private var selectedCustomer: Customer?
    @State private var contractNumber = ""
    @State private var totalAmount = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now
    
    var body: some View {
        NavigationView {
            Form {
                Section("Contract Details") {
                    TextField("Contract Title", text: $title)
                    
                    Picker("Customer", selection: $selectedCustomer) {
                        Text("Select Customer").tag(nil as Customer?)
                        ForEach(customers) { customer in
                            Text(customer.name).tag(customer as Customer?)
                        }
                    }
                    
                    TextField("Contract Number", text: $contractNumber)
                    TextField("Total Amount", text: $totalAmount)
                        .keyboardType(.decimalPad)
                }
                
                Section("Timeline") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section("Description") {
                    TextField("Contract description...", text: $description, axis: .vertical)
                        .lineLimit(5...10)
                }
            }
            .navigationTitle("New Contract")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createContract()
                    }
                    .disabled(title.isEmpty || selectedCustomer == nil)
                }
            }
        }
    }
    
    private func createContract() {
        let value = Double(totalAmount) ?? 0.0
        
        let newContract = Contract(
            contractNumber: contractNumber.isEmpty ? generateContractNumber() : contractNumber,
            title: title,
            contractDescription: description,
            totalAmount: value,
            status: .draft,
            terms: "",
            paymentSchedule: ""
        )
        
        newContract.startDate = startDate
        newContract.completionDate = endDate
        
        if let customer = selectedCustomer {
            newContract.customer = customer
        }
        
        modelContext.insert(newContract)
        try? modelContext.save()
        dismiss()
    }
    
    private func generateContractNumber() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: Date())
        let randomNumber = Int.random(in: 1000...9999)
        return "CTR-\(dateString)-\(randomNumber)"
    }
}

// MARK: - Contract Detail View

struct ContractDetailView: View {
    @Bindable var contract: Contract
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    ContractDetailHeader(contract: contract)
                    
                    // Status and Timeline
                    ContractStatusSection(contract: contract)
                    
                    // Financial Information
                    ContractFinancialSection(contract: contract)
                    
                    // Description
                    if !contract.contractDescription.isEmpty {
                        ContractDescriptionSection(contract: contract)
                    }
                    
                    // Actions
                    ContractActionsSection(contract: contract)
                }
                .padding()
            }
            .navigationTitle("Contract Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditView = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditContractView(contract: contract)
        }
    }
}

// MARK: - Contract Detail Components

struct ContractDetailHeader: View {
    let contract: Contract
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(contract.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                ContractStatusBadge(status: contract.status)
            }
            
            Text(contract.customer?.name ?? "Unknown Customer")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Contract #\(contract.contractNumber)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct ContractStatusSection: View {
    let contract: Contract
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Timeline")
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Start Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(contract.startDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set")
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Completion Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(contract.completionDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set")
                        .font(.body)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct ContractFinancialSection: View {
    let contract: Contract
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Financial Information")
            
            VStack(spacing: 12) {
                HStack {
                    Text("Total Contract Value")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("$\(Int(contract.totalAmount))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                if contract.paidAmount > 0 {
                    HStack {
                        Text("Amount Paid")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("$\(Int(contract.paidAmount))")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.blue)
                    }
                    
                    HStack {
                        Text("Remaining Balance")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("$\(Int(contract.totalAmount - contract.paidAmount))")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct ContractDescriptionSection: View {
    let contract: Contract
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Description")
            
            Text(contract.contractDescription)
                .font(.body)
                .foregroundColor(.primary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
}

struct ContractActionsSection: View {
    @Bindable var contract: Contract
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Actions")
            
            VStack(spacing: 12) {
                if contract.status == .draft {
                    ActionButton(
                        title: "Submit for Approval",
                        icon: "paperplane.fill",
                        color: .blue
                    ) {
                        contract.status = .pendingSignature
                        try? modelContext.save()
                    }
                }
                
                if contract.status == .pendingSignature {
                    HStack(spacing: 12) {
                        ActionButton(
                            title: "Approve",
                            icon: "checkmark.circle.fill",
                            color: .green
                        ) {
                            contract.status = .active
                            try? modelContext.save()
                        }
                        
                        ActionButton(
                            title: "Reject",
                            icon: "xmark.circle.fill",
                            color: .red
                        ) {
                            contract.status = .cancelled
                            try? modelContext.save()
                        }
                    }
                }
                
                if contract.status == .active {
                    ActionButton(
                        title: "Mark Complete",
                        icon: "flag.checkered.fill",
                        color: .green
                    ) {
                        contract.status = .completed
                        try? modelContext.save()
                    }
                }
                
                ActionButton(
                    title: "Export PDF",
                    icon: "square.and.arrow.up.fill",
                    color: .orange
                ) {
                    // Handle PDF export
                }
            }
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
            }
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding()
            .background(color)
            .cornerRadius(12)
        }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
    }
}

// MARK: - Edit Contract View

struct EditContractView: View {
    @Bindable var contract: Contract
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var customers: [Customer]
    
    @State private var title: String
    @State private var selectedCustomer: Customer?
    @State private var contractNumber: String
    @State private var totalAmount: String
    @State private var description: String
    @State private var startDate: Date?
    @State private var completionDate: Date?
    
    init(contract: Contract) {
        self.contract = contract
        self._title = State(initialValue: contract.title)
        self._selectedCustomer = State(initialValue: contract.customer)
        self._contractNumber = State(initialValue: contract.contractNumber)
        self._totalAmount = State(initialValue: String(Int(contract.totalAmount)))
        self._description = State(initialValue: contract.contractDescription)
        self._startDate = State(initialValue: contract.startDate)
        self._completionDate = State(initialValue: contract.completionDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Contract Details") {
                    TextField("Contract Title", text: $title)
                    
                    Picker("Customer", selection: $selectedCustomer) {
                        Text("Select Customer").tag(nil as Customer?)
                        ForEach(customers) { customer in
                            Text(customer.name).tag(customer as Customer?)
                        }
                    }
                    
                    TextField("Contract Number", text: $contractNumber)
                    TextField("Total Amount", text: $totalAmount)
                        .keyboardType(.decimalPad)
                }
                
                Section("Timeline") {
                    DatePicker("Start Date", selection: Binding(
                        get: { startDate ?? Date() },
                        set: { startDate = $0 }
                    ), displayedComponents: .date)
                    DatePicker("Completion Date", selection: Binding(
                        get: { completionDate ?? Date() },
                        set: { completionDate = $0 }
                    ), displayedComponents: .date)
                }
                
                Section("Description") {
                    TextField("Contract description...", text: $description, axis: .vertical)
                        .lineLimit(5...10)
                }
            }
            .navigationTitle("Edit Contract")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(title.isEmpty || selectedCustomer == nil)
                }
            }
        }
    }
    
    private func saveChanges() {
        let value = Double(totalAmount) ?? 0.0
        
        contract.title = title
        contract.customer = selectedCustomer
        contract.contractNumber = contractNumber
        contract.totalAmount = value
        contract.contractDescription = description
        contract.startDate = startDate
        contract.completionDate = completionDate
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    ContractsListView()
        .modelContainer(for: [Contract.self])
}