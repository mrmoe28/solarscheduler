import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.viewModelContainer) private var viewModelContainer
    @State private var selectedTimeFilter: TimeFilter = .today
    @StateObject private var realTimeService = RealTimeDataService()
    @StateObject private var performanceService = PerformanceMetricsService()
    @StateObject private var notificationService = EnhancedNotificationService()
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel?
    
    private var currentViewModel: DashboardViewModel {
        if let vm = viewModel {
            return vm
        } else {
            if let container = viewModelContainer {
                return container.dashboardViewModel
            } else {
                let dataService = DataService(modelContext: modelContext)
                let newViewModel = DashboardViewModel(dataService: dataService)
                viewModel = newViewModel
                return newViewModel
            }
        }
    }
    
    var body: some View {
        ZStack {
            if currentViewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.systemBackground)
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Critical Alerts
                        if !currentViewModel.alerts.isEmpty {
                            DashboardAlertsView(alerts: currentViewModel.alerts) { alert in
                                currentViewModel.dismissAlert(alert)
                            }
                        }
                        
                        // Time Filter Tabs
                        DashboardTimeFilterView(selectedFilter: $selectedTimeFilter) {
                            currentViewModel.updateTimeFilter(selectedTimeFilter)
                        }
                        
                        // Quick Stats
                        DashboardStatsView(
                            totalJobs: currentViewModel.totalJobs,
                            activeJobs: currentViewModel.activeJobs,
                            totalCustomers: currentViewModel.totalCustomers,
                            lowStockItems: currentViewModel.lowStockItemsCount
                        )
                        
                        // Recent Activity
                        DashboardRecentActivityView(
                            recentJobs: currentViewModel.recentJobs,
                            upcomingInstallations: currentViewModel.upcomingInstallations
                        )
                        
                        // Revenue Overview
                        DashboardRevenueView(
                            totalRevenue: currentViewModel.totalRevenue,
                            pendingRevenue: currentViewModel.pendingRevenue,
                            completionRate: currentViewModel.getJobsCompletionRate(),
                            averageJobValue: currentViewModel.getAverageJobValue()
                        )
                        
                        // Equipment Alerts
                        DashboardEquipmentAlertsView(
                            lowStockEquipment: currentViewModel.lowStockEquipment
                        ) { equipment in
                            currentViewModel.reorderEquipment(equipment)
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Solar Scheduler")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 8) {
                    if realTimeService.isConnected {
                        LiveDataIndicator()
                    } else {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("OFFLINE")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: {
                        // Handle notifications
                    }) {
                        ZStack {
                            Image(systemName: notificationService.unreadCount > 0 ? "bell.fill" : "bell")
                                .foregroundColor(notificationService.unreadCount > 0 ? .orange : .primary)
                            
                            if notificationService.unreadCount > 0 {
                                Text("\(notificationService.unreadCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: notificationService.unreadCount)
                }
            }
            
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 12) {
                    Button(action: {
                        currentViewModel.refreshData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
            }
        }
        .refreshable {
            currentViewModel.refreshData()
        }
        .onAppear {
            // Load dashboard data when view appears
            currentViewModel.refreshData()
        }
        .alert("Error", isPresented: .constant(currentViewModel.errorMessage != nil)) {
            Button("OK") {
                currentViewModel.errorMessage = nil
            }
        } message: {
            Text(currentViewModel.errorMessage ?? "")
        }
    }
}

struct DashboardStatsView: View {
    let totalJobs: Int
    let activeJobs: Int
    let totalCustomers: Int
    let lowStockItems: Int
    @State private var showingJobs = false
    @State private var showingCustomers = false
    @State private var showingInventory = false
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            DashboardStatCard(
                title: "Total Jobs",
                value: "\(totalJobs)",
                icon: "list.bullet.clipboard",
                color: .blue
            ) {
                showingJobs = true
            }
            
            DashboardStatCard(
                title: "Active Jobs",
                value: "\(activeJobs)",
                icon: "hammer",
                color: .orange
            ) {
                showingJobs = true
            }
            
            DashboardStatCard(
                title: "Customers",
                value: "\(totalCustomers)",
                icon: "person.2",
                color: .green
            ) {
                showingCustomers = true
            }
            
            DashboardStatCard(
                title: "Low Stock",
                value: "\(lowStockItems)",
                icon: "exclamationmark.triangle",
                color: lowStockItems > 0 ? .red : .gray
            ) {
                showingInventory = true
            }
        }
        .sheet(isPresented: $showingJobs) {
            NavigationStack {
                JobsListView()
            }
        }
        .sheet(isPresented: $showingCustomers) {
            NavigationStack {
                CustomersListView()
            }
        }
        .sheet(isPresented: $showingInventory) {
            NavigationStack {
                InventoryListView()
            }
        }
    }
}


