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
        NavigationView {
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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Add New Vendor")
                .navigationTitle("New Vendor")
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
    VendorsListView()
        .modelContainer(for: [Vendor.self])
}