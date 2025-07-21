import SwiftUI
import SwiftData

struct AddJobView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var customers: [Customer]
    @State private var userSession = UserSession.shared
    
    // Form state
    @State private var customerName = ""
    @State private var selectedCustomer: Customer?
    @State private var address = ""
    @State private var systemSize = ""
    @State private var selectedStatus: JobStatus = .pending
    @State private var scheduledDate = Date()
    @State private var hasScheduledDate = false
    @State private var estimatedRevenue = ""
    @State private var notes = ""
    
    // Site Visit state
    @State private var hasSiteVisit = false
    @State private var siteVisitDate = Date()
    @State private var siteVisitNotes = ""
    @State private var sitePhotos: [Data] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    
    // UI state
    @State private var showingCustomerPicker = false
    @State private var isNewCustomer = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Editing mode
    let jobToEdit: SolarJob?
    
    init(jobToEdit: SolarJob? = nil) {
        self.jobToEdit = jobToEdit
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Customer Section
                Section("Customer Information") {
                    // Customer selection toggle
                    Picker("Customer Type", selection: $isNewCustomer) {
                        Text("New Customer").tag(true)
                        Text("Existing Customer").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if isNewCustomer {
                        TextField("Customer Name", text: $customerName)
                            .textContentType(.name)
                    } else {
                        HStack {
                            Text("Customer")
                            Spacer()
                            if let selectedCustomer = selectedCustomer {
                                Text(selectedCustomer.name)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Select Customer")
                                    .foregroundColor(Color.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingCustomerPicker = true
                        }
                    }
                    
                    TextField("Installation Address", text: $address, axis: .vertical)
                        .textContentType(.fullStreetAddress)
                        .lineLimit(2...4)
                }
                
                // System Details
                Section("System Details") {
                    HStack {
                        TextField("System Size", text: $systemSize)
                            .keyboardType(.decimalPad)
                        Text("kW")
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(JobStatus.allCases, id: \.self) { status in
                            Label(status.rawValue, systemImage: statusIcon(for: status))
                                .tag(status)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Scheduling
                Section("Scheduling") {
                    Toggle("Schedule Installation Date", isOn: $hasScheduledDate)
                    
                    if hasScheduledDate {
                        DatePicker("Scheduled Date", selection: $scheduledDate, in: Date()..., displayedComponents: [.date])
                            .datePickerStyle(GraphicalDatePickerStyle())
                    }
                }
                
                // Financial
                Section("Financial Information") {
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("Estimated Revenue", text: $estimatedRevenue)
                            .keyboardType(.decimalPad)
                    }
                }
                
                // Site Visit
                Section("Site Visit") {
                    Toggle("Schedule Site Visit", isOn: $hasSiteVisit)
                    
                    if hasSiteVisit {
                        DatePicker("Visit Date", selection: $siteVisitDate, in: Date()..., displayedComponents: [.date])
                        
                        TextField("Site Visit Notes", text: $siteVisitNotes, axis: .vertical)
                            .lineLimit(2...4)
                        
                        // Photos Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Site Photos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    // Existing photos
                                    ForEach(Array(sitePhotos.enumerated()), id: \.offset) { index, photoData in
                                        ZStack(alignment: .topTrailing) {
                                            if let image = UIImage(data: photoData) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 80, height: 80)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                            
                                            Button(action: {
                                                sitePhotos.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.white)
                                                    .background(Color.black.opacity(0.6))
                                                    .clipShape(Circle())
                                            }
                                            .padding(4)
                                        }
                                    }
                                    
                                    // Add photo buttons
                                    Menu {
                                        Button(action: { showingCamera = true }) {
                                            Label("Take Photo", systemImage: "camera")
                                        }
                                        
                                        Button(action: { showingImagePicker = true }) {
                                            Label("Choose from Library", systemImage: "photo")
                                        }
                                    } label: {
                                        VStack {
                                            Image(systemName: "plus")
                                                .font(.title2)
                                                .foregroundColor(.blue)
                                            Text("Add Photo")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                        .frame(width: 80, height: 80)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                                .foregroundColor(.blue)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Additional Information
                Section("Additional Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle(jobToEdit == nil ? "New Solar Job" : "Edit Job")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Ensure UserSession is configured
                if userSession.currentUser == nil {
                    userSession.configure(with: modelContext)
                }
                print("👤 Current user: \(userSession.currentUser?.fullName ?? "None")")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(jobToEdit == nil ? "Create" : "Save") {
                        saveJob()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                loadJobData()
            }
            .sheet(isPresented: $showingCustomerPicker) {
                CustomerPickerView(selectedCustomer: $selectedCustomer)
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            #if os(iOS)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(images: $sitePhotos, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(images: $sitePhotos, sourceType: .camera)
            }
            #endif
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        let hasCustomer = isNewCustomer ? !customerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : selectedCustomer != nil
        let hasAddress = !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasSystemSize = !systemSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && Double(systemSize) != nil
        
        return hasCustomer && hasAddress && hasSystemSize
    }
    
    private func statusIcon(for status: JobStatus) -> String {
        switch status {
        case .pending: return "clock"
        case .approved: return "checkmark.circle"
        case .inProgress: return "hammer"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        case .onHold: return "pause.circle"
        }
    }
    
    private func loadJobData() {
        guard let job = jobToEdit else { return }
        
        // Load existing job data for editing
        if let customer = job.customer {
            selectedCustomer = customer
            isNewCustomer = false
        } else {
            customerName = job.customerName
            isNewCustomer = true
        }
        
        address = job.address
        systemSize = String(job.systemSize)
        selectedStatus = job.status
        
        if let scheduledDate = job.scheduledDate {
            self.scheduledDate = scheduledDate
            hasScheduledDate = true
        }
        
        estimatedRevenue = job.estimatedRevenue > 0 ? String(job.estimatedRevenue) : ""
        notes = job.notes
        
        // Load site visit data
        if let siteVisitDate = job.siteVisitDate {
            hasSiteVisit = true
            self.siteVisitDate = siteVisitDate
            siteVisitNotes = job.siteVisitNotes ?? ""
            sitePhotos = job.sitePhotos ?? []
        }
    }
    
    private func saveJob() {
        guard isFormValid else {
            alertMessage = "Please fill in all required fields."
            showingAlert = true
            return
        }
        
        guard let systemSizeValue = Double(systemSize) else {
            alertMessage = "Please enter a valid system size."
            showingAlert = true
            return
        }
        
        // Check if user is logged in
        guard userSession.currentUser != nil else {
            alertMessage = "You must be logged in to create a job."
            showingAlert = true
            print("❌ Error: No current user found in session")
            return
        }
        
        let revenueValue = Double(estimatedRevenue) ?? 0.0
        
        do {
            if let jobToEdit = jobToEdit {
                // Update existing job
                updateExistingJob(jobToEdit, systemSize: systemSizeValue, revenue: revenueValue)
            } else {
                // Create new job
                createNewJob(systemSize: systemSizeValue, revenue: revenueValue)
            }
            
            try modelContext.save()
            print("✅ Job saved successfully")
            dismiss()
            
        } catch {
            print("❌ Failed to save job: \(error)")
            alertMessage = "Failed to save job: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func updateExistingJob(_ job: SolarJob, systemSize: Double, revenue: Double) {
        if isNewCustomer {
            job.customerName = customerName.trimmingCharacters(in: .whitespacesAndNewlines)
            job.customer = nil
        } else {
            job.customer = selectedCustomer
            job.customerName = selectedCustomer?.name ?? ""
        }
        
        job.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        job.systemSize = systemSize
        job.status = selectedStatus
        job.scheduledDate = hasScheduledDate ? scheduledDate : nil
        job.estimatedRevenue = revenue
        job.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Update site visit data
        if hasSiteVisit {
            job.siteVisitDate = siteVisitDate
            job.siteVisitNotes = siteVisitNotes
            job.sitePhotos = sitePhotos
        } else {
            job.siteVisitDate = nil
            job.siteVisitNotes = ""
            job.sitePhotos = []
        }
    }
    
    private func createNewJob(systemSize: Double, revenue: Double) {
        let job = SolarJob(
            customerName: isNewCustomer ? customerName.trimmingCharacters(in: .whitespacesAndNewlines) : selectedCustomer?.name ?? "",
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            systemSize: systemSize,
            status: selectedStatus,
            scheduledDate: hasScheduledDate ? scheduledDate : nil,
            estimatedRevenue: revenue,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        if !isNewCustomer, let selectedCustomer = selectedCustomer {
            job.customer = selectedCustomer
        }
        
        // Add site visit data
        if hasSiteVisit {
            job.siteVisitDate = siteVisitDate
            job.siteVisitNotes = siteVisitNotes
            job.sitePhotos = sitePhotos
        }
        
        // Associate with current user
        job.user = userSession.currentUser
        
        modelContext.insert(job)
    }
}

// MARK: - Customer Picker View

struct CustomerPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var customers: [Customer]
    @Binding var selectedCustomer: Customer?
    @State private var searchText = ""
    
    var filteredCustomers: [Customer] {
        if searchText.isEmpty {
            return customers
        } else {
            return customers.filter { customer in
                customer.name.localizedCaseInsensitiveContains(searchText) ||
                customer.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCustomers) { customer in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(customer.name)
                                .font(.headline)
                            
                            Text(customer.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if !customer.address.isEmpty {
                                Text(customer.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        if selectedCustomer?.id == customer.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCustomer = customer
                        dismiss()
                    }
                }
            }
            .navigationTitle("Select Customer")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search customers")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if filteredCustomers.isEmpty {
                    ContentUnavailableView(
                        "No Customers Found",
                        systemImage: "person.slash",
                        description: Text(searchText.isEmpty ? "No customers available. Add customers first." : "No customers match your search.")
                    )
                }
            }
        }
    }
}

#Preview {
    AddJobView()
        .modelContainer(for: [SolarJob.self, Customer.self])
}

#Preview("Edit Mode") {
    let job = SolarJob(
        customerName: "John Doe",
        address: "123 Main St, Anytown, USA",
        systemSize: 10.5,
        estimatedRevenue: 25000.0,
        notes: "Sample job for preview"
    )
    
    return AddJobView(jobToEdit: job)
        .modelContainer(for: [SolarJob.self, Customer.self])
}

// MARK: - Image Picker for iOS
#if os(iOS)
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [Data]
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
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
            if let image = info[.originalImage] as? UIImage,
               let imageData = image.jpegData(compressionQuality: 0.7) {
                parent.images.append(imageData)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif