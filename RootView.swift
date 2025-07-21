import SwiftUI
import SwiftData
import CryptoKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Animated Splash View
struct AnimatedSplashView: View {
    @State private var isAnimating = false
    @State private var showLogo = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showRays = false
    @State private var sunRotation = 0.0
    @State private var rayOpacity = 0.0
    @State private var particlesVisible = false
    
    // Colors
    let sunGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.8, blue: 0.2),
            Color(red: 1.0, green: 0.6, blue: 0.1),
            Color(red: 1.0, green: 0.4, blue: 0.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.1, green: 0.1, blue: 0.2),
            Color(red: 0.2, green: 0.1, blue: 0.3),
            Color(red: 0.3, green: 0.2, blue: 0.4)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
                .ignoresSafeArea()
                .overlay(
                    // Animated particles
                    GeometryReader { geometry in
                        ForEach(0..<20, id: \.self) { index in
                            Circle()
                                .fill(Color.yellow.opacity(0.3))
                                .frame(width: CGFloat.random(in: 2...6))
                                .position(
                                    x: CGFloat.random(in: 0...geometry.size.width),
                                    y: CGFloat.random(in: 0...geometry.size.height)
                                )
                                .opacity(particlesVisible ? 1 : 0)
                                .animation(
                                    Animation.easeIn(duration: 2)
                                        .delay(Double(index) * 0.1)
                                        .repeatForever(autoreverses: true),
                                    value: particlesVisible
                                )
                        }
                    }
                )
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated Sun Logo
                ZStack {
                    // Sun rays
                    ForEach(0..<12, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(sunGradient)
                            .frame(width: 4, height: 20)
                            .offset(y: -70)
                            .rotationEffect(.degrees(Double(index) * 30))
                            .scaleEffect(showRays ? 1 : 0.3)
                            .opacity(showRays ? rayOpacity : 0)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.05),
                                value: showRays
                            )
                    }
                    
                    // Main sun circle
                    Circle()
                        .fill(sunGradient)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.8), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: .orange.opacity(0.6), radius: 20, x: 0, y: 0)
                        .scaleEffect(showLogo ? 1 : 0)
                        .rotationEffect(.degrees(sunRotation))
                }
                .frame(height: 150)
                
                // Title and Subtitle
                VStack(spacing: 16) {
                    Text("Solar Scheduler")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 0.9, green: 0.9, blue: 1.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .scaleEffect(showTitle ? 1 : 0.8)
                        .opacity(showTitle ? 1 : 0)
                    
                    Text("Powering Your Solar Business")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .scaleEffect(showSubtitle ? 1 : 0.8)
                        .opacity(showSubtitle ? 1 : 0)
                }
                
                Spacer()
                
                // Loading indicator
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 10, height: 10)
                            .scaleEffect(isAnimating ? 1.2 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Logo animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            showLogo = true
        }
        
        // Sun rotation
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            sunRotation = 360
        }
        
        // Rays animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showRays = true
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                rayOpacity = 1
            }
        }
        
        // Title animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showTitle = true
            }
        }
        
        // Subtitle animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showSubtitle = true
            }
        }
        
        // Loading dots
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isAnimating = true
        }
        
        // Particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            particlesVisible = true
        }
    }
}

// MARK: - String Extensions for Validation
extension String {
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    var isValidPassword: Bool {
        // At least 6 characters
        return self.count >= 6
    }
}

// MARK: - Theme Management (copied from AppTheme.swift to resolve import issues)
enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") var selectedTheme: AppTheme = .system
}

// MARK: - Navigation Router
class NavigationRouter: ObservableObject {
    @Published var currentTab: Int = 0
    @Published var navigationPath = NavigationPath()
    
    func navigate(to tab: Int) {
        currentTab = tab
    }
}

