import SwiftUI
import SwiftData

// MARK: - Root View
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        if hasCompletedOnboarding {
            ContentView()
        } else {
            WelcomeView()
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
                            subtitle: "Efficiently manage installations, site visits, and team schedules in one place",
                            imageName: "calendar.badge.plus",
                            backgroundColor: .green,
                            features: [
                                "Interactive calendar view",
                                "Color-coded job status",
                                "Easy installation scheduling"
                            ]
                        )
                        .tag(2)
                        
                        WelcomePageView(
                            title: "Customer CRM",
                            subtitle: "Track leads, prospects, and customers throughout your entire sales pipeline",
                            imageName: "person.2.fill",
                            backgroundColor: .purple,
                            features: [
                                "Lead management system",
                                "Project value tracking",
                                "Communication history"
                            ]
                        )
                        .tag(3)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Page indicators and controls
                    VStack(spacing: 24) {
                        // Page indicators
                        HStack(spacing: 8) {
                            ForEach(0..<4, id: \.self) { index in
                                Circle()
                                    .fill(currentPage == index ? Color.orange : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                            }
                        }
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            if currentPage < 3 {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        currentPage += 1
                                    }
                                } label: {
                                    Text("Continue")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.orange)
                                        )
                                }
                                .padding(.horizontal, 20)
                                
                                if currentPage > 0 {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            currentPage -= 1
                                        }
                                    } label: {
                                        Text("Back")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            } else {
                                // Final page - Get Started button
                                Button {
                                    withAnimation(.easeInOut(duration: 0.8)) {
                                        hasCompletedOnboarding = true
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("Get Started")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                                }
                                .padding(.horizontal, 20)
                                .scaleEffect(1.02)
                                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Welcome Page View
struct WelcomePageView: View {
    let title: String
    let subtitle: String
    let imageName: String
    let backgroundColor: Color
    let features: [String]
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Main illustration
            VStack(spacing: 24) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(backgroundColor.opacity(0.1))
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .fill(backgroundColor.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    // Icon
                    Image(systemName: imageName)
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(backgroundColor)
                }
                .scaleEffect(1.1)
            }
            
            // Text content
            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Text(subtitle)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 30)
            }
            
            // Features list
            VStack(spacing: 12) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(backgroundColor)
                        
                        Text(feature)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                }
            }
            
            Spacer()
            Spacer()
        }
    }
}

struct ContentView: View {
    var body: some View {
        DashboardView()
            .ignoresSafeArea(.container, edges: .bottom)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @State private var selectedTimeframe = "This Month"
    let timeframes = ["Today", "This Week", "This Month", "This Year"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Quick Stats Cards
                    statsSection
                    
                    // Progress Indicators
                    progressSection
                    
                    // Recent Activity
                    recentActivitySection
                    
                    // Action Items
                    actionItemsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Solar Scheduler")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good morning!")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Solar Business Overview")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Solar Icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "sun.max.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
            }
            
            // Timeframe Selector
            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(timeframes, id: \.self) { timeframe in
                    Text(timeframe).tag(timeframe)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Total Revenue",
                value: "$127,500",
                change: "+12.5%",
                isPositive: true,
                icon: "dollarsign.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "Active Projects",
                value: "23",
                change: "+3",
                isPositive: true,
                icon: "hammer.circle.fill",
                color: .blue
            )
            
            StatCard(
                title: "Installations",
                value: "8",
                change: "This Month",
                isPositive: nil,
                icon: "house.circle.fill",
                color: .orange
            )
            
