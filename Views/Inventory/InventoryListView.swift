import SwiftUI
import SwiftData

struct InventoryListView: View {
    @Environment(\.viewModelContainer) private var viewModelContainer
    @State private var searchText = ""
    @State private var selectedCategory: InventoryCategory = .all
    @State private var showingAddItem = false
    @State private var selectedItem: Equipment?
    @State private var showingItemDetail = false
    @State private var showingLowStockOnly = false
    
    private var viewModel: EquipmentViewModel {
        viewModelContainer?.equipmentViewModel ?? EquipmentViewModel(
            dataService: DataService(modelContext: ModelContext(for: Schema([
                SolarJob.self, Customer.self, Equipment.self, Installation.self, Vendor.self, Contract.self
            ])))
        )
    }
    
    private var filteredInventory: [Equipment] {
        var items = viewModel.equipment
        
        // Apply category filter
        if selectedCategory != .all {
            items = items.filter { equipment in
                switch selectedCategory {
                case .all:
                    return true
                case .panels:
                    return equipment.category == "Solar Panels"
                case .inverters:
                    return equipment.category == "Inverters"
                case .batteries:
                    return equipment.category == "Batteries"
                case .mounting:
                    return equipment.category == "Mounting"
                case .electrical:
                    return equipment.category == "Electrical"
                case .tools:
                    return equipment.category == "Tools"
                }
            }
        }
        
        // Apply low stock filter
        if showingLowStockOnly {
            items = items.filter { $0.quantity <= $0.minimumStock }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { equipment in
                equipment.name.localizedCaseInsensitiveContains(searchText) ||
                equipment.manufacturer.localizedCaseInsensitiveContains(searchText) ||
                equipment.model.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return items.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        VStack(spacing: 0) {
                // Search and Filter Section
                VStack(spacing: 12) {
                    SearchBar(text: $searchText)
                    
                    HStack {
                        InventoryCategoryFilter(selectedCategory: $selectedCategory)
                        
                        Spacer()
                        
                        LowStockToggle(showingLowStockOnly: $showingLowStockOnly)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                if viewModel.isLoading {
                    InventoryLoadingView()
                } else if filteredInventory.isEmpty {
                    EmptyInventoryView(
                        searchText: searchText,
                        selectedCategory: selectedCategory,
                        showingLowStockOnly: showingLowStockOnly
                    ) {
                        showingAddItem = true
                    }
                } else {
                    InventoryList(
                        items: filteredInventory,
                        onItemTap: { item in
                            selectedItem = item
                            showingItemDetail = true
                        }
                    )
                }
                
                Spacer()
            }
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddItem = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: showingAddItem)
                }
            }
            .refreshable {
                viewModel.refreshData()
            }
            .onAppear {
                viewModel.refreshData()
            }
        .sheet(isPresented: $showingAddItem) {
            AddInventoryItemView(viewModel: viewModel)
        }
        .sheet(item: $selectedItem) { item in
            InventoryItemDetailView(item: item, viewModel: viewModel)
        }
    }
}

// MARK: - Inventory Category

enum InventoryCategory: String, CaseIterable {
    case all = "All"
    case panels = "Solar Panels"
    case inverters = "Inverters"
    case batteries = "Batteries"
    case mounting = "Mounting"
    case electrical = "Electrical"
    case tools = "Tools"
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .panels: return "sun.max.fill"
        case .inverters: return "powerplug.fill"
        case .batteries: return "battery.100"
        case .mounting: return "hammer.fill"
        case .electrical: return "bolt.fill"
        case .tools: return "wrench.and.screwdriver.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .primary
        case .panels: return .orange
        case .inverters: return .blue
        case .batteries: return .green
        case .mounting: return .brown
        case .electrical: return .yellow
        case .tools: return .gray
        }
    }
}

// MARK: - Inventory Category Filter

