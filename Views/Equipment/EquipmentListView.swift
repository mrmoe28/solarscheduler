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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: equipment.category.icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(equipment.name)
                        .font(.headline)
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
        .padding(.vertical, 4)
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