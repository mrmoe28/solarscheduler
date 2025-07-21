import SwiftUI
import SwiftData

struct AddVendorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var contactName = ""
    @State private var contactEmail = ""
    @State private var contactPhone = ""
    @State private var address = ""
    @State private var website = ""
    @State private var notes = ""
    @State private var vendorType: VendorType = .supplier
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Vendor Information") {
                    TextField("Company Name", text: $name)
                    
                    Picker("Vendor Type", selection: $vendorType) {
                        ForEach(VendorType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Contact Details") {
                    TextField("Contact Name", text: $contactName)
                    TextField("Email", text: $contactEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Phone", text: $contactPhone)
                        .keyboardType(.phonePad)
                }
                
                Section("Address") {
                    TextField("Address", text: $address, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Additional Information") {
                    TextField("Website", text: $website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Vendor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveVendor()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || contactEmail.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveVendor() {
        // Validate email
        if !contactEmail.isEmpty && !isValidEmail(contactEmail) {
            errorMessage = "Please enter a valid email address"
            showingError = true
            return
        }
        
        // Create new vendor
        let vendor = Vendor(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            contactName: contactName.trimmingCharacters(in: .whitespacesAndNewlines),
            contactEmail: contactEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            contactPhone: contactPhone.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            website: website.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            vendorType: vendorType
        )
        
        modelContext.insert(vendor)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save vendor: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

#Preview {
    AddVendorView()
        .modelContainer(for: Vendor.self, inMemory: true)
}