            StatCard(
                title: "Energy Generated",
                value: "45.2 MWh",
                change: "+8.3%",
                isPositive: true,
                icon: "bolt.circle.fill",
                color: .yellow
            )
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 16) {
            // Installation Pipeline
            ProgressCard(
                title: "Installation Pipeline",
                subtitle: "Projects in progress",
                items: [
                    ProgressItem(title: "Site Assessment", completed: 12, total: 15, color: .blue),
                    ProgressItem(title: "Permits & Approvals", completed: 8, total: 12, color: .orange),
                    ProgressItem(title: "Installation", completed: 5, total: 8, color: .green),
                    ProgressItem(title: "Inspection", completed: 3, total: 5, color: .purple)
                ]
            )
            
            // Monthly Goals
            GoalsCard(
                title: "Monthly Goals",
                goals: [
                    Goal(title: "New Leads", current: 45, target: 60, color: .cyan),
                    Goal(title: "Installations", current: 8, target: 12, color: .orange),
                    Goal(title: "Revenue", current: 127500, target: 150000, color: .green, isRevenue: true)
                ]
            )
        }
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        ActivityCard(
            title: "Recent Activity",
            activities: [
                Activity(title: "Installation completed", subtitle: "Johnson residence - 8.5kW system", time: "2 hours ago", icon: "checkmark.circle.fill", color: .green),
                Activity(title: "New lead assigned", subtitle: "Sarah Chen - Commercial project", time: "4 hours ago", icon: "person.circle.fill", color: .blue),
                Activity(title: "Permit approved", subtitle: "Smith residence - City approval", time: "1 day ago", icon: "doc.circle.fill", color: .orange),
                Activity(title: "Site assessment scheduled", subtitle: "Miller property - Tomorrow 2PM", time: "2 days ago", icon: "calendar.circle.fill", color: .purple)
            ]
        )
    }
    
    // MARK: - Action Items Section
    private var actionItemsSection: some View {
        ActionItemsCard(
            title: "Action Items",
            items: [
                ActionItem(title: "Follow up with 3 pending quotes", priority: .high, dueDate: "Today"),
                ActionItem(title: "Schedule site visit for Wilson project", priority: .medium, dueDate: "Tomorrow"),
                ActionItem(title: "Review equipment inventory", priority: .low, dueDate: "This week"),
                ActionItem(title: "Prepare monthly report", priority: .medium, dueDate: "Friday")
            ]
        )
    }
}

