import SwiftUI
import SwiftData

struct AddInstallationView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: InstallationsViewModel
    
    var body: some View {
        Form {
                Section("Job Selection") {
                    Picker("Select Job", selection: $viewModel.newInstallationJobId) {
                        Text("Select a job...").tag(UUID?.none)
                        ForEach(viewModel.getAvailableJobs(), id: \.id) { job in
                            Text("\(job.customerName) - \(job.address)")
                                .tag(UUID?.some(job.id))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: viewModel.newInstallationJobId) { _, _ in
                        // Clear validation errors when job selection changes
                        viewModel.clearFormErrors()
                    }
                    
                    // Show selected job details
                    if let selectedJobId = viewModel.newInstallationJobId,
                       let selectedJob = viewModel.getAvailableJobs().first(where: { $0.id == selectedJobId }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected Job Details:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text("\(selectedJob.customerName)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(selectedJob.address)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(selectedJob.systemSize, specifier: "%.1f") kW • \(selectedJob.status.rawValue)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.secondarySystemBackground)
                        .cornerRadius(8)
                    }
                    
                    if viewModel.getAvailableJobs().isEmpty {
                        Text("No jobs available for scheduling. Create a job first or ensure jobs are in Pending or Approved status.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
                }
                
                Section("Schedule Details") {
                    DatePicker("Scheduled Date", selection: $viewModel.newInstallationScheduledDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                    
                    HStack {
                        Text("Estimated Duration")
                        Spacer()
                        Picker("Duration", selection: $viewModel.newInstallationEstimatedDuration) {
                            Text("4 hours").tag(4 * 3600.0)
                            Text("6 hours").tag(6 * 3600.0)
                            Text("8 hours").tag(8 * 3600.0)
                            Text("10 hours").tag(10 * 3600.0)
                            Text("12 hours").tag(12 * 3600.0)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("Crew Size")
                        Spacer()
                        Picker("Crew Size", selection: $viewModel.newInstallationCrewSize) {
                            ForEach(1...6, id: \.self) { size in
                                Text("\(size) people").tag(size)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section("Notes") {
                    TextField("Installation notes...", text: $viewModel.newInstallationNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Validation Errors
                if !viewModel.formErrors.isEmpty {
                    Section("Please fix the following errors:") {
                        ForEach(viewModel.formErrors, id: \.field) { error in
                            Text(error.message)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            }
        .navigationTitle("Schedule Installation")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button("Schedule") {
                    viewModel.addInstallation()
                    if viewModel.formErrors.isEmpty {
                        dismiss()
                    }
                }
                .disabled(viewModel.newInstallationJobId == nil)
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Installation.self, SolarJob.self, Customer.self, Equipment.self, Vendor.self, Contract.self)
    let dataService = DataService(modelContext: container.mainContext)
    let viewModel = InstallationsViewModel(dataService: dataService)
    
    return AddInstallationView(viewModel: viewModel)
        .modelContainer(container)
}