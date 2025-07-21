import SwiftUI

// MARK: - Calendar View
struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var currentDate = Date()
    @State private var showingAddInstallation = false
    @State private var selectedViewMode: CalendarViewMode = .month
    @State private var selectedInstallation: CalendarInstallation?
    @State private var showingInstallationDetail = false
    
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
            .sheet(isPresented: $showingInstallationDetail) {
                if let installation = selectedInstallation {
                    InstallationDetailSheet(installation: installation)
                }
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
                            .onTapGesture {
                                selectedInstallation = installation
                                showingInstallationDetail = true
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
    
    // MARK: - Upcoming Installations
    private var upcomingInstallations: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming This Week")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(upcomingInstallationsThisWeek, id: \.id) { installation in
                    InstallationCardView(installation: installation, showDate: true)
                        .onTapGesture {
                            selectedInstallation = installation
                            showingInstallationDetail = true
                        }
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

// MARK: - Detail Row Component
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Installation Detail Sheet
struct InstallationDetailSheet: View {
    let installation: CalendarInstallation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(installation.customerName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(installation.address)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Text(installation.status.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(installation.status.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(installation.status.color.opacity(0.1))
                                .cornerRadius(6)
                        }
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("System Size")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(installation.systemSize)
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Scheduled")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(installation.scheduledDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.headline)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(20)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Installation Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Installation Details")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            DetailRow(label: "Customer", value: installation.customerName)
                            DetailRow(label: "Address", value: installation.address)
                            DetailRow(label: "System Size", value: installation.systemSize)
                            DetailRow(label: "Status", value: installation.status.rawValue)
                            DetailRow(label: "Date", value: installation.scheduledDate.formatted(date: .complete, time: .shortened))
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Quick Actions
                    VStack(spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 8) {
                            InstallationActionButton(
                                icon: "calendar.badge.clock",
                                title: "Reschedule Installation",
                                color: .orange
                            ) {
                                // Handle reschedule
                            }
                            
                            InstallationActionButton(
                                icon: "phone.fill",
                                title: "Contact Customer",
                                color: .blue
                            ) {
                                // Handle contact
                            }
                            
                            InstallationActionButton(
                                icon: "location.fill",
                                title: "Get Directions",
                                color: .green
                            ) {
                                // Handle directions
                            }
                            
                            InstallationActionButton(
                                icon: "pencil",
                                title: "Edit Installation",
                                color: .purple
                            ) {
                                // Handle edit
                            }
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(20)
            }
            .navigationTitle("Installation Details")
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

// MARK: - Installation Action Button
struct InstallationActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}