struct DashboardStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let action: (() -> Void)?
    
    init(title: String, value: String, icon: String, color: Color, action: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                    Spacer()
                    
                    if action != nil {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color.secondarySystemBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
}

struct DashboardRecentActivityView: View {
    let recentJobs: [SolarJob]
    let upcomingInstallations: [Installation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(recentJobs.prefix(3), id: \.id) { job in
                    HStack {
                        Image(systemName: "list.bullet.clipboard")
                            .foregroundColor(Color.blue)
                        
                        VStack(alignment: .leading) {
                            Text(job.customerName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(job.status.rawValue) • \(job.createdDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("$\(job.estimatedRevenue.safeValue, specifier: "%.0f")")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal)
                }
                
                if !upcomingInstallations.isEmpty {
                    Divider()
                        .padding(.horizontal)
                    
                    ForEach(upcomingInstallations, id: \.id) { installation in
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading) {
                                Text("Installation Scheduled")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(installation.scheduledDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(installation.status.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(installation.status.color).opacity(0.2))
                                .cornerRadius(4)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical)
        .background(Color.secondarySystemBackground)
        .cornerRadius(12)
    }
}

struct DashboardRevenueView: View {
    let totalRevenue: Double
    let pendingRevenue: Double
    let completionRate: Double
    let averageJobValue: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Revenue Overview")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(totalRevenue.safeValue, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading) {
                    Text("Pipeline")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(pendingRevenue.safeValue, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.blue)
                }
                
                VStack(alignment: .leading) {
                    Text("Completion Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\((completionRate * 100).safeValue, specifier: "%.1f")%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading) {
                    Text("Avg Job Value")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(averageJobValue.safeValue, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.secondarySystemBackground)
        .cornerRadius(12)
    }
}

struct DashboardEquipmentAlertsView: View {
    let lowStockEquipment: [Equipment]
    let onReorder: (Equipment) -> Void
    
    var body: some View {
        if !lowStockEquipment.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text("Low Stock Alerts")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                
                VStack(spacing: 8) {
                    ForEach(lowStockEquipment.prefix(3), id: \.id) { equipment in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(equipment.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("\(equipment.quantity) remaining")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            
                            Spacer()
                            
                            Button("Reorder") {
                                onReorder(equipment)
                            }
                            .font(.caption)
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Dashboard Alerts View

struct DashboardAlertsView: View {
    let alerts: [DashboardAlert]
    let onDismiss: (DashboardAlert) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(alerts) { alert in
                HStack {
                    Image(systemName: alert.priority.icon)
                        .foregroundColor(alert.priority.color)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(alert.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(alert.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { onDismiss(alert) }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(alert.priority.color.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Time Filter Components

struct DashboardTimeFilterView: View {
    @Binding var selectedFilter: TimeFilter
    let onFilterChange: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimeFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                        onFilterChange()
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    let container = try! ModelContainer(for: SolarJob.self, Customer.self, Equipment.self, Installation.self, Vendor.self, Contract.self)
    
    return DashboardView()
        .modelContainer(container)
}

// MARK: - Navigation Menu View

struct NavigationMenuView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Pages") {
                    NavigationLink(destination: DashboardView()) {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                    }
                    
                    NavigationLink(destination: InstallationCalendarView()) {
                        Label("Calendar", systemImage: "calendar")
                    }
                    
                    NavigationLink(destination: JobsListView()) {
                        Label("Jobs", systemImage: "list.bullet.clipboard")
                    }
                    
                    NavigationLink(destination: CustomersListView()) {
                        Label("Customers", systemImage: "person.2.fill")
                    }
                    
                    NavigationLink(destination: InventoryListView()) {
                        Label("Equipment", systemImage: "wrench.and.screwdriver")
                    }
                    
                    NavigationLink(destination: Text("Vendors - Coming Soon")) {
                        Label("Vendors", systemImage: "building.2")
                    }
                    
                    NavigationLink(destination: Text("Settings - Coming Soon")) {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .navigationTitle("Navigation")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}