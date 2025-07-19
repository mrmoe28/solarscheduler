import SwiftUI
import SwiftData

struct ContractsListView: View {
    @Environment(\.viewModelContainer) private var viewModelContainer
    @State private var searchText = ""
    @State private var selectedFilter: ContractFilter = .all
    @State private var showingAddContract = false
    @State private var selectedContract: Contract?
    @State private var showingContractDetail = false
    
    private var viewModel: ContractsViewModel {
        viewModelContainer?.contractsViewModel ?? ContractsViewModel(
            dataService: DataService(modelContext: ModelContext(for: Schema([
                SolarJob.self, Customer.self, Equipment.self, Installation.self, Vendor.self, Contract.self
            ])))
        )
    }
    
    private var filteredContracts: [Contract] {
        var contracts = viewModel.contracts
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .draft:
            contracts = contracts.filter { $0.status == .draft }
        case .pending:
            contracts = contracts.filter { $0.status == .pending }
        case .active:
            contracts = contracts.filter { $0.status == .active }
        case .completed:
            contracts = contracts.filter { $0.status == .completed }
        case .cancelled:
            contracts = contracts.filter { $0.status == .cancelled }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            contracts = contracts.filter { contract in
                contract.title.localizedCaseInsensitiveContains(searchText) ||
                contract.customerName.localizedCaseInsensitiveContains(searchText) ||
                contract.contractNumber.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return contracts.sorted { $0.createdDate > $1.createdDate }
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
                
                if viewModel.isLoading {
                    ContractLoadingView()
                } else if filteredContracts.isEmpty {
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
                    .buttonStyle(BouncyButtonStyle())
                    .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: showingAddContract)
                }
            }
            .refreshable {
                viewModel.refreshData()
            }
            .onAppear {
                viewModel.refreshData()
            }
        .sheet(isPresented: $showingAddContract) {
            AddContractView(viewModel: viewModel)
        }
        .sheet(item: $selectedContract) { contract in
            ContractDetailView(contract: contract, viewModel: viewModel)
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
        .buttonStyle(BouncyButtonStyle())
        .sensoryFeedback(.selection, trigger: isSelected)
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
                .buttonStyle(BouncyButtonStyle())
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(contract.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(contract.customerName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ContractStatusBadge(status: contract.status)
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
                    value: "$\(Int(contract.totalValue))"
                )
                
                Spacer()
                
                ContractDetailItem(
                    icon: "calendar",
                    value: contract.createdDate.formatted(date: .abbreviated, time: .omitted)
                )
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
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
            .background(status.color)
            .cornerRadius(8)
    }
}

// MARK: - Add Contract View

struct AddContractView: View {
    let viewModel: ContractsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var customerName = ""
    @State private var contractNumber = ""
    @State private var totalValue = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now
    
    var body: some View {
        NavigationView {
            Form {
                Section("Contract Details") {
                    TextField("Contract Title", text: $title)
                    TextField("Customer Name", text: $customerName)
                    TextField("Contract Number", text: $contractNumber)
                    TextField("Total Value", text: $totalValue)
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
                    .disabled(title.isEmpty || customerName.isEmpty)
                    .sensoryFeedback(.success, trigger: !(title.isEmpty || customerName.isEmpty))
                }
            }
        }
    }
    
    private func createContract() {
        let value = Double(totalValue) ?? 0.0
        
        let newContract = Contract(
            title: title,
            customerName: customerName,
            contractNumber: contractNumber.isEmpty ? generateContractNumber() : contractNumber,
            totalValue: value,
            description: description,
            startDate: startDate,
            endDate: endDate,
            status: .draft
        )
        
        viewModel.addContract(newContract)
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
    let contract: Contract
    let viewModel: ContractsViewModel
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
                    if !contract.description.isEmpty {
                        ContractDescriptionSection(contract: contract)
                    }
                    
                    // Actions
                    ContractActionsSection(contract: contract, viewModel: viewModel)
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
            EditContractView(contract: contract, viewModel: viewModel)
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
            
            Text(contract.customerName)
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
                    Text(contract.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("End Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(contract.endDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.body)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
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
                    
                    Text("$\(Int(contract.totalValue))")
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
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Remaining Balance")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("$\(Int(contract.totalValue - contract.paidAmount))")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct ContractDescriptionSection: View {
    let contract: Contract
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Description")
            
            Text(contract.description)
                .font(.body)
                .foregroundColor(.primary)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
        }
    }
}

struct ContractActionsSection: View {
    let contract: Contract
    let viewModel: ContractsViewModel
    
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
                        viewModel.updateContractStatus(contract, status: .pending)
                    }
                }
                