// MARK: - Root View
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var userSession = UserSession.shared
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var navigationRouter = NavigationRouter()
    @Environment(\.modelContext) private var modelContext
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                AnimatedSplashView()
                    .transition(.opacity)
            } else {
                Group {
                    if !hasCompletedOnboarding {
                        WelcomeView()
                    } else if userSession.isSignedIn {
                        AppNavigationView()
                            .environmentObject(navigationRouter)
                            .environmentObject(themeManager)
                    } else {
                        SignInView()
                    }
                }
                .environmentObject(themeManager)
                .environment(\.viewModelContainer, ViewModelContainer(modelContext: modelContext))
                .preferredColorScheme(themeManager.selectedTheme.colorScheme)
                .onAppear {
                    // Configure UserSession with ModelContext
                    userSession.configure(with: modelContext)
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            // Hide splash after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
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
                    #if os(iOS)
                    .tabViewStyle(PageTabViewStyle())
                    #else
                    .tabViewStyle(DefaultTabViewStyle())
                    #endif
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

enum AppPage: String, CaseIterable {
    case dashboard = "Dashboard"
    case contacts = "Contacts"
    case contracts = "Contracts"
    case jobs = "Jobs"
    case inventory = "Inventory"
    case contractors = "Contractors"
    case settings = "Settings"
    
    var systemImage: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .contacts: return "person.2.fill"
        case .contracts: return "doc.text.fill"
        case .jobs: return "list.bullet.clipboard"
        case .inventory: return "cube.box.fill"
        case .contractors: return "building.2"
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
            
            // Contracts Tab
            NavigationStack {
                ContractsListView()
            }
            .tabItem {
                Image(systemName: "doc.text.fill")
                Text("Contracts")
            }
            
            // Calendar Tab
            NavigationStack {
                InstallationCalendarView()
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Calendar")
            }
            
            // Inventory Tab
            NavigationStack {
                InventoryListView()
            }
            .tabItem {
                Image(systemName: "cube.box.fill")
                Text("Inventory")
            }
            
            // Contractors Tab
            NavigationStack {
                ContractorsListView()
            }
            .tabItem {
                Image(systemName: "building.2")
                Text("Contractors")
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
        #if os(iOS)
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        #elseif os(macOS)
        .frame(minWidth: 1000, minHeight: 700)
        #endif
    }
}

// MARK: - Dashboard Content View (without NavigationView wrapper)

struct DashboardContentView: View {
    @Environment(\.viewModelContainer) private var viewModelContainer
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTimeFilter: TimeFilter = .today
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
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.orange)
                    
                    Text("Loading Dashboard...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                #if os(iOS)
                .background(Color(UIColor.systemBackground))
                #elseif os(macOS)
                .background(Color(NSColor.windowBackgroundColor))
                #endif
                .transition(.opacity.combined(with: .scale))
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
        #if os(iOS)
        .refreshable {
            currentViewModel.refreshData()
        }
        #endif
        .onAppear {
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
        #if os(iOS)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: themeManager.selectedTheme)
        #endif
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

// MARK: - Temporary View Definitions
// These views are defined here temporarily until their files are added to the Xcode project
// The actual implementations exist in:
// - /Views/Authentication/SignInView.swift
// - /Views/Settings/SettingsView.swift
// - /Views/Vendors/VendorsListView.swift

struct SignInView: View {
    @State private var userSession = UserSession.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingSignUp = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Color.orange.opacity(0.1), Color.blue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Logo and Title
                    VStack(spacing: 20) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                            .shadow(radius: 10)
                        
                        VStack(spacing: 8) {
                            Text("Solar Scheduler")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Manage your solar business efficiently")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Login Form
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                #if os(iOS)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                #endif
                                .autocorrectionDisabled()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Button(action: signIn) {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.orange)
                                .cornerRadius(10)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        
                        HStack {
                            Text("Don't have an account?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Button("Sign Up") {
                                showingSignUp = true
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.orange)
                }
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func signIn() {
        isLoading = true
        
        Task {
            do {
                try await userSession.signIn(email: email, password: password)
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// The InventoryListView, EquipmentRowView, and AddEquipmentView are now in their own file

// MARK: - Contractors List View (temporary until added to Xcode project)

struct ContractorsListView: View {
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
            if filteredVendors.isEmpty {
                ContentUnavailableView {
                    Label("No Contractors", systemImage: "building.2")
                } description: {
                    Text(searchText.isEmpty ? "Add contractors to track your suppliers and service providers." : "No contractors match your search.")
                } actions: {
                    if searchText.isEmpty {
                        Button("Add Contractor") {
                            showingAddVendor = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                ForEach(filteredVendors, id: \.id) { vendor in
                    VendorRowView(vendor: vendor)
                }
                .onDelete(perform: deleteVendors)
            }
        }
        .searchable(text: $searchText, prompt: "Search contractors...")
        .navigationTitle("Contractors")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showingAddVendor = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddVendor) {
            AddVendorView()
        }
    }
    
    private func deleteVendors(at offsets: IndexSet) {
        for index in offsets {
            let vendor = filteredVendors[index]
            vendor.isActive = false
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete vendor: \(error)")
        }
    }
}

struct VendorRowView: View {
    let vendor: Vendor
    @State private var showingDetail = false
    @State private var showingDeleteAlert = false
    @State private var showShareSheet = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack(spacing: 12) {
            // Main content - clickable
            Button(action: { showingDetail = true }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vendor.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !vendor.contactEmail.isEmpty {
                        Label(vendor.contactEmail, systemImage: "envelope")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !vendor.specialties.isEmpty {
                        Text(vendor.specialties.map { $0.rawValue }.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Action buttons
            HStack(spacing: 16) {
                // View button
                Button(action: { showingDetail = true }) {
                    Image(systemName: "eye")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
                
                // Share button
                Button(action: { showShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                }
                
                // Delete button
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color.secondaryBackground)
        .cornerRadius(8)
        .sheet(isPresented: $showingDetail) {
            NavigationStack {
                VendorDetailView(vendor: vendor)
            }
        }
        .alert("Delete Contractor", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                vendor.isActive = false
                try? modelContext.save()
            }
        } message: {
            Text("Are you sure you want to delete this contractor?")
        }
        #if os(iOS)
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(items: [vendor.shareText])
        }
        #endif
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
                        #if os(iOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        #endif
                }
                
                Section("Contact Information") {
                    TextField("Email", text: $contactEmail)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        #endif
                    TextField("Phone", text: $contactPhone)
                        #if os(iOS)
                        .keyboardType(.phonePad)
                        #endif
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
                                    .foregroundColor(.accentColor)
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
            .navigationTitle("New Contractor")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button("Save") {
                        saveVendor()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || contactEmail.isEmpty)
                }
            }
        }
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

struct SettingsView: View {
    @State private var userSession = UserSession.shared
    @State private var showingSignOut = false
    @State private var showingProfileSettings = false
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            List {
                Section("Profile") {
                    if let user = userSession.currentUser {
                        Button(action: { showingProfileSettings = true }) {
                            HStack {
                                // Profile image
                                if let profileImageData = user.profileImageData,
                                   let uiImage = UIImage(data: profileImageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.fullName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(user.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Section("Appearance") {
                    HStack {
                        Label("Theme", systemImage: currentThemeIcon)
                        
                        Spacer()
                        
                        Picker("Theme", selection: $themeManager.selectedTheme) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                }
                
                Section("Account") {
                    Button("Sign Out") {
                        showingSignOut = true
                    }
                    .foregroundColor(.red)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showingSignOut) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await userSession.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showingProfileSettings) {
                ProfileSettingsView()
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #elseif os(macOS)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .automatic)
        #endif
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
}

// MARK: - Sign Up View (temporary until added to Xcode project)

struct SignUpView: View {
    @State private var userSession = UserSession.shared
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var companyName = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.orange.opacity(0.05), Color.blue.opacity(0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Create Account")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Join Solar Scheduler to manage your business")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        
                        // Form
                        VStack(spacing: 20) {
                            // Personal Information
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Personal Information")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Full Name")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("Enter your full name", text: $fullName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        #if os(iOS)
                                        .textInputAutocapitalization(.words)
                                        #endif
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("Enter your email", text: $email)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        #if os(iOS)
                                        .textInputAutocapitalization(.never)
                                        .keyboardType(.emailAddress)
                                        #endif
                                        .autocorrectionDisabled()
                                }
                            }
                            
                            // Password
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Security")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Password")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    SecureField("Enter your password", text: $password)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    Text("At least 6 characters")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirm Password")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    SecureField("Confirm your password", text: $confirmPassword)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                            
                            // Company Information (Optional)
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Company Information (Optional)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Company Name")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("Enter your company name", text: $companyName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        #if os(iOS)
                                        .textInputAutocapitalization(.words)
                                        #endif
                                }
                            }
                            
                            // Sign Up Button
                            Button(action: signUp) {
                                Text("Create Account")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.orange)
                                    .cornerRadius(10)
                            }
                            .disabled(isLoading || !isFormValid)
                            .padding(.top, 8)
                            
                            // Terms
                            Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                }
                
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.orange)
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty &&
        !email.isEmpty &&
        email.isValidEmail &&
        !password.isEmpty &&
        password.isValidPassword &&
        password == confirmPassword
    }
    
    private func signUp() {
        // Additional validation
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            showingError = true
            return
        }
        
        guard email.isValidEmail else {
            errorMessage = "Please enter a valid email address"
            showingError = true
            return
        }
        
        guard password.isValidPassword else {
            errorMessage = "Password must be at least 6 characters"
            showingError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await userSession.signUp(
                    email: email,
                    password: password,
                    fullName: fullName,
                    companyName: companyName
                )
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}
// MARK: - Vendor Detail View
struct VendorDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var vendor: Vendor
    @State private var showingEditVendor = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(vendor.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(vendor.contactEmail)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Rating
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(vendor.rating) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    VStack(spacing: 12) {
                        InfoRow(icon: "phone", label: "Phone", value: vendor.contactPhone)
                        InfoRow(icon: "location", label: "Address", value: vendor.address)
                        InfoRow(icon: "doc.text", label: "License", value: vendor.licenseNumber.isEmpty ? "N/A" : vendor.licenseNumber)
                        InfoRow(icon: "link", label: "Website", value: vendor.website.isEmpty ? "N/A" : vendor.website)
                    }
                }
                .padding(20)
                .background(Color.secondaryBackground)
                .cornerRadius(12)
                
                // Specialties
                VStack(alignment: .leading, spacing: 12) {
                    Text("Specialties")
                        .font(.headline)
                    
                    if vendor.specialties.isEmpty {
                        Text("No specialties listed")
                            .foregroundColor(.secondary)
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(Color.secondaryBackground)
                            .cornerRadius(12)
                    } else {
                        ForEach(vendor.specialties, id: \.self) { specialty in
                            HStack(spacing: 4) {
                                Image(systemName: specialty.icon)
                                    .font(.caption)
                                Text(specialty.rawValue)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(16)
                        }
                    }
                }
                
                // Additional Information
                VStack(alignment: .leading, spacing: 12) {
                    Text("Additional Information")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        InfoRow(icon: "phone.circle", label: "Emergency Contact", value: vendor.emergencyContact.isEmpty ? "N/A" : vendor.emergencyContact)
                        InfoRow(icon: "shield", label: "Insurance", value: vendor.insuranceDetails.isEmpty ? "N/A" : vendor.insuranceDetails)
                        InfoRow(icon: "checkmark.circle", label: "Completed Jobs", value: "\(vendor.completedInstallations)")
                    }
                    .padding(16)
                    .background(Color.secondaryBackground)
                    .cornerRadius(12)
                }
                
                // Notes
                if \!vendor.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.headline)
                        
                        Text(vendor.notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(16)
                            .background(Color.secondaryBackground)
                            .cornerRadius(12)
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(20)
        }
        .navigationTitle("Contractor Details")
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

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}
EOF < /dev/null