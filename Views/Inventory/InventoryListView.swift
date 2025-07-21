import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

struct InventoryListView: View {
    @Environment(\.viewModelContainer) private var viewModelContainer
    @State private var searchText = ""
    @State private var selectedCategory: InventoryCategory = .all
    @State private var showingAddItem = false
    @State private var selectedItem: Equipment?
    @State private var showingItemDetail = false
    @State private var showingLowStockOnly = false
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: EquipmentViewModel?
    
    private var currentViewModel: EquipmentViewModel {
        if let vm = viewModel {
            return vm
        } else {
            let dataService = DataService(modelContext: modelContext)
            let newViewModel = EquipmentViewModel(dataService: dataService)
            viewModel = newViewModel
            return newViewModel
        }
    }
    
    private var filteredInventory: [Equipment] {
        var items = currentViewModel.equipment
        
        // Apply category filter
        if selectedCategory != .all {
            items = items.filter { equipment in
                switch selectedCategory {
                case .all:
                    return true
                case .panels:
                    return equipment.category == .solarPanels
                case .inverters:
                    return equipment.category == .inverters
                case .batteries:
                    return equipment.category == .batteries
                case .mounting:
                    return equipment.category == .mounting
                case .electrical:
                    return equipment.category == .electrical
                case .tools:
                    return equipment.category == .tools
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
                
                if currentViewModel.isLoading {
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
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
                currentViewModel.loadEquipment()
            }
            .onAppear {
                currentViewModel.loadEquipment()
            }
        .sheet(isPresented: $showingAddItem) {
            AddInventoryItemView(viewModel: currentViewModel)
        }
        .sheet(item: $selectedItem) { item in
            InventoryItemDetailView(item: item, viewModel: currentViewModel)
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
            // Equipment Image or Category Icon
            VStack {
                if item.imageData != nil {
                    EquipmentImageView(imageData: item.imageData, size: 40)
                } else {
                    Image(systemName: categoryIcon)
                        .font(.title2)
                        .foregroundColor(categoryColor)
                        .frame(width: 40, height: 40)
                        .background(categoryColor.opacity(0.1))
                        .cornerRadius(8)
                }
                
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
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var categoryIcon: String {
        return item.category.icon
    }
    
    private var categoryColor: Color {
        switch item.category {
        case .solarPanels: return .orange
        case .inverters: return .blue
        case .batteries: return .green
        case .mounting: return .brown
        case .electrical: return .yellow
        case .tools: return .gray
        case .monitoring: return .purple
        case .safety: return .red
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
    @State private var selectedImage: PlatformImage?
    @State private var showingImageSelection = false
    
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
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    TextField("Minimum Stock Level", text: $minimumStock)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    TextField("Unit Price", text: $unitPrice)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                
                Section("Additional Information") {
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Photo") {
                    HStack {
                        EquipmentImageView(imageData: selectedImage?.compressedData(), size: 80)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                showingImageSelection = true
                            }) {
                                HStack {
                                    Image(systemName: selectedImage == nil ? "camera.fill" : "photo.fill")
                                    Text(selectedImage == nil ? "Add Photo" : "Change Photo")
                                }
                                .foregroundColor(.orange)
                            }
                            
                            if selectedImage != nil {
                                Button(action: {
                                    selectedImage = nil
                                }) {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                        Text("Remove Photo")
                                    }
                                    .foregroundColor(.red)
                                }
                            }
                        }
                        
                        Spacer()
                    }
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
            .sheet(isPresented: $showingImageSelection) {
                ImageSelectionSheet(selectedImage: $selectedImage)
            }
        }
    }
    
    private func saveItem() {
        let qty = Int(quantity) ?? 0
        let minStock = Int(minimumStock) ?? 0
        let price = Double(unitPrice) ?? 0.0
        
        let equipmentCategory: EquipmentCategory = {
            switch category {
            case "Solar Panels": return .solarPanels
            case "Inverters": return .inverters
            case "Batteries": return .batteries
            case "Mounting": return .mounting
            case "Electrical": return .electrical
            case "Tools": return .tools
            default: return .solarPanels
            }
        }()
        
        // Set ViewModel properties
        viewModel.newEquipmentName = name
        viewModel.newEquipmentCategory = equipmentCategory
        viewModel.newEquipmentBrand = manufacturer
        viewModel.newEquipmentModel = model
        viewModel.newEquipmentQuantity = qty
        viewModel.newEquipmentUnitCost = price
        viewModel.newEquipmentMinimumStock = minStock
        viewModel.newEquipmentDescription = description
        
        // Set image data if available
        if let image = selectedImage {
            let resizedImage = image.resized(toWidth: 800) ?? image
            viewModel.newEquipmentImageData = resizedImage.compressedData(quality: 0.8)
        }
        
        // Add the equipment
        viewModel.addEquipment()
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .automatic) {
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
            if item.imageData != nil {
                EquipmentImageView(imageData: item.imageData, size: 60)
            } else {
                Image(systemName: categoryIcon)
                    .font(.system(size: 40))
                    .foregroundColor(categoryColor)
                    .frame(width: 60, height: 60)
                    .background(categoryColor.opacity(0.1))
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !item.manufacturer.isEmpty {
                    Text("\(item.manufacturer) \(item.model)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(item.category.rawValue)
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
        return item.category.icon
    }
    
    private var categoryColor: Color {
        switch item.category {
        case .solarPanels: return .orange
        case .inverters: return .blue
        case .batteries: return .green
        case .mounting: return .brown
        case .electrical: return .yellow
        case .tools: return .gray
        case .monitoring: return .purple
        case .safety: return .red
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
            .background(Color.systemGray6)
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
                
                
                if !item.equipmentDescription.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(item.equipmentDescription)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
            .background(Color.systemGray6)
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
            .background(Color.systemGray6)
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
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    
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
    @State private var selectedImage: PlatformImage?
    @State private var showingImageSelection = false
    
    private let categories = ["Solar Panels", "Inverters", "Batteries", "Mounting", "Electrical", "Tools"]
    
    init(item: Equipment, viewModel: EquipmentViewModel) {
        self.item = item
        self.viewModel = viewModel
        self._name = State(initialValue: item.name)
        self._manufacturer = State(initialValue: item.manufacturer)
        self._model = State(initialValue: item.model)
        self._category = State(initialValue: item.category.rawValue)
        self._minimumStock = State(initialValue: String(item.minimumStock))
        self._unitPrice = State(initialValue: String(item.unitPrice))
        self._description = State(initialValue: item.equipmentDescription)
        if let imageData = item.imageData {
            self._selectedImage = State(initialValue: PlatformImage(data: imageData))
        }
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
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    TextField("Unit Price", text: $unitPrice)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                
                Section("Additional Information") {
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Photo") {
                    HStack {
                        EquipmentImageView(imageData: selectedImage?.compressedData(), size: 80)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                showingImageSelection = true
                            }) {
                                HStack {
                                    Image(systemName: selectedImage == nil ? "camera.fill" : "photo.fill")
                                    Text(selectedImage == nil ? "Add Photo" : "Change Photo")
                                }
                                .foregroundColor(.orange)
                            }
                            
                            if selectedImage != nil {
                                Button(action: {
                                    selectedImage = nil
                                }) {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                        Text("Remove Photo")
                                    }
                                    .foregroundColor(.red)
                                }
                            }
                        }
                        
                        Spacer()
                    }
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
            .sheet(isPresented: $showingImageSelection) {
                ImageSelectionSheet(selectedImage: $selectedImage)
            }
        }
    }
    
    private func saveChanges() {
        let minStock = Int(minimumStock) ?? 0
        let price = Double(unitPrice) ?? 0.0
        
        // Update image data if changed
        let imageData = selectedImage?.resized(toWidth: 800)?.compressedData(quality: 0.8)
        
        viewModel.updateEquipmentWithImage(
            item,
            name: name,
            manufacturer: manufacturer,
            model: model,
            category: category,
            minimumStock: minStock,
            unitPrice: price,
            description: description,
            imageData: imageData
        )
        
        dismiss()
    }
}

// MARK: - Cross-Platform Image Selection Sheet

struct ImageSelectionSheet: View {
    @Binding var selectedImage: PlatformImage?
    @Environment(\.dismiss) private var dismiss
    @State private var showingPhotoLibrary = false
    @State private var showingCamera = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Photo")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    #if os(iOS)
                    Button(action: {
                        showingCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            Text("Take Photo")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                    #endif
                    
                    Button(action: {
                        showingPhotoLibrary = true
                    }) {
                        HStack {
                            Image(systemName: "photo.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            Text("Choose from Library")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                    }
                    
                    if selectedImage != nil {
                        Button(action: {
                            selectedImage = nil
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                
                                Text("Remove Photo")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        #if os(iOS)
        .sheet(isPresented: $showingPhotoLibrary) {
            ImagePicker(image: $selectedImage)
        }
        .sheet(isPresented: $showingCamera) {
            CameraImagePicker(image: $selectedImage)
        }
        #elseif os(macOS)
        .sheet(isPresented: $showingPhotoLibrary) {
            CrossPlatformImagePicker(image: $selectedImage, isPresented: $showingPhotoLibrary)
        }
        #endif
        .onChange(of: selectedImage) { _, _ in
            if selectedImage != nil {
                dismiss()
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Equipment.self)
    let viewModelContainer = ViewModelContainer(modelContext: container.mainContext)
    
    return InventoryListView()
        .modelContainer(container)
        .environment(\.viewModelContainer, viewModelContainer)
}

// MARK: - Cross-Platform Image Extensions

extension PlatformImage {
    func compressedData(quality: CGFloat = 0.8) -> Data? {
        #if os(iOS)
        return self.jpegData(compressionQuality: quality)
        #elseif os(macOS)
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality])
        #endif
    }
    
    func resized(toWidth width: CGFloat) -> PlatformImage? {
        #if os(iOS)
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
        #elseif os(macOS)
        let ratio = width / self.size.width
        let newSize = CGSize(width: width, height: self.size.height * ratio)
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        draw(in: NSRect(origin: .zero, size: newSize),
             from: NSRect(origin: .zero, size: self.size),
             operation: .copy,
             fraction: 1.0)
        newImage.unlockFocus()
        return newImage
        #endif
    }
}


