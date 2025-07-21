import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

// MARK: - Main Inventory View
struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var equipment: [Equipment]
    
    @State private var showingAddEquipment = false
    @State private var selectedCategory: EquipmentCategory = .panels
    @State private var searchText = ""
    @State private var selectedEquipment: Equipment?
    
    // Add 'all' option to category filter
    private enum CategoryFilter: String, CaseIterable {
        case all = "All"
        case panels = "Solar Panels"
        case inverters = "Inverters"
        case mounting = "Mounting Systems"
        case electrical = "Electrical Components"
        case batteries = "Battery Storage"
        case monitoring = "Monitoring Systems"
        case tools = "Installation Tools"
        case safety = "Safety Equipment"
        
        var equipmentCategory: EquipmentCategory? {
            switch self {
            case .all: return nil
            case .panels: return .panels
            case .inverters: return .inverters
            case .mounting: return .mounting
            case .electrical: return .electrical
            case .batteries: return .batteries
            case .monitoring: return .monitoring
            case .tools: return .tools
            case .safety: return .safety
            }
        }
    }
    
    @State private var selectedCategoryFilter: CategoryFilter = .all
    
    private var filteredEquipment: [Equipment] {
        var filtered = equipment
        
        if let category = selectedCategoryFilter.equipmentCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.brand.localizedCaseInsensitiveContains(searchText) ||
                item.model.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    private var lowStockItems: [Equipment] {
        equipment.filter { $0.quantity <= $0.lowStockThreshold }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with stats
                inventoryHeader
                
                // Category filter
                categoryFilter
                
                // Equipment grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        ForEach(filteredEquipment, id: \.id) { item in
                            EquipmentCard(equipment: item)
                                .onTapGesture {
                                    selectedEquipment = item
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddEquipment = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showingAddEquipment) {
                AddEquipmentSheet()
            }
            .sheet(item: $selectedEquipment) { equipment in
                EquipmentDetailSheet(equipment: equipment)
            }
        }
        .searchable(text: $searchText, prompt: "Search equipment...")
    }
    
    // MARK: - Inventory Header
    private var inventoryHeader: some View {
        VStack(spacing: 16) {
            // Quick stats
            HStack(spacing: 16) {
                InventoryStatView(
                    title: "Total Items",
                    value: "\(equipment.count)",
                    icon: "box.fill",
                    color: .blue
                )
                
                InventoryStatView(
                    title: "Low Stock",
                    value: "\(lowStockItems.count)",
                    icon: "exclamationmark.triangle.fill",
                    color: lowStockItems.isEmpty ? .green : .red
                )
                
                InventoryStatView(
                    title: "Categories",
                    value: "\(Set(equipment.map { $0.category }).count)",
                    icon: "tag.fill",
                    color: .orange
                )
            }
            .padding(.horizontal, 16)
            
            // Low stock alert
            if !lowStockItems.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("\(lowStockItems.count) items running low on stock")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CategoryFilter.allCases, id: \.self) { category in
                    CategoryPill(
                        title: category.rawValue,
                        count: category == .all ? equipment.count : equipment.filter { $0.category == category.equipmentCategory }.count,
                        isSelected: selectedCategoryFilter == category
                    )
                    .onTapGesture {
                        selectedCategoryFilter = category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
}

// MARK: - Equipment Card
struct EquipmentCard: View {
    let equipment: Equipment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Equipment image or placeholder
            Group {
                #if os(iOS)
                if let imageData = equipment.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // Default placeholder based on category
                    Image(systemName: equipment.category.icon)
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.orange.opacity(0.1))
                }
                #elseif os(macOS)
                if let imageData = equipment.imageData,
                   let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // Default placeholder based on category
                    Image(systemName: equipment.category.icon)
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.orange.opacity(0.1))
                }
                #endif
            }
            .frame(height: 120)
            .clipped()
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(equipment.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Text("\(equipment.brand) \(equipment.model)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "number")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(equipment.quantity)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(equipment.quantity <= equipment.lowStockThreshold ? .red : .primary)
                    }
                    
                    Spacer()
                    
                    Text("$\(equipment.unitPrice, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                if !equipment.equipmentDescription.isEmpty {
                    Text(equipment.equipmentDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            // Stock warning badge
            Group {
                if equipment.quantity <= equipment.lowStockThreshold {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
        )
    }
}

// MARK: - Add Equipment Sheet
struct AddEquipmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var category = EquipmentCategory.panels
    @State private var brand = ""
    @State private var model = ""
    @State private var quantity = ""
    @State private var unitPrice = ""
    @State private var equipmentDescription = ""
    @State private var lowStockThreshold = "5"
    @State private var selectedImage: PlatformImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingImageOptions = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, brand, model, quantity, unitPrice, description, threshold
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !brand.isEmpty && !model.isEmpty && 
        !quantity.isEmpty && !unitPrice.isEmpty &&
        Int(quantity) != nil && Double(unitPrice) != nil
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: "box.badge.plus")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("Add Equipment")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    // Image upload section
                    imageUploadSection
                    
                    // Form sections
                    VStack(spacing: 24) {
                        // Basic Information
                        FormSection(title: "Basic Information", icon: "info.circle.fill") {
                            CustomTextField(
                                title: "Equipment Name",
                                text: $name,
                                placeholder: "Tier 1 Solar Panel",
                                icon: "tag"
                            )
                            .focused($focusedField, equals: .name)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "list.bullet")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    Text("Category")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Picker("Category", selection: $category) {
                                    ForEach(EquipmentCategory.allCases, id: \.self) { cat in
                                        Text(cat.rawValue).tag(cat)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.orange)
                            }
                            
                            CustomTextField(
                                title: "Brand",
                                text: $brand,
                                placeholder: "SunPower",
                                icon: "building.2"
                            )
                            .focused($focusedField, equals: .brand)
                            
                            CustomTextField(
                                title: "Model",
                                text: $model,
                                placeholder: "X-Series X22-370",
                                icon: "rectangle.3.group"
                            )
                            .focused($focusedField, equals: .model)
                        }
                        
                        // Quantity and Pricing
                        FormSection(title: "Inventory Details", icon: "number.circle.fill") {
                            HStack(spacing: 16) {
                                CustomTextField(
                                    title: "Quantity",
                                    text: $quantity,
                                    placeholder: "50",
                                    icon: "number"
                                )
                                .focused($focusedField, equals: .quantity)
                                .keyboardType(.numberPad)
                                
                                CustomTextField(
                                    title: "Unit Price",
                                    text: $unitPrice,
                                    placeholder: "300",
                                    icon: "dollarsign.circle"
                                )
                                .focused($focusedField, equals: .unitPrice)
                                .keyboardType(.decimalPad)
                            }
                            
                            CustomTextField(
                                title: "Low Stock Alert",
                                text: $lowStockThreshold,
                                placeholder: "5",
                                icon: "exclamationmark.triangle"
                            )
                            .focused($focusedField, equals: .threshold)
                            .keyboardType(.numberPad)
                        }
                        
                        // Description
                        FormSection(title: "Description", icon: "doc.text") {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    Text("Equipment Description")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                TextEditor(text: $equipmentDescription)
                                    .frame(minHeight: 80)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .focused($focusedField, equals: .description)
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
                    Button("Save Equipment") {
                        saveEquipment()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? .orange : .secondary)
                    .disabled(!isFormValid)
                }
            }
        }
        .confirmationDialog("Add Photo", isPresented: $showingImageOptions) {
            Button("Camera") {
                showingCamera = true
            }
            Button("Photo Library") {
                showingImagePicker = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
    }
    
    // MARK: - Image Upload Section
    private var imageUploadSection: some View {
        VStack(spacing: 12) {
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(
                        Button {
                            showingImageOptions = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(8),
                        alignment: .topTrailing
                    )
            } else {
                Button {
                    showingImageOptions = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("Add Equipment Photo")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Text("Tap to add image from camera or library")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func saveEquipment() {
        guard isFormValid,
              let quantityInt = Int(quantity),
              let priceDouble = Double(unitPrice),
              let thresholdInt = Int(lowStockThreshold) else { return }
        
        let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
        
        let newEquipment = Equipment(
            name: name,
            category: category,
            brand: brand,
            model: model,
            quantity: quantityInt,
            unitPrice: priceDouble,
            equipmentDescription: equipmentDescription,
            imageData: imageData,
            lowStockThreshold: thresholdInt
        )
        
        modelContext.insert(newEquipment)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save equipment: \(error)")
        }
    }
}

// MARK: - Supporting Views
struct InventoryStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CategoryPill: View {
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
                .fontWeight(.bold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(isSelected ? Color.white : Color.orange.opacity(0.2))
                .foregroundColor(isSelected ? .orange : .orange)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.orange : Color(.systemGray6))
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(20)
    }
}

// MARK: - Equipment Detail Sheet
struct EquipmentDetailSheet: View {
    let equipment: Equipment
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var equipmentDescription: String = ""
    @State private var isEditingDescription = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Equipment image
                    Group {
                        #if os(iOS)
                        if let imageData = equipment.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 250)
                                .clipped()
                        } else {
                            Image(systemName: equipment.category.icon)
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                                .frame(height: 250)
                                .frame(maxWidth: .infinity)
                                .background(Color.orange.opacity(0.1))
                        }
                        #elseif os(macOS)
                        if let imageData = equipment.imageData,
                           let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 250)
                                .clipped()
                        } else {
                            Image(systemName: equipment.category.icon)
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                                .frame(height: 250)
                                .frame(maxWidth: .infinity)
                                .background(Color.orange.opacity(0.1))
                        }
                        #endif
                        }
                    }
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    // Equipment details
                    VStack(spacing: 16) {
                        Text(equipment.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("\(equipment.brand) \(equipment.model)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        // Stats
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(equipment.quantity)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(equipment.quantity <= equipment.lowStockThreshold ? .red : .primary)
                                Text("In Stock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack {
                                Text("$\(equipment.unitPrice, specifier: "%.0f")")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text("Unit Price")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack {
                                Text("$\(Double(equipment.quantity) * equipment.unitPrice, specifier: "%.0f")")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.blue)
                                Text("Total Value")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Description section with edit capability
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Description")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button {
                                    if isEditingDescription {
                                        // Save description (in a real app, you'd update the model)
                                        isEditingDescription = false
                                    } else {
                                        equipmentDescription = equipment.equipmentDescription
                                        isEditingDescription = true
                                    }
                                } label: {
                                    Image(systemName: isEditingDescription ? "checkmark" : "pencil")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            if isEditingDescription {
                                TextEditor(text: $equipmentDescription)
                                    .frame(minHeight: 100)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            } else {
                                Text(equipment.equipmentDescription.isEmpty ? "No description available" : equipment.equipmentDescription)
                                    .font(.body)
                                    .foregroundColor(equipment.equipmentDescription.isEmpty ? .secondary : .primary)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
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

// MARK: - Image Picker
#if os(iOS)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif

// MARK: - Form Components (moved from CustomerViews.swift for reusability)
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

// MARK: - Jobs List View (if it exists and is needed)
struct JobsListView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Solar Jobs")
                    .font(.largeTitle)
                    .padding()
                Text("Manage your solar installation projects")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Jobs")
        }
    }
}

#Preview {
    InventoryView()
}