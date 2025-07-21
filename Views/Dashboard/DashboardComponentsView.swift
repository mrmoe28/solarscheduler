import SwiftUI

// MARK: - Dashboard View
struct DashboardComponentsView: View {
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

#Preview {
    DashboardComponentsView()
}