                if contract.status == .pending {
                    HStack(spacing: 12) {
                        ActionButton(
                            title: "Approve",
                            icon: "checkmark.circle.fill",
                            color: .green
                        ) {
                            viewModel.updateContractStatus(contract, status: .active)
                        }
                        
                        ActionButton(
                            title: "Reject",
                            icon: "xmark.circle.fill",
                            color: .red
                        ) {
                            viewModel.updateContractStatus(contract, status: .cancelled)
                        }
                    }
                }
                
                if contract.status == .active {
                    ActionButton(
                        title: "Mark Complete",
                        icon: "flag.checkered.fill",
                        color: .green
                    ) {
                        viewModel.updateContractStatus(contract, status: .completed)
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
        .buttonStyle(BouncyButtonStyle())
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: UUID())
    }
}

// MARK: - Edit Contract View

struct EditContractView: View {
    let contract: Contract
    let viewModel: ContractsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var customerName: String
    @State private var contractNumber: String
    @State private var totalValue: String
    @State private var description: String
    @State private var startDate: Date
    @State private var endDate: Date
    
    init(contract: Contract, viewModel: ContractsViewModel) {
        self.contract = contract
        self.viewModel = viewModel
        self._title = State(initialValue: contract.title)
        self._customerName = State(initialValue: contract.customerName)
        self._contractNumber = State(initialValue: contract.contractNumber)
        self._totalValue = State(initialValue: String(Int(contract.totalValue)))
        self._description = State(initialValue: contract.description)
        self._startDate = State(initialValue: contract.startDate)
        self._endDate = State(initialValue: contract.endDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Contract Details") {
                    TextField("Contract Title", text: $title)
                    TextField("Customer Name", text: $customerName)
                    TextField("Contract Number", text: $contractNumber)
                    TextField("Total Value", text: $totalValue)
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
                    .disabled(title.isEmpty || customerName.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        let value = Double(totalValue) ?? 0.0
        
        viewModel.updateContract(
            contract,
            title: title,
            customerName: customerName,
            contractNumber: contractNumber,
            totalValue: value,
            description: description,
            startDate: startDate,
            endDate: endDate
        )
        
        dismiss()
    }
}

// MARK: - Contracts ViewModel

class ContractsViewModel: ObservableObject {
    @Published var contracts: [Contract] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataService: DataService
    
    init(dataService: DataService) {
        self.dataService = dataService
        loadContracts()
    }
    
    func refreshData() {
        loadContracts()
    }
    
    private func loadContracts() {
        isLoading = true
        
        // Simulate loading with mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.contracts = self.generateMockContracts()
            self.isLoading = false
        }
    }
    
    func addContract(_ contract: Contract) {
        contracts.append(contract)
    }
    
    func updateContract(
        _ contract: Contract,
        title: String,
        customerName: String,
        contractNumber: String,
        totalValue: Double,
        description: String,
        startDate: Date,
        endDate: Date
    ) {
        if let index = contracts.firstIndex(where: { $0.id == contract.id }) {
            contracts[index].title = title
            contracts[index].customerName = customerName
            contracts[index].contractNumber = contractNumber
            contracts[index].totalValue = totalValue
            contracts[index].description = description
            contracts[index].startDate = startDate
            contracts[index].endDate = endDate
        }
    }
    
    func updateContractStatus(_ contract: Contract, status: ContractStatus) {
        if let index = contracts.firstIndex(where: { $0.id == contract.id }) {
            contracts[index].status = status
        }
    }
    
    private func generateMockContracts() -> [Contract] {
        [
            Contract(
                title: "Residential Solar Installation - Johnson",
                customerName: "Michael Johnson",
                contractNumber: "CTR-20250719-1001",
                totalValue: 25000.0,
                description: "Complete residential solar panel installation including 20 panels, inverter, and electrical work.",
                startDate: Date(),
                endDate: Date().addingTimeInterval(45 * 24 * 60 * 60),
                status: .active,
                paidAmount: 12500.0
            ),
            Contract(
                title: "Commercial Solar Array - ABC Corp",
                customerName: "ABC Corporation",
                contractNumber: "CTR-20250718-1002",
                totalValue: 85000.0,
                description: "Large-scale commercial solar installation for warehouse facility.",
                startDate: Date().addingTimeInterval(-7 * 24 * 60 * 60),
                endDate: Date().addingTimeInterval(60 * 24 * 60 * 60),
                status: .pending,
                paidAmount: 0.0
            ),
            Contract(
                title: "Solar Maintenance Agreement - Smith",
                customerName: "Sarah Smith",
                contractNumber: "CTR-20250717-1003",
                totalValue: 5000.0,
                description: "Annual maintenance and monitoring service agreement.",
                startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                endDate: Date().addingTimeInterval(335 * 24 * 60 * 60),
                status: .completed,
                paidAmount: 5000.0
            )
        ]
    }
}

#Preview {
    ContractsListView()
        .modelContainer(for: [Contract.self])
}