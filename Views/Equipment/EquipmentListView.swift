import SwiftUI
import SwiftData

struct EquipmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Equipment.name) private var equipment: [Equipment]
    @State private var showingAddEquipment = false
    @State private var searchText = ""
    @State private var selectedCategory: EquipmentCategory?
    @State private var showLowStockOnly = false
    
    var filteredEquipment: [Equipment] {
        var filtered = equipment
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.brand.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if showLowStockOnly {
            filtered = filtered.filter { $0.isLowStock }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Section
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "All",
                            isSelected: selectedCategory == nil && !showLowStockOnly
                        ) {
                            selectedCategory = nil
                            showLowStockOnly = false
                        }
                        
                        FilterChip(
                            title: "Low Stock",
                            isSelected: showLowStockOnly,
                            count: equipment.filter { $0.isLowStock }.count
                        ) {
                            showLowStockOnly.toggle()
                            selectedCategory = nil
                        }
                        
                        ForEach(EquipmentCategory.allCases, id: \.self) { category in
                            FilterChip(
                                title: category.rawValue,
                                isSelected: selectedCategory == category,
                                count: equipment.filter { $0.category == category }.count
                            ) {
                                selectedCategory = selectedCategory == category ? nil : category
                                showLowStockOnly = false
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Equipment List
                List {
                    ForEach(filteredEquipment, id: \.id) { equipment in
                        EquipmentRowView(equipment: equipment)
                    }
                    .onDelete(perform: deleteEquipment)
                }
                .searchable(text: $searchText, prompt: "Search equipment...")
            }
            .navigationTitle("Equipment (\(filteredEquipment.count))")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEquipment = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEquipment) {
                AddEquipmentView()
            }
        }
    }
    
    private func deleteEquipment(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredEquipment[index])
            }
        }
    }
}

struct EquipmentRowView: View {
    let equipment: Equipment
    @State private var showingDetail = false
    @State private var showingDeleteAlert = false
    @State private var showShareSheet = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack(spacing: 12) {
            // Main content - clickable
            Button(action: { showingDetail = true }) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: equipment.category.icon)
                            .foregroundColor(Color.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(equipment.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text("\(equipment.brand) • \(equipment.model)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack {
                                if equipment.isLowStock {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                                Text("\(equipment.quantity)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(equipment.isLowStock ? .red : .primary)
                            }
                            
                            Text("$\(equipment.unitPrice.safeValue, specifier: "%.2f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text(equipment.category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        Text("Total: $\(equipment.totalValue.safeValue, specifier: "%.2f")")
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
        .padding(.vertical, 4)
        .sheet(isPresented: $showingDetail) {
            NavigationStack {
                EquipmentDetailView(equipment: equipment)
            }
        }
        .alert("Delete Equipment", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(equipment)
                do {
                    try modelContext.save()
                } catch {
                    print("Failed to delete equipment: \(error)")
                }
            }
        } message: {
            Text("Are you sure you want to delete this equipment? This action cannot be undone.")
        }
        #if os(iOS)
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(items: [createEquipmentShareText()])
        }
        #endif
    }
    
    private func createEquipmentShareText() -> String {
        """
        Equipment Details:
        Name: \(equipment.name)
        Brand: \(equipment.brand)
        Model: \(equipment.model)
        Category: \(equipment.category.rawValue)
        Quantity: \(equipment.quantity) units
        Unit Price: $\(equipment.unitPrice.formatted())
        Total Value: $\(equipment.totalValue.formatted())
        Status: \(equipment.isLowStock ? "⚠️ Low Stock" : "✅ In Stock")
        """
    }
}

// MARK: - Equipment Detail View
struct EquipmentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var equipment: Equipment
    @State private var showingEditEquipment = false
    @State private var showingDeleteAlert = false
    @State private var adjustmentAmount = ""
    @State private var showingAdjustStock = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(equipment.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(equipment.brand) • \(equipment.model)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: equipment.category.icon)
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                    }
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Stock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                Text("\(equipment.quantity)")
                                    .font(.headline)
                                    .foregroundColor(equipment.isLowStock ? .red : .green)
                                if equipment.isLowStock {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Unit Price")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(equipment.unitPrice, specifier: "%.2f")")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Value")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(equipment.totalValue, specifier: "%.2f")")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                    }
                }
                .padding(20)
                .background(Color.secondarySystemBackground)
                .cornerRadius(12)
                
                // Category Badge
                HStack {
                    Text(equipment.category.rawValue)
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                
                // Equipment Details
                VStack(alignment: .leading, spacing: 16) {
                    Text("Equipment Details")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        DetailRow(label: "Manufacturer", value: equipment.manufacturer.isEmpty ? "N/A" : equipment.manufacturer)
                        DetailRow(label: "Supplier", value: equipment.supplier.isEmpty ? "N/A" : equipment.supplier)
                        DetailRow(label: "Warranty Period", value: "\(equipment.warrantyPeriod) months")
                        DetailRow(label: "Low Stock Threshold", value: "\(equipment.lowStockThreshold) units")
                        DetailRow(label: "Minimum Stock", value: "\(equipment.minimumStock) units")
                    }
                    .padding(16)
                    .background(Color.secondarySystemBackground)
                    .cornerRadius(12)
                }
                
                // Description
                if !equipment.equipmentDescription.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(equipment.equipmentDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(16)
                            .background(Color.secondarySystemBackground)
                            .cornerRadius(12)
                    }
                }
                
                // Quick Actions
                VStack(spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 8) {
                        EquipmentActionButton(
                            icon: "plus.minus",
                            title: "Adjust Stock",
                            color: .orange
                        ) {
                            showingAdjustStock = true
                        }
                        
                        EquipmentActionButton(
                            icon: "pencil",
                            title: "Edit Equipment",
                            color: .blue
                        ) {
                            showingEditEquipment = true
                        }
                        
                        EquipmentActionButton(
                            icon: "trash",
                            title: "Delete Equipment",
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
        .navigationTitle("Equipment Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showingEditEquipment) {
            NavigationStack {
                Text("Edit Equipment") // Placeholder for edit view
                    .navigationTitle("Edit Equipment")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showingEditEquipment = false }
                        }
                    }
            }
        }
        .alert("Delete Equipment", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteEquipment()
            }
        } message: {
            Text("Are you sure you want to delete this equipment? This action cannot be undone.")
        }
        .alert("Adjust Stock", isPresented: $showingAdjustStock) {
            TextField("Adjustment amount (use - for removal)", text: $adjustmentAmount)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
            Button("Cancel", role: .cancel) {
                adjustmentAmount = ""
            }
            Button("Adjust") {
                if let amount = Int(adjustmentAmount) {
                    equipment.adjustStock(by: amount)
                    saveChanges()
                }
                adjustmentAmount = ""
            }
        } message: {
            Text("Enter the amount to add or remove from stock")
        }
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save equipment changes: \(error)")
        }
    }
    
    private func deleteEquipment() {
        modelContext.delete(equipment)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete equipment: \(error)")
        }
    }
}

// MARK: - Equipment Action Button
struct EquipmentActionButton: View {
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
            .background(Color.secondarySystemBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct AddEquipmentView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Add New Equipment")
                .navigationTitle("New Equipment")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    EquipmentListView()
        .modelContainer(for: [Equipment.self])
}

