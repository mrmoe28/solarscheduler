import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct ContactsListView: View {
    @Environment(\.viewModelContainer) private var viewModelContainer
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var showingAddContact = false
    @State private var selectedContact: Customer?
    @State private var showingContactDetail = false
    @State private var viewModel: CustomersViewModel?
    
    private var currentViewModel: CustomersViewModel {
        if let vm = viewModel {
            return vm
        } else {
            if let container = viewModelContainer {
                return container.customersViewModel
            } else {
                let dataService = DataService(modelContext: modelContext)
                let newViewModel = CustomersViewModel(dataService: dataService)
                viewModel = newViewModel
                return newViewModel
            }
        }
    }
    
    private var filteredContacts: [Customer] {
        if searchText.isEmpty {
            return currentViewModel.customers
        } else {
            return currentViewModel.customers.filter { contact in
                contact.name.localizedCaseInsensitiveContains(searchText) ||
                contact.email.localizedCaseInsensitiveContains(searchText) ||
                contact.phone.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                if currentViewModel.isLoading {
                    LoadingView()
                } else if filteredContacts.isEmpty {
                    EmptyContactsView(searchText: searchText) {
                        showingAddContact = true
                    }
                } else {
                    ContactsList(
                        contacts: filteredContacts,
                        onContactTap: { contact in
                            selectedContact = contact
                            showingContactDetail = true
                        }
                    )
                }
                
                Spacer()
            }
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddContact = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: showingAddContact)
                }
            }
            .refreshable {
                currentViewModel.refreshData()
            }
            .onAppear {
                currentViewModel.refreshData()
            }
        .sheet(isPresented: $showingAddContact) {
            AddContactView(viewModel: viewModel)
        }
        .sheet(item: $selectedContact) { contact in
            ContactDetailView(contact: contact, viewModel: viewModel)
        }
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search contacts...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.orange)
            
            Text("Loading contacts...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty Contacts View

struct EmptyContactsView: View {
    let searchText: String
    let onAddContact: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: searchText.isEmpty ? "person.2.badge.plus" : "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.orange.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Contacts Yet" : "No Results Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(searchText.isEmpty ? 
                     "Add your first contact to get started" : 
                     "Try adjusting your search terms")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if searchText.isEmpty {
                Button(action: onAddContact) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Contact")
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
}

// MARK: - Contacts List

struct ContactsList: View {
    let contacts: [Customer]
    let onContactTap: (Customer) -> Void
    
    var body: some View {
        List {
            ForEach(contacts, id: \.id) { contact in
                ContactRowView(contact: contact)
                    .onTapGesture {
                        onContactTap(contact)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Contact Row View

struct ContactRowView: View {
    let contact: Customer
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ContactAvatarView(name: contact.name)
            
            // Contact Info
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !contact.email.isEmpty {
                    Text(contact.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if !contact.phone.isEmpty {
                    Text(contact.phone)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status Indicator
            ContactStatusIndicator(customer: contact)
        }
        .padding(.vertical, 4)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Contact Avatar View

struct ContactAvatarView: View {
    let name: String
    
    private var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first?.uppercased() ?? ""
        let lastInitial = components.count > 1 ? components.last?.first?.uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.8))
                .frame(width: 50, height: 50)
            
            Text(initials)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Contact Status Indicator

struct ContactStatusIndicator: View {
    let customer: Customer
    
    var body: some View {
        VStack(spacing: 4) {
            // Active jobs count
            if customer.activeJobsCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "hammer.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("\(customer.activeJobsCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
            
            // Last contact indicator
            Circle()
                .fill(recentContactColor)
                .frame(width: 8, height: 8)
        }
    }
    
    private var recentContactColor: Color {
        let daysSinceLastContact = Calendar.current.dateComponents([.day], from: customer.lastContactDate, to: Date()).day ?? 0
        
        if daysSinceLastContact <= 7 {
            return .green
        } else if daysSinceLastContact <= 30 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Add Contact View

struct AddContactView: View {
    let viewModel: CustomersViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Contact Information") {
                    TextField("Full Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Address") {
                    TextField("Address", text: $address, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Notes") {
                    TextField("Additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveContact()
                    }
                    .disabled(name.isEmpty)
                    .sensoryFeedback(.success, trigger: name.isEmpty == false)
                }
            }
        }
    }
    
    private func saveContact() {
        let newCustomer = Customer(
            name: name,
            email: email,
            phone: phone,
            address: address,
            notes: notes
        )
        
        currentViewModel.addCustomer(newCustomer)
        dismiss()
    }
}

// MARK: - Contact Detail View

struct ContactDetailView: View {
    let contact: Customer
    let viewModel: CustomersViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    ContactDetailHeader(contact: contact)
                    
                    // Contact Information
                    ContactDetailInfo(contact: contact)
                    
                    // Recent Jobs
                    ContactJobsSection(contact: contact)
                    
                    // Quick Actions
                    ContactQuickActions(contact: contact)
                }
                .padding()
            }
            .navigationTitle("Contact Details")
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
            EditContactView(contact: contact, viewModel: viewModel)
        }
    }
}

// MARK: - Contact Detail Components

struct ContactDetailHeader: View {
    let contact: Customer
    
    var body: some View {
        HStack(spacing: 16) {
            ContactAvatarView(name: contact.name)
                .scaleEffect(1.5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Customer since \(contact.createdDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical)
    }
}

struct ContactDetailInfo: View {
    let contact: Customer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Contact Information")
            
            if !contact.email.isEmpty {
                ContactInfoRow(icon: "envelope.fill", title: "Email", value: contact.email)
            }
            
            if !contact.phone.isEmpty {
                ContactInfoRow(icon: "phone.fill", title: "Phone", value: contact.phone)
            }
            
            if !contact.address.isEmpty {
                ContactInfoRow(icon: "location.fill", title: "Address", value: contact.address)
            }
            
            if !contact.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(contact.notes)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct ContactInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ContactJobsSection: View {
    let contact: Customer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Recent Jobs")
            
            // This would show recent jobs for this contact
            Text("Job history will be displayed here")
                .font(.body)
                .foregroundColor(.secondary)
                .italic()
        }
    }
}

struct ContactQuickActions: View {
    let contact: Customer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Quick Actions")
            
            HStack(spacing: 16) {
                QuickActionButton(
                    icon: "phone.fill",
                    title: "Call",
                    color: .green
                ) {
                    // Handle phone call
                    #if os(iOS)
                    if let url = URL(string: "tel:\(contact.phone)") {
                        UIApplication.shared.open(url)
                    }
                    #elseif os(macOS)
                    // Copy phone number to clipboard on macOS
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(contact.phone, forType: .string)
                    #endif
                }
                
                QuickActionButton(
                    icon: "envelope.fill",
                    title: "Email",
                    color: .blue
                ) {
                    // Handle email
                    if let url = URL(string: "mailto:\(contact.email)") {
                        #if os(iOS)
                        UIApplication.shared.open(url)
                        #elseif os(macOS)
                        NSWorkspace.shared.open(url)
                        #endif
                    }
                }
                
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "New Job",
                    color: .orange
                ) {
                    // Handle new job creation
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(BouncyButtonStyle())
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

// MARK: - Edit Contact View

struct EditContactView: View {
    let contact: Customer
    let viewModel: CustomersViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var email: String
    @State private var phone: String
    @State private var address: String
    @State private var notes: String
    
    init(contact: Customer, viewModel: CustomersViewModel) {
        self.contact = contact
        self.viewModel = viewModel
        self._name = State(initialValue: contact.name)
        self._email = State(initialValue: contact.email)
        self._phone = State(initialValue: contact.phone)
        self._address = State(initialValue: contact.address)
        self._notes = State(initialValue: contact.notes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Contact Information") {
                    TextField("Full Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Address") {
                    TextField("Address", text: $address, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Notes") {
                    TextField("Additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Contact")
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
        // Update the contact
        currentViewModel.updateCustomer(
            contact,
            name: name,
            email: email,
            phone: phone,
            address: address,
            notes: notes
        )
        dismiss()
    }
}

#Preview {
    ContactsListView()
        .modelContainer(for: [Customer.self])
}