import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.viewModelContainer) private var viewModelContainer
    @State private var selectedTimeFilter: TimeFilter = .today
    @State private var showingNavigationMenu = false
    @StateObject private var realTimeService = RealTimeDataService()
    @StateObject private var performanceService = PerformanceMetricsService()
    @StateObject private var notificationService = EnhancedNotificationService()
    
    private var viewModel: DashboardViewModel {
        viewModelContainer?.dashboardViewModel ?? DashboardViewModel(
            dataService: DataService(modelContext: ModelContext(for: Schema([
                SolarJob.self, Customer.self, Equipment.self, Installation.self, Vendor.self, Contract.self
            ])))
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(UIColor.systemBackground))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Critical Alerts
                            if !viewModel.alerts.isEmpty {
                                DashboardAlertsView(alerts: viewModel.alerts) { alert in
                                    viewModel.dismissAlert(alert)
                                }
                            }
                            
                            // Time Filter Tabs
                            DashboardTimeFilterView(selectedFilter: $selectedTimeFilter) {
                                viewModel.updateTimeFilter(selectedTimeFilter)
                            }
                            
                            // Quick Stats
                            DashboardStatsView(
                                totalJobs: viewModel.totalJobs,
                                activeJobs: viewModel.activeJobs,
                                totalCustomers: viewModel.totalCustomers,
                                lowStockItems: viewModel.lowStockItemsCount
                            )
                            
                            // Recent Activity
                            DashboardRecentActivityView(
                                recentJobs: viewModel.recentJobs,
                                upcomingInstallations: viewModel.upcomingInstallations
                            )
                            
                            // Revenue Overview
                            DashboardRevenueView(
                                totalRevenue: viewModel.totalRevenue,
                                pendingRevenue: viewModel.pendingRevenue,
                                completionRate: viewModel.getJobsCompletionRate(),
                                averageJobValue: viewModel.getAverageJobValue()
                            )
                            
                            // Equipment Alerts
                            DashboardEquipmentAlertsView(
                                lowStockEquipment: viewModel.lowStockEquipment
                            ) { equipment in
                                viewModel.reorderEquipment(equipment)
                            }
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Solar Scheduler")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
                        
                        if notificationService.unreadCount > 0 {
                            Button(action: {
                                // Handle notifications
                            }) {
                                ZStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.orange)
                                    
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
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                realTimeService.forceRefresh()
                                performanceService.updatePerformanceData()
                            }
                        }) {
                            DataUpdateIndicator()
                        }
                        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.3), trigger: realTimeService.lastUpdateTime)
                        
                        Button(action: {
                            showingNavigationMenu.toggle()
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                }
            }
            .refreshable {
                viewModel.refreshData()
            }
            .onAppear {
                // Load dashboard data when view appears
                viewModel.refreshData()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showingNavigationMenu) {
            NavigationMenuView()
        }
    }
}

struct DashboardStatsView: View {
    let totalJobs: Int
    let activeJobs: Int
    let totalCustomers: Int
    let lowStockItems: Int
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            DashboardStatCard(
                title: "Total Jobs",
                value: "\(totalJobs)",
                icon: "list.bullet.clipboard",
                color: .blue
            )
            
            DashboardStatCard(
                title: "Active Jobs",
                value: "\(activeJobs)",
                icon: "hammer",
                color: .orange
            )
            
            DashboardStatCard(
                title: "Customers",
                value: "\(totalCustomers)",
                icon: "person.2",
                color: .green
            )
            
            DashboardStatCard(
                title: "Low Stock",
                value: "\(lowStockItems)",
                icon: "exclamationmark.triangle",
                color: lowStockItems > 0 ? .red : .gray
            )
        }
    }
}

struct DashboardStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
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
                            .foregroundColor(.blue)
                        
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
        .background(Color(UIColor.secondarySystemBackground))
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
                        .foregroundColor(.blue)
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
        .background(Color(UIColor.secondarySystemBackground))
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
    let dataService = DataService(modelContext: container.mainContext)
    let viewModel = DashboardViewModel(dataService: dataService)
    
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
                    
                    NavigationLink(destination: EquipmentListView()) {
                        Label("Equipment", systemImage: "wrench.and.screwdriver")
                    }
                    
                    NavigationLink(destination: VendorsListView()) {
                        Label("Vendors", systemImage: "building.2")
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .navigationTitle("Navigation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}