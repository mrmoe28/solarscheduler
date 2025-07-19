import SwiftUI
import SwiftData

// MARK: - Root View
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var navigationRouter = NavigationRouter()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                AppNavigationView()
                    .environmentObject(navigationRouter)
                    .environmentObject(themeManager)
            } else {
                WelcomeView()
            }
        }
        .environmentObject(themeManager)
        .environment(\.viewModelContainer, ViewModelContainer(modelContext: modelContext))
        .preferredColorScheme(themeManager.selectedTheme.colorScheme)
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.1),
                        Color.blue.opacity(0.05),
                        Color.green.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Skip button
                    HStack {
                        Spacer()
                        Button("Skip") {
                            hasCompletedOnboarding = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                    }
                    
                    // Content
                    TabView(selection: $currentPage) {
                        WelcomePageView(
                            title: "Welcome to Solar Scheduler",
                            subtitle: "Streamline your solar business operations with our comprehensive management platform",
                            imageName: "sun.max.fill",
                            backgroundColor: .orange,
                            features: [
                                "Manage installations and projects",
                                "Track customer relationships",
                                "Schedule site visits and work"
                            ]
                        )
                        .tag(0)
                        
                        WelcomePageView(
                            title: "Powerful Dashboard",
                            subtitle: "Get real-time insights into your business performance and project pipeline",
                            imageName: "chart.bar.xaxis",
                            backgroundColor: .blue,
                            features: [
                                "Track revenue and goals",
                                "Monitor installation progress",
                                "View recent activity feed"
                            ]
                        )
                        .tag(1)
                        
                        WelcomePageView(
                            title: "Smart Scheduling",
                            subtitle: "Efficiently manage your installation calendar and crew assignments",
                            imageName: "calendar.badge.plus",
                            backgroundColor: .green,
                            features: [
                                "Calendar-based scheduling",
                                "Crew assignment tracking",
                                "Automatic notifications"
                            ]
                        )
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: geometry.size.height * 0.8)
                    
                    // Page indicator and buttons
                    VStack(spacing: 20) {
                        HStack(spacing: 8) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(currentPage == index ? Color.primary : Color.secondary.opacity(0.5))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        HStack(spacing: 16) {
                            if currentPage > 0 {
                                Button("Previous") {
                                    withAnimation {
                                        currentPage -= 1
                                    }
                                }
                                .font(.headline)
                                .foregroundColor(.secondary)
                            } else {
                                Spacer()
                            }
                            
                            Spacer()
                            
                            if currentPage < 2 {
                                Button("Next") {
                                    withAnimation {
                                        currentPage += 1
                                    }
                                }
                                .font(.headline)
                                .foregroundColor(.accentColor)
                            } else {
                                Button("Get Started") {
                                    hasCompletedOnboarding = true
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.accentColor)
                                .cornerRadius(25)
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                    .frame(height: geometry.size.height * 0.2)
                }
            }
        }
    }
}

struct WelcomePageView: View {
    let title: String
    let subtitle: String
    let imageName: String
    let backgroundColor: Color
    let features: [String]
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Image(systemName: imageName)
                    .font(.system(size: 80))
                    .foregroundColor(backgroundColor)
                
                VStack(spacing: 12) {
                    Text(title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
            }
            
            VStack(spacing: 16) {
                ForEach(features, id: \.self) { feature in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(backgroundColor)
                            .font(.title3)
                        
                        Text(feature)
                            .font(.body)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Navigation Router

class NavigationRouter: ObservableObject {
    @Published var currentPage: AppPage = .dashboard
}

enum AppPage: String, CaseIterable {
    case dashboard = "Dashboard"
    case contacts = "Contacts"
    case contracts = "Contracts"
    case jobs = "Jobs"
    case inventory = "Inventory"
    case settings = "Settings"
    
    var systemImage: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .contacts: return "person.2.fill"
        case .contracts: return "doc.text.fill"
        case .jobs: return "list.bullet.clipboard"
        case .inventory: return "cube.box.fill"
        case .settings: return "gear"
        }
    }
}

// MARK: - App Navigation View

struct AppNavigationView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        TabView {
            // Dashboard Tab
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("Dashboard")
            }
            
            // Jobs Tab
            NavigationStack {
                JobsListView()
            }
            .tabItem {
                Image(systemName: "list.bullet.clipboard")
                Text("Jobs")
            }
            
            // Customers Tab
            NavigationStack {
                CustomersListView()
            }
            .tabItem {
                Image(systemName: "person.2.fill")
                Text("Customers")
            }
            
            // Calendar Tab
            NavigationStack {
                InstallationCalendarView()
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Calendar")
            }
            
            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
        }
        .accentColor(.orange)
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Dashboard Content View (without NavigationView wrapper)

struct DashboardContentView: View {
    @Environment(\.viewModelContainer) private var viewModelContainer
    @State private var selectedTimeFilter: TimeFilter = .today
    
    private var viewModel: DashboardViewModel {
        viewModelContainer?.dashboardViewModel ?? DashboardViewModel(
            dataService: DataService(modelContext: ModelContext(for: Schema([
                SolarJob.self, Customer.self, Equipment.self, Installation.self, Vendor.self, Contract.self
            ])))
        )
    }
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.orange)
                    
                    Text("Loading Dashboard...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
                .transition(.opacity.combined(with: .scale))
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
        .refreshable {
            viewModel.refreshData()
        }
        .onAppear {
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
}


// MARK: - Theme Toggle Button

struct ThemeToggleButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                cycleTheme()
            }
        }) {
            Image(systemName: currentThemeIcon)
                .font(.title2)
                .foregroundColor(.primary)
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .rotationEffect(.degrees(isPressed ? 10 : 0))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: themeManager.selectedTheme)
        .accessibilityLabel("Toggle theme")
        .accessibilityHint("Cycles between light, dark, and system themes")
    }
    
    private var currentThemeIcon: String {
        switch themeManager.selectedTheme {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
    
    private func cycleTheme() {
        switch themeManager.selectedTheme {
        case .system:
            themeManager.selectedTheme = .light
        case .light:
            themeManager.selectedTheme = .dark
        case .dark:
            themeManager.selectedTheme = .system
        }
    }
}

#Preview {
    RootView()
}