import SwiftUI

struct UserProfileView: View {
    @ObservedObject private var userSession = UserSession.shared
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var companyName = ""
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var showingSignOutAlert = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Header
                Section {
                    HStack {
                        // Profile Avatar
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Text(userInitials)
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userSession.currentUser?.fullName ?? "Unknown User")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(userSession.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let companyName = userSession.currentUser?.companyName, !companyName.isEmpty {
                                Text(companyName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Account Information
                Section(header: Text("Account Information")) {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(userSession.currentUser?.email ?? "")
                            .foregroundColor(.secondary)
                    }
                    
                    if isEditing {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Full Name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Full Name", text: $fullName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Company Name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Company Name", text: $companyName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    } else {
                        HStack {
                            Text("Full Name")
                            Spacer()
                            Text(userSession.currentUser?.fullName ?? "")
                                .foregroundColor(.secondary)
                        }
                        
                        if let company = userSession.currentUser?.companyName, !company.isEmpty {
                            HStack {
                                Text("Company")
                                Spacer()
                                Text(company)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Account Statistics
                Section(header: Text("Account Statistics")) {
                    if let user = userSession.currentUser {
                        HStack {
                            Text("Member Since")
                            Spacer()
                            Text(user.createdDate, style: .date)
                                .foregroundColor(.secondary)
                        }
                        
                        if let lastSignIn = user.lastSignInDate {
                            HStack {
                                Text("Last Sign In")
                                Spacer()
                                Text(lastSignIn, style: .relative)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        let (jobStats, equipmentStats) = userSession.getUserStatistics()
                        
                        if let jobStats = jobStats {
                            HStack {
                                Text("Total Jobs")
                                Spacer()
                                Text("\\(jobStats.totalJobs)")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Completed Jobs")
                                Spacer()
                                Text("\\(jobStats.completedJobs)")
                                    .foregroundColor(.green)
                            }
                        }
                        
                        if let equipmentStats = equipmentStats {
                            HStack {
                                Text("Equipment Items")
                                Spacer()
                                Text("\\(equipmentStats.totalItems)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Account Actions
                Section(header: Text("Account Actions")) {
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.orange)
                            Text("Sign Out")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Delete Account")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveProfile()
                        }
                        .disabled(isLoading)
                    } else {
                        Button("Edit") {
                            startEditing()
                        }
                    }
                }
            }
            .onAppear {
                loadUserData()
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    userSession.signOut()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    userSession.deleteAccount()
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
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
    
    private func loadUserData() {
        guard let user = userSession.currentUser else { return }
        fullName = user.fullName
        companyName = user.companyName
    }
    
    private func startEditing() {
        isEditing = true
        loadUserData()
    }
    
    private func saveProfile() {
        isLoading = true
        
        userSession.updateProfile(
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            companyName: companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            isEditing = false
        }
    }
}

#Preview {
    UserProfileView()
}