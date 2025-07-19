import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showingAbout = false
    
    var body: some View {
        List {
                Section("Appearance") {
                    HStack {
                        Image(systemName: "paintbrush")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Theme")
                        
                        Spacer()
                        
                        Picker("Theme", selection: $themeManager.selectedTheme) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section("Data") {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        Button("Reset Onboarding") {
                            hasCompletedOnboarding = false
                        }
                        .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        Button("Clear All Data") {
                            // Implement data clearing
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section("Support") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Button("About") {
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
                }
            }
        .navigationTitle("Settings")
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
        .environmentObject(ThemeManager())
}