struct InventoryCategoryFilter: View {
    @Binding var selectedCategory: InventoryCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InventoryCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct CategoryChip: View {
    let category: InventoryCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                
                if category != .all {
                    Text(category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(isSelected ? .white : category.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? category.color : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(category.color, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(BouncyButtonStyle())
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Low Stock Toggle

struct LowStockToggle: View {
    @Binding var showingLowStockOnly: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showingLowStockOnly.toggle()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: showingLowStockOnly ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundColor(showingLowStockOnly ? .white : .red)
                
                Text("Low Stock")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(showingLowStockOnly ? .white : .red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(showingLowStockOnly ? Color.red : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(BouncyButtonStyle())
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: showingLowStockOnly)
    }
}

// MARK: - Loading View

struct InventoryLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.orange)
            
            Text("Loading inventory...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty Inventory View

struct EmptyInventoryView: View {
    let searchText: String
    let selectedCategory: InventoryCategory
    let showingLowStockOnly: Bool
    let onAddItem: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isEmpty ? "cube.box.fill" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.orange.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(isEmpty ? "No Inventory Items" : "No Results Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(isEmpty ? 
                     "Add your first inventory item to get started" : 
                     "Try adjusting your search or filters")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if isEmpty {
                Button(action: onAddItem) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Item")
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
        searchText.isEmpty && selectedCategory == .all && !showingLowStockOnly
    }
}

// MARK: - Inventory List

struct InventoryList: View {
    let items: [Equipment]
    let onItemTap: (Equipment) -> Void
    
    var body: some View {
        List {
            ForEach(items, id: \.id) { item in
                InventoryRowView(item: item)
                    .onTapGesture {
                        onItemTap(item)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Inventory Row View

struct InventoryRowView: View {
    let item: Equipment
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            VStack {
                Image(systemName: categoryIcon)
                    .font(.title2)
                    .foregroundColor(categoryColor)
                    .frame(width: 40, height: 40)
                    .background(categoryColor.opacity(0.1))
                    .cornerRadius(8)
                
                Spacer()
            }
            
            // Item Information
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if !item.manufacturer.isEmpty {
                    Text("\(item.manufacturer) • \(item.model)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    InventoryDetailItem(
                        icon: "number",
                        value: "Qty: \(item.quantity)"
                    )
                    
                    if item.unitPrice > 0 {
                        InventoryDetailItem(
                            icon: "dollarsign.circle",
                            value: "$\(Int(item.unitPrice))"
                        )
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Stock Status
            VStack(spacing: 8) {
                StockStatusIndicator(item: item)
                
                if item.quantity <= item.minimumStock {
                    LowStockBadge()
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var categoryIcon: String {
        switch item.category {
        case "Solar Panels": return "sun.max.fill"
        case "Inverters": return "powerplug.fill"
        case "Batteries": return "battery.100"
        case "Mounting": return "hammer.fill"
        case "Electrical": return "bolt.fill"
        case "Tools": return "wrench.and.screwdriver.fill"
        default: return "cube.box.fill"
        }
    }
    
    private var categoryColor: Color {
        switch item.category {
        case "Solar Panels": return .orange
        case "Inverters": return .blue
        case "Batteries": return .green
        case "Mounting": return .brown
        case "Electrical": return .yellow
        case "Tools": return .gray
        default: return .primary
        }
    }
}

struct InventoryDetailItem: View {
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

struct StockStatusIndicator: View {
    let item: Equipment
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(item.quantity)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(stockColor)
            
            Text("in stock")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var stockColor: Color {
        if item.quantity <= item.minimumStock {
            return .red
        } else if item.quantity <= (item.minimumStock * 2) {
            return .orange
        } else {
            return .green
        }
    }
}

struct LowStockBadge: View {
    var body: some View {
        Text("LOW")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red)
            .cornerRadius(4)
    }
}

// MARK: - Add Inventory Item View

struct AddInventoryItemView: View {
    let viewModel: EquipmentViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var manufacturer = ""
    @State private var model = ""
    @State private var category = "Solar Panels"
    @State private var quantity = ""
    @State private var minimumStock = ""
    @State private var unitPrice = ""
    @State private var description = ""
    @State private var location = ""
    
    private let categories = ["Solar Panels", "Inverters", "Batteries", "Mounting", "Electrical", "Tools"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $name)
                    TextField("Manufacturer", text: $manufacturer)
                    TextField("Model", text: $model)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                Section("Inventory") {
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)
                    TextField("Minimum Stock Level", text: $minimumStock)
                        .keyboardType(.numberPad)
                    TextField("Unit Price", text: $unitPrice)
                        .keyboardType(.decimalPad)
                }
                
                Section("Additional Information") {
                    TextField("Storage Location", text: $location)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(name.isEmpty)
                    .sensoryFeedback(.success, trigger: !name.isEmpty)
                }
            }
        }
    }
    
    private func saveItem() {
        let qty = Int(quantity) ?? 0
        let minStock = Int(minimumStock) ?? 0
        let price = Double(unitPrice) ?? 0.0
        
        let newItem = Equipment(
            name: name,
            category: category,
            manufacturer: manufacturer,
            model: model,
            quantity: qty,
            minimumStock: minStock,
            unitPrice: price,
            description: description,
            location: location
        )
        
        viewModel.addEquipment(newItem)
        dismiss()
    }
}

// MARK: - Inventory Item Detail View

struct InventoryItemDetailView: View {
    let item: Equipment
    let viewModel: EquipmentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditView = false
    @State private var showingStockAdjustment = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    InventoryItemHeader(item: item)
                    
                    // Stock Information
                    InventoryStockSection(item: item) {
                        showingStockAdjustment = true
                    }
                    
                    // Item Details
                    InventoryDetailsSection(item: item)
                    
                    // Financial Information
                    if item.unitPrice > 0 {
                        InventoryFinancialSection(item: item)
                    }
                    
                    // Quick Actions
                    InventoryQuickActions(item: item, viewModel: viewModel)
                }
                .padding()
            }
            .navigationTitle("Item Details")
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
            EditInventoryItemView(item: item, viewModel: viewModel)
        }
        .sheet(isPresented: $showingStockAdjustment) {
            StockAdjustmentView(item: item, viewModel: viewModel)
        }
    }
}

// MARK: - Inventory Detail Components

struct InventoryItemHeader: View {
    let item: Equipment
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: categoryIcon)
                .font(.system(size: 40))
                .foregroundColor(categoryColor)
                .frame(width: 60, height: 60)
                .background(categoryColor.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !item.manufacturer.isEmpty {
                    Text("\(item.manufacturer) \(item.model)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(item.category)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(categoryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
    }
    
    private var categoryIcon: String {
        switch item.category {
        case "Solar Panels": return "sun.max.fill"
        case "Inverters": return "powerplug.fill"
        case "Batteries": return "battery.100"
        case "Mounting": return "hammer.fill"
        case "Electrical": return "bolt.fill"
        case "Tools": return "wrench.and.screwdriver.fill"
        default: return "cube.box.fill"
        }
    }
    
    private var categoryColor: Color {
        switch item.category {
        case "Solar Panels": return .orange
        case "Inverters": return .blue
        case "Batteries": return .green
        case "Mounting": return .brown
        case "Electrical": return .yellow
        case "Tools": return .gray
        default: return .primary
        }
    }
}

struct InventoryStockSection: View {
    let item: Equipment
    let onAdjustStock: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Stock Information")
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Current Stock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(item.quantity)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(stockColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Minimum Level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(item.minimumStock)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
            
            if item.quantity <= item.minimumStock {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Stock level is below minimum threshold")
                        .font(.subheadline)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button(action: onAdjustStock) {
                HStack {
                    Image(systemName: "plus.minus")
                    Text("Adjust Stock")
                    Spacer()
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
            }
            .buttonStyle(BouncyButtonStyle())
        }
    }
    
    private var stockColor: Color {
        if item.quantity <= item.minimumStock {
            return .red
        } else if item.quantity <= (item.minimumStock * 2) {
            return .orange
        } else {
            return .green
        }
    }
}

struct InventoryDetailsSection: View {
    let item: Equipment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Item Details")
            
            VStack(spacing: 12) {
                if !item.manufacturer.isEmpty {
                    DetailRow(label: "Manufacturer", value: item.manufacturer)
                }
                
                if !item.model.isEmpty {
                    DetailRow(label: "Model", value: item.model)
                }
                
                if !item.location.isEmpty {
                    DetailRow(label: "Location", value: item.location)
                }
                
                if !item.description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(item.description)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

struct InventoryFinancialSection: View {
    let item: Equipment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Financial Information")
            
            VStack(spacing: 12) {
                HStack {
                    Text("Unit Price")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("$\(item.unitPrice, specifier: "%.2f")")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Total Value")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("$\(Double(item.quantity) * item.unitPrice, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct InventoryQuickActions: View {
    let item: Equipment
    let viewModel: EquipmentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Quick Actions")
            
            VStack(spacing: 12) {
                if item.quantity <= item.minimumStock {
                    ActionButton(
                        title: "Reorder Stock",
                        icon: "cart.badge.plus",
                        color: .blue
                    ) {
                        // Handle reorder
                        viewModel.reorderEquipment(item)
                    }
                }
                
                ActionButton(
                    title: "Generate Report",
                    icon: "doc.text.fill",
                    color: .orange
                ) {
                    // Handle report generation
                }
                
                ActionButton(
                    title: "Export Data",
                    icon: "square.and.arrow.up.fill",
                    color: .green
                ) {
                    // Handle data export
                }
            }
        }
    }
}

// MARK: - Stock Adjustment View

struct StockAdjustmentView: View {
    let item: Equipment
    let viewModel: EquipmentViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var adjustmentType: AdjustmentType = .add
    @State private var quantity = ""
    @State private var reason = ""
    
    enum AdjustmentType: String, CaseIterable {
        case add = "Add Stock"
        case remove = "Remove Stock"
        case set = "Set Stock"
        
        var icon: String {
            switch self {
            case .add: return "plus.circle.fill"
            case .remove: return "minus.circle.fill"
            case .set: return "equal.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .add: return .green
            case .remove: return .red
            case .set: return .blue
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Current Stock") {
                    HStack {
                        Text("Item")
                        Spacer()
                        Text(item.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Current Quantity")
                        Spacer()
                        Text("\(item.quantity)")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                
                Section("Adjustment") {
                    Picker("Type", selection: $adjustmentType) {
                        ForEach(AdjustmentType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)
                    
                    TextField("Reason (optional)", text: $reason)
                }
                
                if !quantity.isEmpty, let qty = Int(quantity) {
                    Section("Preview") {
                        HStack {
                            Text("New Quantity")
                            Spacer()
                            Text("\(newQuantity(currentQty: item.quantity, adjustment: qty, type: adjustmentType))")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Adjust Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAdjustment()
                    }
                    .disabled(quantity.isEmpty)
                }
            }
        }
    }
    
    private func newQuantity(currentQty: Int, adjustment: Int, type: AdjustmentType) -> Int {
        switch type {
        case .add:
            return currentQty + adjustment
        case .remove:
            return max(0, currentQty - adjustment)
        case .set:
            return adjustment
        }
    }
    
    private func saveAdjustment() {
        guard let qty = Int(quantity) else { return }
        
        let newQty = newQuantity(currentQty: item.quantity, adjustment: qty, type: adjustmentType)
        viewModel.updateEquipmentQuantity(item, newQuantity: newQty)
        
        dismiss()
    }
}

// MARK: - Edit Inventory Item View

struct EditInventoryItemView: View {
    let item: Equipment
    let viewModel: EquipmentViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var manufacturer: String
    @State private var model: String
    @State private var category: String
    @State private var minimumStock: String
    @State private var unitPrice: String
    @State private var description: String
    @State private var location: String
    
    private let categories = ["Solar Panels", "Inverters", "Batteries", "Mounting", "Electrical", "Tools"]
    
    init(item: Equipment, viewModel: EquipmentViewModel) {
        self.item = item
        self.viewModel = viewModel
        self._name = State(initialValue: item.name)
        self._manufacturer = State(initialValue: item.manufacturer)
        self._model = State(initialValue: item.model)
        self._category = State(initialValue: item.category)
        self._minimumStock = State(initialValue: String(item.minimumStock))
        self._unitPrice = State(initialValue: String(item.unitPrice))
        self._description = State(initialValue: item.description)
        self._location = State(initialValue: item.location)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $name)
                    TextField("Manufacturer", text: $manufacturer)
                    TextField("Model", text: $model)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                Section("Inventory Settings") {
                    TextField("Minimum Stock Level", text: $minimumStock)
                        .keyboardType(.numberPad)
                    TextField("Unit Price", text: $unitPrice)
                        .keyboardType(.decimalPad)
                }
                
                Section("Additional Information") {
                    TextField("Storage Location", text: $location)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Item")
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
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        let minStock = Int(minimumStock) ?? 0
        let price = Double(unitPrice) ?? 0.0
        
        viewModel.updateEquipment(
            item,
            name: name,
            manufacturer: manufacturer,
            model: model,
            category: category,
            minimumStock: minStock,
            unitPrice: price,
            description: description,
            location: location
        )
        
        dismiss()
    }
}

#Preview {
    InventoryListView()
        .modelContainer(for: [Equipment.self])
}