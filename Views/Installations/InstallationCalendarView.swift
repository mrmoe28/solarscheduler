import SwiftUI
import SwiftData

struct InstallationCalendarView: View {
    @Environment(\.viewModelContainer) private var viewModelContainer
    @State private var selectedDate = Date()
    @State private var showingMonth = true
    
    private var viewModel: InstallationsViewModel {
        viewModelContainer?.installationsViewModel ?? InstallationsViewModel(
            dataService: DataService(modelContext: ModelContext(for: Schema([
                Installation.self, SolarJob.self, Customer.self, Equipment.self, Vendor.self, Contract.self
            ])))
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Calendar Header
                HStack {
                    Button(action: {
                        showingMonth.toggle()
                    }) {
                        Text(showingMonth ? "Month View" : "Week View")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        selectedDate = Date()
                    }) {
                        Text("Today")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding()
                
                // Calendar
                if showingMonth {
                    CalendarMonthView(
                        selectedDate: $selectedDate,
                        installations: viewModel.installations,
                        onDateSelected: { date in
                            selectedDate = date
                        }
                    )
                } else {
                    CalendarWeekView(
                        selectedDate: $selectedDate,
                        installations: viewModel.installations,
                        onDateSelected: { date in
                            selectedDate = date
                        }
                    )
                }
                
                // Selected Date Info
                VStack(alignment: .leading, spacing: 12) {
                    Text(selectedDate.formatted(date: .complete, time: .omitted))
                        .font(.headline)
                        .padding(.horizontal)
                    
                    let dayInstallations = viewModel.getInstallations(for: selectedDate)
                    
                    if dayInstallations.isEmpty {
                        VStack(spacing: 12) {
                            Text("No installations scheduled for this day")
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            // Show all upcoming installations if none today
                            let upcomingInstallations = viewModel.getUpcomingInstallations()
                            if !upcomingInstallations.isEmpty {
                                Text("Upcoming Installations:")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(upcomingInstallations.prefix(3), id: \.id) { installation in
                                    InstallationCalendarRowView(installation: installation)
                                        .padding(.horizontal)
                                }
                                
                                if upcomingInstallations.count > 3 {
                                    Text("... and \(upcomingInstallations.count - 3) more")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                }
                            } else {
                                Text("No installations scheduled")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            }
                        }
                    } else {
                        ForEach(dayInstallations, id: \.id) { installation in
                            InstallationCalendarRowView(installation: installation)
                                .padding(.horizontal)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical)
                
                Spacer()
            }
            .navigationTitle("Installation Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showAddInstallation() }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddInstallation) {
                AddInstallationView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }
}

struct CalendarMonthView: View {
    @Binding var selectedDate: Date
    let installations: [Installation]
    let onDateSelected: (Date) -> Void
    
    @State private var currentMonth = Date()
    
    var body: some View {
        VStack(spacing: 8) {
            // Month Header
            HStack {
                Button(action: {
                    currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            // Days Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Day headers
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                // Calendar days
                ForEach(getDaysInMonth(), id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        hasInstallations: hasInstallations(for: date),
                        installationCount: getInstallationCount(for: date)
                    ) {
                        selectedDate = date
                        onDateSelected(date)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private func getDaysInMonth() -> [Date] {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: currentMonth)!
        let startOfMonth = monthInterval.start
        let endOfMonth = monthInterval.end
        
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)!.start
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: calendar.date(byAdding: .day, value: -1, to: endOfMonth)!)!.end
        
        var dates: [Date] = []
        var currentDate = startOfWeek
        
        while currentDate <= endOfWeek {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dates
    }
    
    private func hasInstallations(for date: Date) -> Bool {
        return installations.contains { installation in
            Calendar.current.isDate(installation.scheduledDate, inSameDayAs: date)
        }
    }
    
    private func getInstallationCount(for date: Date) -> Int {
        return installations.filter { installation in
            Calendar.current.isDate(installation.scheduledDate, inSameDayAs: date)
        }.count
    }
}

struct CalendarWeekView: View {
    @Binding var selectedDate: Date
    let installations: [Installation]
    let onDateSelected: (Date) -> Void
    
    @State private var currentWeek = Date()
    
    var body: some View {
        VStack(spacing: 8) {
            // Week Header
            HStack {
                Button(action: {
                    currentWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeek) ?? currentWeek
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                Text(getWeekRange())
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    currentWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeek) ?? currentWeek
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            // Week Days
            HStack(spacing: 4) {
                ForEach(getDaysInWeek(), id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        hasInstallations: hasInstallations(for: date),
                        installationCount: getInstallationCount(for: date)
                    ) {
                        selectedDate = date
                        onDateSelected(date)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private func getDaysInWeek() -> [Date] {
        let calendar = Calendar.current
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentWeek)!
        let startOfWeek = weekInterval.start
        
        var dates: [Date] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    private func getWeekRange() -> String {
        let calendar = Calendar.current
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentWeek)!
        let startOfWeek = weekInterval.start
        let endOfWeek = calendar.date(byAdding: .day, value: -1, to: weekInterval.end)!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }
    
    private func hasInstallations(for date: Date) -> Bool {
        return installations.contains { installation in
            Calendar.current.isDate(installation.scheduledDate, inSameDayAs: date)
        }
    }
    
    private func getInstallationCount(for date: Date) -> Int {
        return installations.filter { installation in
            Calendar.current.isDate(installation.scheduledDate, inSameDayAs: date)
        }.count
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let hasInstallations: Bool
    let installationCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                
                if hasInstallations {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                        .overlay(
                            Text("\(installationCount)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
            .frame(width: max(40, 40), height: max(40, 40))
            .background(
                Circle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .overlay(
                Circle()
                    .stroke(hasInstallations ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InstallationCalendarRowView: View {
    let installation: Installation
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color(installation.status.color))
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(installation.scheduledDate.formatted(date: .omitted, time: .shortened))
                    .font(.headline)
                
                if let jobCustomer = installation.job?.customerName {
                    Text(jobCustomer)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("Crew: \(installation.crewSize) • \(installation.status.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(status: installation.status.rawValue, color: Color(installation.status.color))
                
                if installation.isOverdue {
                    Text("Overdue")
                        .font(.caption)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    InstallationCalendarView()
}