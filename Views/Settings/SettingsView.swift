import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Settings Header
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Settings")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Manage your app preferences")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Profile avatar
                        Button(action: {
                            // This will be handled by the account settings tab
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.2))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "person.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Settings Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SettingsTab.allCases, id: \.self) { tab in
                                SettingsTabButton(
                                    tab: tab,
                                    isSelected: selectedTab == tab
                                ) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedTab = tab
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 20)
                .background(Color(UIColor.systemBackground))
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    GeneralSettingsView()
                        .tag(SettingsTab.general)
                    
                    NotificationsSettingsView()
                        .tag(SettingsTab.notifications)
                    
                    AccountSettingsView()
                        .tag(SettingsTab.account)
                    
                    AppearanceSettingsView()
                        .tag(SettingsTab.appearance)
                    
                    DataSettingsView()
                        .tag(SettingsTab.data)
                    
                    AboutSettingsView()
                        .tag(SettingsTab.about)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Settings Tab Enum
enum SettingsTab: String, CaseIterable {
    case general = "General"
    case notifications = "Notifications"
    case account = "Account"
    case appearance = "Appearance"
    case data = "Data"
    case about = "About"
    
    var icon: String {
        switch self {
        case .general: return "gear"
        case .notifications: return "bell"
        case .account: return "person.circle"
        case .appearance: return "paintpalette"
        case .data: return "externaldrive"
        case .about: return "info.circle"
        }
    }
}

