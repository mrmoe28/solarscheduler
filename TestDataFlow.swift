import SwiftUI
import SwiftData

// Test view to verify data flow works correctly
struct TestDataFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.viewModelContainer) private var viewModelContainer
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Testing Data Flow")
                .font(.title)
                .bold()
            
            Button("Create Test Customer") {
                testCreateCustomer()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Create Test Job") {
                testCreateJob()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Create Test Installation") {
                testCreateInstallation()
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Print All Data") {
                printAllData()
            }
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
    
    private func testCreateCustomer() {
        guard let container = viewModelContainer else {
            print("❌ ViewModelContainer not available")
            return
        }
        
        let viewModel = container.customersViewModel
        viewModel.newCustomerName = "Test Customer \(Date().timeIntervalSince1970)"
        viewModel.newCustomerEmail = "test@example.com"
        viewModel.newCustomerPhone = "555-0123"
        viewModel.newCustomerAddress = "123 Test St"
        viewModel.addCustomer()
        
        if viewModel.formErrors.isEmpty {
            print("✅ Customer created successfully!")
        } else {
            print("❌ Customer creation failed: \(viewModel.formErrors)")
        }
    }
    
    private func testCreateJob() {
        guard let container = viewModelContainer else {
            print("❌ ViewModelContainer not available")
            return
        }
        
        let viewModel = container.jobsViewModel
        viewModel.newJobCustomerName = "Test Job Customer \(Date().timeIntervalSince1970)"
        viewModel.newJobAddress = "123 Job St"
        viewModel.newJobSystemSize = 10.0
        viewModel.newJobEstimatedRevenue = 25000.0
        viewModel.addJob()
        
        if viewModel.formErrors.isEmpty {
            print("✅ Job created successfully!")
        } else {
            print("❌ Job creation failed: \(viewModel.formErrors)")
        }
    }
    
    private func testCreateInstallation() {
        guard let container = viewModelContainer else {
            print("❌ ViewModelContainer not available")
            return
        }
        
        let installationViewModel = container.installationsViewModel
        let jobsViewModel = container.jobsViewModel
        
        // First ensure we have jobs available
        jobsViewModel.loadJobs()
        
        let availableJobs = installationViewModel.getAvailableJobs()
        guard let firstJob = availableJobs.first else {
            print("❌ No available jobs for installation")
            return
        }
        
        installationViewModel.newInstallationJobId = firstJob.id
        installationViewModel.newInstallationScheduledDate = Date().addingTimeInterval(86400) // Tomorrow
        installationViewModel.newInstallationEstimatedDuration = 8 * 3600 // 8 hours
        installationViewModel.newInstallationCrewSize = 3
        installationViewModel.newInstallationNotes = "Test installation"
        installationViewModel.addInstallation()
        
        if installationViewModel.formErrors.isEmpty {
            print("✅ Installation created successfully!")
        } else {
            print("❌ Installation creation failed: \(installationViewModel.formErrors)")
        }
    }
    
    private func printAllData() {
        guard let container = viewModelContainer else {
            print("❌ ViewModelContainer not available")
            return
        }
        
        print("📊 Current Data:")
        print("Customers: \(container.customersViewModel.customers.count)")
        print("Jobs: \(container.jobsViewModel.jobs.count)")
        print("Installations: \(container.installationsViewModel.installations.count)")
        
        // Print some details
        for customer in container.customersViewModel.customers.prefix(3) {
            print("Customer: \(customer.name) - \(customer.email)")
        }
        
        for job in container.jobsViewModel.jobs.prefix(3) {
            print("Job: \(job.customerName) - $\(job.estimatedRevenue)")
        }
        
        for installation in container.installationsViewModel.installations.prefix(3) {
            print("Installation: \(installation.scheduledDate) - \(installation.status)")
        }
    }
}

#Preview {
    TestDataFlowView()
}