// MARK: - Supporting Views and Models
struct StatCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                if let isPositive = isPositive {
                    HStack(spacing: 4) {
                        Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text(change)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(isPositive ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isPositive ? Color.green : Color.red).opacity(0.1))
                    .cornerRadius(8)
                } else {
                    Text(change)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ProgressItem {
    let title: String
    let completed: Int
    let total: Int
    let color: Color
    
    var progress: Double {
        Double(completed) / Double(total)
    }
}

struct ProgressCard: View {
    let title: String
    let subtitle: String
    let items: [ProgressItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(Array(items.indices), id: \.self) { index in
                    let item = items[index]
                    VStack(spacing: 8) {
                        HStack {
                            Text(item.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(item.completed)/\(item.total)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: item.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: item.color))
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct Goal {
    let title: String
    let current: Int
    let target: Int
    let color: Color
    let isRevenue: Bool
    
    init(title: String, current: Int, target: Int, color: Color, isRevenue: Bool = false) {
        self.title = title
        self.current = current
        self.target = target
        self.color = color
        self.isRevenue = isRevenue
    }
    
    var progress: Double {
        Double(current) / Double(target)
    }
    
    var displayCurrent: String {
        isRevenue ? "$\(current / 1000)K" : "\(current)"
    }
    
    var displayTarget: String {
        isRevenue ? "$\(target / 1000)K" : "\(target)"
    }
}

struct GoalsCard: View {
    let title: String
    let goals: [Goal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                ForEach(goals.indices, id: \.self) { index in
                    let goal = goals[index]
                    VStack(spacing: 8) {
                        HStack {
                            Text(goal.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(goal.displayCurrent) / \(goal.displayTarget)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(goal.color)
                                .frame(width: CGFloat(goal.progress) * 300, height: 8)
                                .animation(.easeInOut(duration: 0.5), value: goal.progress)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct Activity {
    let title: String
    let subtitle: String
    let time: String
    let icon: String
    let color: Color
}

struct ActivityCard: View {
    let title: String
    let activities: [Activity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(activities.indices, id: \.self) { index in
                    let activity = activities[index]
                    HStack(spacing: 12) {
                        Image(systemName: activity.icon)
                            .font(.title3)
                            .foregroundColor(activity.color)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activity.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(activity.subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Text(activity.time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    if index < activities.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}


struct ActionItem: Identifiable {
    let id = UUID()
    let title: String
    let priority: Priority
    let dueDate: String
}

enum Priority: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

struct ActionItemsCard: View {
    let title: String
    let items: [ActionItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(item.priority.color)
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Due: \(item.dueDate)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(item.priority.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(item.priority.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(item.priority.color.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .padding(.vertical, 4)
                    
                    if index < items.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var currentDate = Date()
    @State private var showingAddInstallation = false
    @State private var selectedViewMode: CalendarViewMode = .month
    
    enum CalendarViewMode: String, CaseIterable {
        case month = "Month"
        case week = "Week"
        case day = "Day"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with view mode selector
                calendarHeader
                
                // Calendar content
                ScrollView {
                    VStack(spacing: 20) {
                        // Calendar grid
                        calendarGrid
                        
                        // Today's installations
                        todaysInstallations
                        
                        // Upcoming installations
                        upcomingInstallations
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Installation Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddInstallation = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showingAddInstallation) {
                AddInstallationSheet()
            }
        }
    }
    
    // MARK: - Calendar Header
    private var calendarHeader: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(currentDate.formatted(.dateTime.month(.wide).year(.defaultDigits)))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
            
            // View mode selector
            Picker("View Mode", selection: $selectedViewMode) {
                ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        VStack(spacing: 12) {
            // Days of week header
            HStack(spacing: 0) {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            
            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(calendarDays, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        isToday: Calendar.current.isDate(date, inSameDayAs: Date()),
                        installations: installationsForDate(date),
                        isCurrentMonth: Calendar.current.isDate(date, equalTo: currentDate, toGranularity: .month)
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Today's Installations
    private var todaysInstallations: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Installations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(todayInstallations.count) scheduled")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if todayInstallations.isEmpty {
                HStack {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("No installations scheduled for today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(todayInstallations, id: \.id) { installation in
                        InstallationCardView(installation: installation)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Upcoming Installations
    private var upcomingInstallations: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming This Week")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(upcomingInstallationsThisWeek, id: \.id) { installation in
                    InstallationCardView(installation: installation, showDate: true)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Computed Properties
    private var calendarDays: [Date] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: currentDate) else {
            return []
        }
        
        let monthFirstWeekday = Calendar.current.component(.weekday, from: monthInterval.start)
        let daysToShow = 42 // 6 weeks
        
        let startDate = Calendar.current.date(byAdding: .day, value: -(monthFirstWeekday - 1), to: monthInterval.start)!
        
        return (0..<daysToShow).compactMap { dayOffset in
            Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate)
        }
    }
    
    private var todayInstallations: [CalendarInstallation] {
        sampleInstallations.filter { installation in
            Calendar.current.isDate(installation.scheduledDate, inSameDayAs: Date())
        }
    }
    
    private var upcomingInstallationsThisWeek: [CalendarInstallation] {
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let endOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.end ?? Date()
        
        return sampleInstallations.filter { installation in
            installation.scheduledDate > Date() &&
            installation.scheduledDate >= startOfWeek &&
            installation.scheduledDate <= endOfWeek &&
            !Calendar.current.isDate(installation.scheduledDate, inSameDayAs: Date())
        }.sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    private func installationsForDate(_ date: Date) -> [CalendarInstallation] {
        sampleInstallations.filter { installation in
            Calendar.current.isDate(installation.scheduledDate, inSameDayAs: date)
        }
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let installations: [CalendarInstallation]
    let isCurrentMonth: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .medium))
                .foregroundColor(textColor)
            
            // Installation indicators
            HStack(spacing: 2) {
                ForEach(installations.prefix(3), id: \.id) { installation in
                    Circle()
                        .fill(installation.status.color)
                        .frame(width: 4, height: 4)
                }
                
                if installations.count > 3 {
                    Text("+\(installations.count - 3)")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 40, height: 44)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
        )
    }
    
    private var textColor: Color {
        if isToday {
            return isSelected ? .white : .orange
        } else if isSelected {
            return .white
        } else if isCurrentMonth {
            return .primary
        } else {
            return .secondary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return isToday ? .orange : .blue
        } else if isToday {
            return .orange.opacity(0.1)
        } else {
            return .clear
        }
    }
    
    private var borderColor: Color {
        isToday ? .orange : .blue
    }
}

// MARK: - Installation Card View
struct InstallationCardView: View {
    let installation: CalendarInstallation
    let showDate: Bool
    
    init(installation: CalendarInstallation, showDate: Bool = false) {
        self.installation = installation
        self.showDate = showDate
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(installation.status.color)
                .frame(width: 4, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(installation.customerName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if showDate {
                        Text(installation.scheduledDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(installation.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Label(installation.systemSize, systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Label(installation.scheduledDate.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Status badge
            Text(installation.status.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(installation.status.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(installation.status.color.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

// MARK: - Add Installation Sheet
struct AddInstallationSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Schedule New Installation")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 20)
                
                Text("Installation scheduling form would go here")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                }
            }
        }
    }
}

// MARK: - Calendar Installation Model
struct CalendarInstallation {
    let id = UUID()
    let customerName: String
    let address: String
    let systemSize: String
    let scheduledDate: Date
    let status: InstallationStatus
    
    enum InstallationStatus: String, CaseIterable {
        case scheduled = "Scheduled"
        case inProgress = "In Progress"
        case completed = "Completed"
        case delayed = "Delayed"
        
        var color: Color {
            switch self {
            case .scheduled: return .blue
            case .inProgress: return .orange
            case .completed: return .green
            case .delayed: return .red
            }
        }
    }
}

// MARK: - Sample Data
private let sampleInstallations: [CalendarInstallation] = [
    CalendarInstallation(
        customerName: "Johnson Residence",
        address: "123 Oak Street, Sunnyville",
        systemSize: "8.5 kW",
        scheduledDate: Date(),
        status: .scheduled
    ),
    CalendarInstallation(
        customerName: "Smith Commercial",
        address: "456 Business Blvd, Commerce City",
        systemSize: "25.0 kW",
        scheduledDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date(),
        status: .inProgress
    ),
    CalendarInstallation(
        customerName: "Wilson Home",
        address: "789 Maple Ave, Green Valley",
        systemSize: "12.3 kW",
        scheduledDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
        status: .scheduled
    ),
    CalendarInstallation(
        customerName: "Davis Property",
        address: "321 Pine Road, Solar Heights",
        systemSize: "6.8 kW",
        scheduledDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
        status: .scheduled
    ),
    CalendarInstallation(
        customerName: "Martinez Office",
        address: "654 Corporate Drive, Business Park",
        systemSize: "18.2 kW",
        scheduledDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
        status: .completed
    )
]

struct JobsListView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Solar Jobs")
                    .font(.largeTitle)
                    .padding()
                Text("Manage your solar installation projects")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Jobs")
        }
    }
}

// MARK: - Customers View
struct CustomersView: View {
    @State private var searchText = ""
    @State private var selectedFilter: CustomerFilter = .all
    @State private var showingAddCustomer = false
    @State private var selectedCustomer: SolarCustomer?
    
    enum CustomerFilter: String, CaseIterable {
        case all = "All"
        case leads = "Leads"
        case prospects = "Prospects"
        case customers = "Customers"
        case completed = "Completed"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter header
                customerHeader
                
                // Customer list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredCustomers, id: \.id) { customer in
                            CustomerCardView(customer: customer)
                                .onTapGesture {
                                    selectedCustomer = customer
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Customers")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCustomer = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showingAddCustomer) {
                AddCustomerSheet()
            }
            .sheet(item: $selectedCustomer) { customer in
                CustomerDetailSheet(customer: customer)
            }
        }
        .searchable(text: $searchText, prompt: "Search customers...")
    }
    
    // MARK: - Customer Header
    private var customerHeader: some View {
        VStack(spacing: 16) {
            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CustomerFilter.allCases, id: \.self) { filter in
                        FilterPill(
                            title: filter.rawValue,
                            count: customerCount(for: filter),
                            isSelected: selectedFilter == filter
                        )
                        .onTapGesture {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Quick stats
            HStack(spacing: 16) {
                CustomerStatView(
                    title: "Total Customers",
                    value: "\(sampleCustomers.count)",
                    icon: "person.2.fill",
                    color: .blue
                )
                
                CustomerStatView(
                    title: "This Month",
                    value: "\(newCustomersThisMonth)",
                    icon: "person.badge.plus",
                    color: .green
                )
                
                CustomerStatView(
                    title: "Pipeline Value",
                    value: "$\(totalPipelineValue)K",
                    icon: "dollarsign.circle",
                    color: .orange
                )
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Computed Properties
    private var filteredCustomers: [SolarCustomer] {
        let filtered = sampleCustomers.filter { customer in
            switch selectedFilter {
            case .all:
                return true
            case .leads:
                return customer.status == .lead
            case .prospects:
                return customer.status == .prospect
            case .customers:
                return customer.status == .customer
            case .completed:
                return customer.status == .completed
            }
        }
        
        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { customer in
                customer.name.localizedCaseInsensitiveContains(searchText) ||
                customer.email.localizedCaseInsensitiveContains(searchText) ||
                customer.address.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func customerCount(for filter: CustomerFilter) -> Int {
        switch filter {
        case .all:
            return sampleCustomers.count
        case .leads:
            return sampleCustomers.filter { $0.status == .lead }.count
        case .prospects:
            return sampleCustomers.filter { $0.status == .prospect }.count
        case .customers:
            return sampleCustomers.filter { $0.status == .customer }.count
        case .completed:
            return sampleCustomers.filter { $0.status == .completed }.count
        }
    }
    
    private var newCustomersThisMonth: Int {
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        return sampleCustomers.filter { $0.createdDate >= startOfMonth }.count
    }
    
    private var totalPipelineValue: Int {
        sampleCustomers.reduce(0) { total, customer in
            total + customer.estimatedValue
        } / 1000
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2))
                )
        }
        .foregroundColor(isSelected ? .white : .primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(isSelected ? Color.orange : Color(.systemGray6))
        )
    }
}

// MARK: - Customer Stat View
struct CustomerStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Customer Card View
struct CustomerCardView: View {
    let customer: SolarCustomer
    
    var body: some View {
        HStack(spacing: 16) {
            // Customer avatar
            ZStack {
                Circle()
                    .fill(customer.status.color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Text(customer.initials)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(customer.status.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(customer.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("$\(customer.estimatedValue / 1000)K")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                Text(customer.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Label(customer.systemSize, systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Text(customer.lastContact.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 8) {
                // Status badge
                Text(customer.status.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(customer.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(customer.status.color.opacity(0.1))
                    .cornerRadius(6)
                
                // Priority indicator
                if customer.priority == .high {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Add Customer Sheet
struct AddCustomerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var systemSize = ""
    @State private var estimatedValue = ""
    @State private var selectedStatus: SolarCustomer.CustomerStatus = .lead
    @State private var selectedPriority: SolarCustomer.Priority = .medium
    @State private var notes = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, phone, address, systemSize, estimatedValue, notes
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !phone.isEmpty && !address.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("Add New Customer")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    // Form sections
                    VStack(spacing: 24) {
                        // Contact Information
                        FormSection(title: "Contact Information", icon: "person.fill") {
                            CustomTextField(
                                title: "Full Name",
                                text: $name,
                                placeholder: "John Doe",
                                icon: "person"
                            )
                            .focused($focusedField, equals: .name)
                            .textContentType(.name)
                            
                            CustomTextField(
                                title: "Email Address",
                                text: $email,
                                placeholder: "john.doe@email.com",
                                icon: "envelope"
                            )
                            .focused($focusedField, equals: .email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            
                            CustomTextField(
                                title: "Phone Number",
                                text: $phone,
                                placeholder: "(555) 123-4567",
                                icon: "phone"
                            )
                            .focused($focusedField, equals: .phone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                        }
                        
                        // Address Information
                        FormSection(title: "Address", icon: "location.fill") {
                            CustomTextField(
                                title: "Full Address",
                                text: $address,
                                placeholder: "123 Main St, City, State, ZIP",
                                icon: "house"
                            )
                            .focused($focusedField, equals: .address)
                            .textContentType(.fullStreetAddress)
                        }
                        
                        // Project Information
                        FormSection(title: "Project Details", icon: "sun.max.fill") {
                            CustomTextField(
                                title: "System Size",
                                text: $systemSize,
                                placeholder: "8.5 kW",
                                icon: "bolt.fill"
                            )
                            .focused($focusedField, equals: .systemSize)
                            
                            CustomTextField(
                                title: "Estimated Value",
                                text: $estimatedValue,
                                placeholder: "25000",
                                icon: "dollarsign.circle"
                            )
                            .focused($focusedField, equals: .estimatedValue)
                            .keyboardType(.numberPad)
                        }
                        
                        // Status and Priority
                        FormSection(title: "Classification", icon: "flag.fill") {
                            VStack(spacing: 16) {
                                // Status Picker
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                        Text("Customer Status")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach([SolarCustomer.CustomerStatus.lead, .prospect, .customer], id: \.self) { status in
                                                StatusPill(
                                                    title: status.rawValue,
                                                    color: status.color,
                                                    isSelected: selectedStatus == status
                                                )
                                                .onTapGesture {
                                                    selectedStatus = status
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 2)
                                    }
                                }
                                
                                // Priority Picker
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                        Text("Priority Level")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach([SolarCustomer.Priority.low, .medium, .high], id: \.self) { priority in
                                                PriorityPill(
                                                    title: priority.rawValue,
                                                    priority: priority,
                                                    isSelected: selectedPriority == priority
                                                )
                                                .onTapGesture {
                                                    selectedPriority = priority
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 2)
                                    }
                                }
                            }
                        }
                        
                        // Notes
                        FormSection(title: "Notes", icon: "note.text") {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    Text("Additional Notes")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                TextEditor(text: $notes)
                                    .frame(minHeight: 80)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .focused($focusedField, equals: .notes)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Customer") {
                        saveCustomer()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? .orange : .secondary)
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func saveCustomer() {
        guard isFormValid else { return }
        
        let newCustomer = Customer(
            name: name,
            email: email,
            phone: phone,
            address: address,
            leadStatus: selectedStatus.rawValue
        )
        
        modelContext.insert(newCustomer)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save customer: \(error)")
        }
    }
}

// MARK: - Form Components
struct FormSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }
}

struct StatusPill: View {
    let title: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? color.opacity(0.15) : Color(.systemGray6))
        .foregroundColor(isSelected ? color : .primary)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color, lineWidth: isSelected ? 1.5 : 0)
        )
    }
}

struct PriorityPill: View {
    let title: String
    let priority: SolarCustomer.Priority
    let isSelected: Bool
    
    private var color: Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
                .foregroundColor(color)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? color.opacity(0.15) : Color(.systemGray6))
        .foregroundColor(isSelected ? color : .primary)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color, lineWidth: isSelected ? 1.5 : 0)
        )
    }
}

// MARK: - Customer Detail Sheet
struct CustomerDetailSheet: View {
    let customer: SolarCustomer
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Customer header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(customer.status.color.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Text(customer.initials)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(customer.status.color)
                        }
                        
                        Text(customer.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(customer.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Customer details would go here
                    Text("Customer details and project information would be displayed here")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                }
            }
        }
    }
}

// MARK: - Solar Customer Model
struct SolarCustomer: Identifiable {
    let id = UUID()
    let name: String
    let email: String
    let phone: String
    let address: String
    let systemSize: String
    let estimatedValue: Int
    let status: CustomerStatus
    let priority: Priority
    let createdDate: Date
    let lastContact: Date
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first?.uppercased() ?? ""
        let lastInitial = components.count > 1 ? components[1].first?.uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }
    
    enum CustomerStatus: String, CaseIterable {
        case lead = "Lead"
        case prospect = "Prospect"
        case customer = "Customer"
        case completed = "Completed"
        
        var color: Color {
            switch self {
            case .lead: return .blue
            case .prospect: return .orange
            case .customer: return .green
            case .completed: return .purple
            }
        }
    }
    
    enum Priority: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .green
            }
        }
    }
}

// MARK: - Sample Customer Data
private let sampleCustomers: [SolarCustomer] = [
    SolarCustomer(
        name: "John & Sarah Johnson",
        email: "john.johnson@email.com",
        phone: "(555) 123-4567",
        address: "123 Oak Street, Sunnyville, CA",
        systemSize: "8.5 kW",
        estimatedValue: 25000,
        status: .customer,
        priority: .medium,
        createdDate: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date(),
        lastContact: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
    ),
    SolarCustomer(
        name: "Michael Chen",
        email: "m.chen@business.com",
        phone: "(555) 234-5678",
        address: "456 Business Blvd, Commerce City, CA",
        systemSize: "25.0 kW",
        estimatedValue: 75000,
        status: .prospect,
        priority: .high,
        createdDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
        lastContact: Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date()
    ),
    SolarCustomer(
        name: "Emily Wilson",
        email: "emily.wilson@gmail.com",
        phone: "(555) 345-6789",
        address: "789 Maple Ave, Green Valley, CA",
        systemSize: "12.3 kW",
        estimatedValue: 35000,
        status: .lead,
        priority: .medium,
        createdDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
        lastContact: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    ),
    SolarCustomer(
        name: "Robert & Lisa Davis",
        email: "davis.family@email.com",
        phone: "(555) 456-7890",
        address: "321 Pine Road, Solar Heights, CA",
        systemSize: "6.8 kW",
        estimatedValue: 20000,
        status: .completed,
        priority: .low,
        createdDate: Calendar.current.date(byAdding: .day, value: -45, to: Date()) ?? Date(),
        lastContact: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    ),
    SolarCustomer(
        name: "Sofia Martinez",
        email: "sofia.martinez@company.com",
        phone: "(555) 567-8901",
        address: "654 Corporate Drive, Business Park, CA",
        systemSize: "18.2 kW",
        estimatedValue: 55000,
        status: .customer,
        priority: .high,
        createdDate: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
        lastContact: Calendar.current.date(byAdding: .hour, value: -12, to: Date()) ?? Date()
    ),
    SolarCustomer(
        name: "David Thompson",
        email: "d.thompson@email.com",
        phone: "(555) 678-9012",
        address: "987 Solar Street, Renewable City, CA",
        systemSize: "10.5 kW",
        estimatedValue: 30000,
        status: .prospect,
        priority: .medium,
        createdDate: Calendar.current.date(byAdding: .day, value: -8, to: Date()) ?? Date(),
        lastContact: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
    )
]

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var equipment: [Equipment]
    
    @State private var showingAddEquipment = false
    @State private var selectedCategory: EquipmentCategory = .all
    @State private var searchText = ""
    @State private var selectedEquipment: Equipment?
    
    enum EquipmentCategory: String, CaseIterable {
        case all = "All"
        case panels = "Solar Panels"
        case inverters = "Inverters"
        case batteries = "Batteries"
        case mounting = "Mounting"
        case electrical = "Electrical"
        case tools = "Tools"
    }
    
    private var filteredEquipment: [Equipment] {
        var filtered = equipment
        
        if selectedCategory != .all {
            filtered = filtered.filter { $0.category == selectedCategory.rawValue }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.brand.localizedCaseInsensitiveContains(searchText) ||
                item.model.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    private var lowStockItems: [Equipment] {
        equipment.filter { $0.quantity <= $0.lowStockThreshold }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with stats
                inventoryHeader
                
                // Category filter
                categoryFilter
                
                // Equipment grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        ForEach(filteredEquipment, id: \.id) { item in
                            EquipmentCard(equipment: item)
                                .onTapGesture {
                                    selectedEquipment = item
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddEquipment = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showingAddEquipment) {
                AddEquipmentSheet()
            }
            .sheet(item: $selectedEquipment) { equipment in
                EquipmentDetailSheet(equipment: equipment)
            }
        }
        .searchable(text: $searchText, prompt: "Search equipment...")
    }
    
    // MARK: - Inventory Header
    private var inventoryHeader: some View {
        VStack(spacing: 16) {
            // Quick stats
            HStack(spacing: 16) {
                InventoryStatView(
                    title: "Total Items",
                    value: "\(equipment.count)",
                    icon: "box.fill",
                    color: .blue
                )
                
                InventoryStatView(
                    title: "Low Stock",
                    value: "\(lowStockItems.count)",
                    icon: "exclamationmark.triangle.fill",
                    color: lowStockItems.isEmpty ? .green : .red
                )
                
                InventoryStatView(
                    title: "Categories",
                    value: "\(Set(equipment.map { $0.category }).count)",
                    icon: "tag.fill",
                    color: .orange
                )
            }
            .padding(.horizontal, 16)
            
            // Low stock alert
            if !lowStockItems.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("\(lowStockItems.count) items running low on stock")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(EquipmentCategory.allCases, id: \.self) { category in
                    CategoryPill(
                        title: category.rawValue,
                        count: category == .all ? equipment.count : equipment.filter { $0.category == category.rawValue }.count,
                        isSelected: selectedCategory == category
                    )
                    .onTapGesture {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
}

// MARK: - Equipment Card
struct EquipmentCard: View {
    let equipment: Equipment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Equipment image or placeholder
            Group {
                if let imageData = equipment.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // Default placeholder based on category
                    Image(systemName: iconForCategory(equipment.category))
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.orange.opacity(0.1))
                }
            }
            .frame(height: 120)
            .clipped()
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(equipment.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Text("\(equipment.brand) \(equipment.model)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "number")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(equipment.quantity)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(equipment.quantity <= equipment.lowStockThreshold ? .red : .primary)
                    }
                    
                    Spacer()
                    
                    Text("$\(equipment.unitPrice, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                if !equipment.equipmentDescription.isEmpty {
                    Text(equipment.equipmentDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            // Stock warning badge
            Group {
                if equipment.quantity <= equipment.lowStockThreshold {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
        )
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "solar panels": return "sun.max.fill"
        case "inverters": return "bolt.fill"
        case "batteries": return "battery.100"
        case "mounting": return "square.stack.3d.up.fill"
        case "electrical": return "cable.connector"
        case "tools": return "wrench.and.screwdriver.fill"
        default: return "box.fill"
        }
    }
}

// MARK: - Add Equipment Sheet
struct AddEquipmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var category = "Solar Panels"
    @State private var brand = ""
    @State private var model = ""
    @State private var quantity = ""
    @State private var unitPrice = ""
    @State private var equipmentDescription = ""
    @State private var lowStockThreshold = "5"
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingImageOptions = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, brand, model, quantity, unitPrice, description, threshold
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !brand.isEmpty && !model.isEmpty && 
        !quantity.isEmpty && !unitPrice.isEmpty &&
        Int(quantity) != nil && Double(unitPrice) != nil
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: "box.badge.plus")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("Add Equipment")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    // Image upload section
                    imageUploadSection
                    
                    // Form sections
                    VStack(spacing: 24) {
                        // Basic Information
                        FormSection(title: "Basic Information", icon: "info.circle.fill") {
                            CustomTextField(
                                title: "Equipment Name",
                                text: $name,
                                placeholder: "Tier 1 Solar Panel",
                                icon: "tag"
                            )
                            .focused($focusedField, equals: .name)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "list.bullet")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    Text("Category")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Picker("Category", selection: $category) {
                                    ForEach(Array(InventoryView.EquipmentCategory.allCases.dropFirst()), id: \.rawValue) { cat in
                                        Text(cat.rawValue).tag(cat.rawValue)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.orange)
                            }
                            
                            CustomTextField(
                                title: "Brand",
                                text: $brand,
                                placeholder: "SunPower",
                                icon: "building.2"
                            )
                            .focused($focusedField, equals: .brand)
                            
                            CustomTextField(
                                title: "Model",
                                text: $model,
                                placeholder: "X-Series X22-370",
                                icon: "rectangle.3.group"
                            )
                            .focused($focusedField, equals: .model)
                        }
                        
                        // Quantity and Pricing
                        FormSection(title: "Inventory Details", icon: "number.circle.fill") {
                            HStack(spacing: 16) {
                                CustomTextField(
                                    title: "Quantity",
                                    text: $quantity,
                                    placeholder: "50",
                                    icon: "number"
                                )
                                .focused($focusedField, equals: .quantity)
                                .keyboardType(.numberPad)
                                
                                CustomTextField(
                                    title: "Unit Price",
                                    text: $unitPrice,
                                    placeholder: "300",
                                    icon: "dollarsign.circle"
                                )
                                .focused($focusedField, equals: .unitPrice)
                                .keyboardType(.decimalPad)
                            }
                            
                            CustomTextField(
                                title: "Low Stock Alert",
                                text: $lowStockThreshold,
                                placeholder: "5",
                                icon: "exclamationmark.triangle"
                            )
                            .focused($focusedField, equals: .threshold)
                            .keyboardType(.numberPad)
                        }
                        
                        // Description
                        FormSection(title: "Description", icon: "doc.text") {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    Text("Equipment Description")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                TextEditor(text: $equipmentDescription)
                                    .frame(minHeight: 80)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .focused($focusedField, equals: .description)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Equipment") {
                        saveEquipment()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? .orange : .secondary)
                    .disabled(!isFormValid)
                }
            }
        }
        .confirmationDialog("Add Photo", isPresented: $showingImageOptions) {
            Button("Camera") {
                showingCamera = true
            }
            Button("Photo Library") {
                showingImagePicker = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
    }
    
    // MARK: - Image Upload Section
    private var imageUploadSection: some View {
        VStack(spacing: 12) {
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(
                        Button {
                            showingImageOptions = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(8),
                        alignment: .topTrailing
                    )
            } else {
                Button {
                    showingImageOptions = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("Add Equipment Photo")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Text("Tap to add image from camera or library")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func saveEquipment() {
        guard isFormValid,
              let quantityInt = Int(quantity),
              let priceDouble = Double(unitPrice),
              let thresholdInt = Int(lowStockThreshold) else { return }
        
        let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
        
        let newEquipment = Equipment(
            name: name,
            category: category,
            brand: brand,
            model: model,
            quantity: quantityInt,
            unitPrice: priceDouble,
            equipmentDescription: equipmentDescription,
            imageData: imageData,
            lowStockThreshold: thresholdInt
        )
        
        modelContext.insert(newEquipment)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save equipment: \(error)")
        }
    }
}

// MARK: - Supporting Views
struct InventoryStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CategoryPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(isSelected ? Color.white : Color.orange.opacity(0.2))
                .foregroundColor(isSelected ? .orange : .orange)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.orange : Color(.systemGray6))
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(20)
    }
}

// MARK: - Equipment Detail Sheet
struct EquipmentDetailSheet: View {
    let equipment: Equipment
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var equipmentDescription: String = ""
    @State private var isEditingDescription = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Equipment image
                    Group {
                        if let imageData = equipment.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 250)
                                .clipped()
                        } else {
                            Image(systemName: iconForCategory(equipment.category))
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                                .frame(height: 250)
                                .frame(maxWidth: .infinity)
                                .background(Color.orange.opacity(0.1))
                        }
                    }
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    // Equipment details
                    VStack(spacing: 16) {
                        Text(equipment.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("\(equipment.brand) \(equipment.model)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        // Stats
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(equipment.quantity)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(equipment.quantity <= equipment.lowStockThreshold ? .red : .primary)
                                Text("In Stock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack {
                                Text("$\(equipment.unitPrice, specifier: "%.0f")")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text("Unit Price")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack {
                                Text("$\(Double(equipment.quantity) * equipment.unitPrice, specifier: "%.0f")")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                Text("Total Value")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Description section with edit capability
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Description")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button {
                                    if isEditingDescription {
                                        // Save description (in a real app, you'd update the model)
                                        isEditingDescription = false
                                    } else {
                                        equipmentDescription = equipment.equipmentDescription
                                        isEditingDescription = true
                                    }
                                } label: {
                                    Image(systemName: isEditingDescription ? "checkmark" : "pencil")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            if isEditingDescription {
                                TextEditor(text: $equipmentDescription)
                                    .frame(minHeight: 100)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            } else {
                                Text(equipment.equipmentDescription.isEmpty ? "No description available" : equipment.equipmentDescription)
                                    .font(.body)
                                    .foregroundColor(equipment.equipmentDescription.isEmpty ? .secondary : .primary)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                }
            }
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "solar panels": return "sun.max.fill"
        case "inverters": return "bolt.fill"
        case "batteries": return "battery.100"
        case "mounting": return "square.stack.3d.up.fill"
        case "electrical": return "cable.connector"
        case "tools": return "wrench.and.screwdriver.fill"
        default: return "box.fill"
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
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
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}


#Preview {
    ContentView()
}
