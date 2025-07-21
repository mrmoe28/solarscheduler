import SwiftUI
import SwiftData

struct VendorsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Vendor.name) private var vendors: [Vendor]
    @State private var showingAddVendor = false
    @State private var searchText = ""
    
    var filteredVendors: [Vendor] {
        if searchText.isEmpty {
            return vendors.filter { $0.isActive }
        }
        return vendors.filter { vendor in
            vendor.isActive && (
                vendor.name.localizedCaseInsensitiveContains(searchText) ||
                vendor.specialtiesString.localizedCaseInsensitiveContains(searchText)
            )
        }
    }
    
    var body: some View {
        List {
                ForEach(filteredVendors, id: \.id) { vendor in
                    VendorRowView(vendor: vendor)
                }
                .onDelete(perform: deleteVendors)
            }
            .searchable(text: $searchText, prompt: "Search vendors...")
            .navigationTitle("Vendors (\(filteredVendors.count))")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddVendor = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddVendor) {
                AddVendorView()
            }
    }
    
    private func deleteVendors(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredVendors[index])
            }
        }
    }
}

struct VendorRowView: View {
    let vendor: Vendor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vendor.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(vendor.contactEmail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        ForEach(0..<5) { star in
                            Image(systemName: star < Int(vendor.rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    
                    Text("\(vendor.completedInstallations) jobs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !vendor.specialties.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(vendor.specialties.prefix(3), id: \.self) { specialty in
                            Text(specialty.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        if vendor.specialties.count > 3 {
                            Text("+\(vendor.specialties.count - 3)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddVendorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var contactEmail = ""
    @State private var contactPhone = ""
    @State private var address = ""
    @State private var website = ""
    @State private var notes = ""
    @State private var selectedSpecialties: Set<VendorSpecialty> = []
    
    var body: some View {
        NavigationView {
            Form {
                Section("Company Information") {
                    TextField("Company Name", text: $name)
                    TextField("Website", text: $website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }
                
                Section("Contact Information") {
                    TextField("Email", text: $contactEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Phone", text: $contactPhone)
                        .keyboardType(.phonePad)
                    TextField("Address", text: $address, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Specialties") {
                    ForEach(VendorSpecialty.allCases, id: \.self) { specialty in
                        HStack {
                            Text(specialty.rawValue)
                            Spacer()
                            if selectedSpecialties.contains(specialty) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedSpecialties.contains(specialty) {
                                selectedSpecialties.remove(specialty)
                            } else {
                                selectedSpecialties.insert(specialty)
                            }
                        }
                    }
                }
                
                Section("Additional Information") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Vendor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveVendor()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !contactEmail.isEmpty
    }
    
    private func saveVendor() {
        let vendor = Vendor(
            name: name,
            contactEmail: contactEmail,
            contactPhone: contactPhone,
            address: address,
            specialties: Array(selectedSpecialties),
            rating: 0.0,
            notes: notes,
            website: website,
            emergencyContact: "",
            insuranceDetails: "",
            licenseNumber: ""
        )
        
        modelContext.insert(vendor)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    VendorsListView()
        .modelContainer(for: [Vendor.self])
}