// MARK: - Settings Tab Button
struct SettingsTabButton: View {
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(tab.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.orange : Color(UIColor.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - General Settings View
struct GeneralSettingsView: View {
    @AppStorage("companyName") private var companyName = "Solar Solutions Inc."
    @AppStorage("defaultCurrency") private var defaultCurrency = "USD"
    @AppStorage("taxRate") private var taxRate = "8.5"
    @AppStorage("defaultMargin") private var defaultMargin = "20"
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("showTips") private var showTips = true
    @AppStorage("measurementUnit") private var measurementUnit = "Imperial"
    
    var body: some View {
        List {
            Section("Company Information") {
                HStack {
                    Image(systemName: "building.2")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    TextField("Company Name", text: $companyName)
                }
            }
            
            Section("Financial Settings") {
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    Text("Default Currency")
                    
                    Spacer()
                    
                    Picker("Currency", selection: $defaultCurrency) {
                        Text("USD ($)").tag("USD")
                        Text("EUR (€)").tag("EUR")
                        Text("GBP (£)").tag("GBP")
                        Text("CAD (C$)").tag("CAD")
                        Text("AUD (A$)").tag("AUD")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                HStack {
                    Image(systemName: "percent")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    Text("Default Tax Rate")
                    
                    Spacer()
                    
                    TextField("8.5", text: $taxRate)
                        .keyboardType(.decimalPad)
                        .frame(width: 60)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("%")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    Text("Default Profit Margin")
                    
                    Spacer()
                    
                    TextField("20", text: $defaultMargin)
                        .keyboardType(.decimalPad)
                        .frame(width: 60)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("%")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("System Preferences") {
                HStack {
                    Image(systemName: "ruler")
                        .foregroundColor(.cyan)
                        .frame(width: 24)
                    
                    Text("Measurement Units")
                    
                    Spacer()
                    
                    Picker("Units", selection: $measurementUnit) {
                        Text("Imperial (ft, in)").tag("Imperial")
                        Text("Metric (m, cm)").tag("Metric")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                HStack {
                    Image(systemName: "square.and.arrow.down.on.square")
                        .foregroundColor(Color.blue)
                        .frame(width: 24)
                    
                    Toggle("Auto Save Changes", isOn: $autoSave)
                }
                
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                    
                    Toggle("Show Helpful Tips", isOn: $showTips)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

// MARK: - Notifications Settings View
struct NotificationsSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("pushNotifications") private var pushNotifications = true
    @AppStorage("emailNotifications") private var emailNotifications = false
    @AppStorage("calendarReminders") private var calendarReminders = true
    
    var body: some View {
        List {
            Section("Notifications") {
                HStack {
                    Image(systemName: "bell")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                }
                
                HStack {
                    Image(systemName: "app.badge")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Toggle("Push Notifications", isOn: $pushNotifications)
                }
                .disabled(!notificationsEnabled)
                
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(Color.blue)
                        .frame(width: 24)
                    
                    Toggle("Email Notifications", isOn: $emailNotifications)
                }
                .disabled(!notificationsEnabled)
                
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    Toggle("Calendar Reminders", isOn: $calendarReminders)
                }
                .disabled(!notificationsEnabled)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

// MARK: - Account Settings View
struct AccountSettingsView: View {
    @ObservedObject private var userSession = UserSession.shared
    @State private var showingSignOut = false
    @State private var showingProfile = false
    @State private var showingDeleteAccount = false
    
    var body: some View {
        List {
            // User Info Section
            if let user = userSession.currentUser {
                Section {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Text(userInitials)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.fullName)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if !user.companyName.isEmpty {
                                Text(user.companyName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section("Account Management") {
                Button(action: {
                    showingProfile = true
                }) {
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(Color.blue)
                            .frame(width: 24)
                        
                        Text("Edit Profile")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Image(systemName: "key")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    Button("Change Password") {
                        // Implement password change
                    }
                    .foregroundColor(.primary)
                }
                
                let (jobStats, equipmentStats) = userSession.getUserStatistics()
                
                if let jobStats = jobStats {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "chart.bar")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            
                            Text("Account Statistics")
                                .font(.headline)
                        }
                        
                        VStack(spacing: 4) {
                            HStack {
                                Text("Total Jobs:")
                                Spacer()
                                Text("\\(jobStats.totalJobs)")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Completed Jobs:")
                                Spacer()
                                Text("\\(jobStats.completedJobs)")
                                    .foregroundColor(.green)
                            }
                            
                            if let equipmentStats = equipmentStats {
                                HStack {
                                    Text("Equipment Items:")
                                    Spacer()
                                    Text("\\(equipmentStats.totalItems)")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .font(.subheadline)
                        .padding(.leading, 32)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section("Danger Zone") {
                HStack {
                    Image(systemName: "arrow.right.square")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    Button("Sign Out") {
                        showingSignOut = true
                    }
                    .foregroundColor(.orange)
                }
                
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Button("Delete Account") {
                        showingDeleteAccount = true
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .sheet(isPresented: $showingProfile) {
            UserProfileView()
        }
        .alert("Sign Out", isPresented: $showingSignOut) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                userSession.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccount) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Account", role: .destructive) {
                userSession.deleteAccount()
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
    
    private var userInitials: String {
        guard let user = userSession.currentUser else { return "?" }
        let names = user.fullName.split(separator: " ")
        if names.count >= 2 {
            return "\(names.first?.first ?? "?")\(names.last?.first ?? "?")"
        } else if let first = names.first?.first {
            return String(first)
        }
        return "?"
    }
}

// MARK: - Appearance Settings View
struct AppearanceSettingsView: View {
    @AppStorage("selectedTheme") private var selectedTheme = "Auto"
    @AppStorage("accentColor") private var accentColor = "Orange"
    
    var body: some View {
        List {
            Section("Theme") {
                HStack {
                    Image(systemName: "paintbrush")
                        .foregroundColor(Color.blue)
                        .frame(width: 24)
                    
                    Text("App Theme")
                    
                    Spacer()
                    
                    Picker("Theme", selection: $selectedTheme) {
                        Text("Auto").tag("Auto")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                HStack {
                    Image(systemName: "paintpalette")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    Text("Accent Color")
                    
                    Spacer()
                    
                    Picker("Accent", selection: $accentColor) {
                        Text("Orange").tag("Orange")
                        Text("Blue").tag("Blue")
                        Text("Green").tag("Green")
                        Text("Purple").tag("Purple")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

// MARK: - Data Settings View
struct DataSettingsView: View {
    @AppStorage("autoBackup") private var autoBackup = false
    @AppStorage("syncFrequency") private var syncFrequency = "Daily"
    @AppStorage("dataRetentionPeriod") private var dataRetentionPeriod = "Forever"
    @AppStorage("exportFormat") private var exportFormat = "CSV"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showingDataClearAlert = false
    @State private var showingBackupRestoreAlert = false
    @State private var showingExportOptions = false
    @State private var lastBackupDate = "Never"
    
    var body: some View {
        List {
            Section("Backup & Sync") {
                HStack {
                    Image(systemName: "icloud.and.arrow.up")
                        .foregroundColor(Color.blue)
                        .frame(width: 24)
                    
                    Toggle("Auto Backup to iCloud", isOn: $autoBackup)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    Text("Sync Frequency")
                    
                    Spacer()
                    
                    Picker("Sync Frequency", selection: $syncFrequency) {
                        Text("Real-time").tag("Real-time")
                        Text("Hourly").tag("Hourly")
                        Text("Daily").tag("Daily")
                        Text("Weekly").tag("Weekly")
                        Text("Manual").tag("Manual")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.cyan)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last Backup")
                            .font(.body)
                        Text(lastBackupDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Backup Now") {
                        performBackup()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                HStack {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    Button("Restore from Backup") {
                        showingBackupRestoreAlert = true
                    }
                    .foregroundColor(.primary)
                }
            }
            
            Section("Data Export") {
                HStack {
                    Image(systemName: "doc.plaintext")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    Text("Default Export Format")
                    
                    Spacer()
                    
                    Picker("Export Format", selection: $exportFormat) {
                        Text("CSV").tag("CSV")
                        Text("JSON").tag("JSON")
                        Text("PDF Report").tag("PDF")
                        Text("Excel (.xlsx)").tag("Excel")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    Button("Export All Data") {
                        showingExportOptions = true
                    }
                    .foregroundColor(.primary)
                }
                
                HStack {
                    Image(systemName: "doc.badge.gearshape")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    Button("Generate Business Report") {
                        generateBusinessReport()
                    }
                    .foregroundColor(.primary)
                }
            }
            
            Section("Data Management") {
                HStack {
                    Image(systemName: "trash.circle")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("Data Retention")
                    
                    Spacer()
                    
                    Picker("Retention Period", selection: $dataRetentionPeriod) {
                        Text("30 Days").tag("30 Days")
                        Text("90 Days").tag("90 Days")
                        Text("1 Year").tag("1 Year")
                        Text("2 Years").tag("2 Years")
                        Text("Forever").tag("Forever")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                HStack {
                    Image(systemName: "opticaldisc")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Button("Optimize Database") {
                        optimizeDatabase()
                    }
                    .foregroundColor(.primary)
                }
                
                HStack {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .foregroundColor(.cyan)
                        .frame(width: 24)
                    
                    Button("View Storage Usage") {
                        viewStorageUsage()
                    }
                    .foregroundColor(.primary)
                }
            }
            
            Section("Reset Options") {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    Button("Reset Onboarding") {
                        hasCompletedOnboarding = false
                    }
                    .foregroundColor(.primary)
                }
                
                HStack {
                    Image(systemName: "gear.badge.xmark")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    Button("Reset All Settings") {
                        resetAllSettings()
                    }
                    .foregroundColor(.primary)
                }
                
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Button("Clear All Data") {
                        showingDataClearAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .alert("Clear All Data", isPresented: $showingDataClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All Data", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will permanently delete all jobs, customers, vendors, and other data. This action cannot be undone.")
        }
        .alert("Restore from Backup", isPresented: $showingBackupRestoreAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Restore", role: .destructive) {
                restoreFromBackup()
            }
        } message: {
            Text("This will replace all current data with data from your most recent backup. Current data will be lost.")
        }
        .confirmationDialog("Export Options", isPresented: $showingExportOptions) {
            Button("Export Jobs Only") { exportData(type: "jobs") }
            Button("Export Customers Only") { exportData(type: "customers") }
            Button("Export Installations Only") { exportData(type: "installations") }
            Button("Export Everything") { exportData(type: "all") }
            Button("Cancel", role: .cancel) { }
        }
        .onAppear {
            loadLastBackupDate()
        }
    }
    
    private func performBackup() {
        // Implement backup functionality
        lastBackupDate = Date().formatted(date: .abbreviated, time: .shortened)
    }
    
    private func restoreFromBackup() {
        // Implement restore functionality
        print("Restoring from backup...")
    }
    
    private func exportData(type: String) {
        // Implement data export functionality
        print("Exporting \(type) data in \(exportFormat) format")
    }
    
    private func generateBusinessReport() {
        // Implement business report generation
        print("Generating comprehensive business report...")
    }
    
    private func optimizeDatabase() {
        // Implement database optimization
        print("Optimizing database...")
    }
    
    private func viewStorageUsage() {
        // Implement storage usage view
        print("Viewing storage usage...")
    }
    
    private func resetAllSettings() {
        // Reset all app settings to defaults
        print("Resetting all settings to defaults...")
    }
    
    private func clearAllData() {
        // Implement data clearing functionality
        print("Clearing all application data...")
    }
    
    private func loadLastBackupDate() {
        // Load actual last backup date from UserDefaults or CloudKit
        // For now, showing placeholder
        lastBackupDate = "Never"
    }
}

// MARK: - About Settings View
struct AboutSettingsView: View {
    @State private var showingAbout = false
    
    var body: some View {
        List {
            Section("Support") {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(Color.blue)
                        .frame(width: 24)
                    
                    Button("About Solar Scheduler") {
                        showingAbout = true
                    }
                    .foregroundColor(.primary)
                }
                
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    Button("Help & Feedback") {
                        // Open help
                    }
                    .foregroundColor(.primary)
                }
                
                HStack {
                    Image(systemName: "star")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                    
                    Button("Rate the App") {
                        // Open app store rating
                    }
                    .foregroundColor(.primary)
                }
            }
            
            Section("App Info") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text("2")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Release Date")
                    Spacer()
                    Text("January 2025")
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("Solar Scheduler")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Version 1.0 (Build 2)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Streamline your solar business operations with comprehensive project management, customer tracking, and installation scheduling.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("© 2025 Solar Scheduler")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Built with SwiftUI & SwiftData")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle("About")
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

#Preview {
    SettingsView()
}