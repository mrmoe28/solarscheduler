import SwiftUI

struct ProfileView: View {
    @AppStorage("userName") private var userName = "John Smith"
    @AppStorage("userEmail") private var userEmail = "john.smith@solarbusiness.com"
    @AppStorage("userPhone") private var userPhone = "(555) 123-4567"
    @AppStorage("companyName") private var companyName = "Solar Solutions Inc."
    @AppStorage("userRole") private var userRole = "Project Manager"
    
    @State private var showingEditProfile = false
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Profile Image
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange, .orange.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                
                                // Edit overlay
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "camera")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        VStack(spacing: 8) {
                            Text(userName)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(userRole)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(companyName)
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Profile Information
                    VStack(spacing: 16) {
                        ProfileInfoCard(
                            title: "Contact Information",
                            items: [
                                ProfileInfoItem(icon: "envelope", label: "Email", value: userEmail),
                                ProfileInfoItem(icon: "phone", label: "Phone", value: userPhone)
                            ]
                        )
                        
                        ProfileInfoCard(
                            title: "Business Information",
                            items: [
                                ProfileInfoItem(icon: "building.2", label: "Company", value: companyName),
                                ProfileInfoItem(icon: "person.badge.key", label: "Role", value: userRole)
                            ]
                        )
                        
                        ProfileInfoCard(
                            title: "Account Statistics",
                            items: [
                                ProfileInfoItem(icon: "hammer", label: "Active Jobs", value: "12"),
                                ProfileInfoItem(icon: "person.2", label: "Total Customers", value: "45"),
                                ProfileInfoItem(icon: "calendar", label: "This Month Installs", value: "8")
                            ]
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Quick Actions
                    VStack(spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 8) {
                            ProfileActionButton(
                                icon: "pencil",
                                title: "Edit Profile",
                                color: .blue
                            ) {
                                showingEditProfile = true
                            }
                            
                            ProfileActionButton(
                                icon: "key",
                                title: "Change Password",
                                color: .orange
                            ) {
                                // Implement password change
                            }
                            
                            ProfileActionButton(
                                icon: "bell",
                                title: "Notification Settings",
                                color: .green
                            ) {
                                // Navigate to notification settings
                            }
                            
                            ProfileActionButton(
                                icon: "arrow.right.square",
                                title: "Sign Out",
                                color: .red
                            ) {
                                // Implement sign out
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(
                    userName: $userName,
                    userEmail: $userEmail,
                    userPhone: $userPhone,
                    companyName: $companyName,
                    userRole: $userRole
                )
            }
        }
    }
}

// MARK: - Profile Info Card
struct ProfileInfoCard: View {
    let title: String
    let items: [ProfileInfoItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(items, id: \.label) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.label)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(item.value)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Profile Info Item
struct ProfileInfoItem {
    let icon: String
    let label: String
    let value: String
}

// MARK: - Profile Action Button
struct ProfileActionButton: View {
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

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var userName: String
    @Binding var userEmail: String
    @Binding var userPhone: String
    @Binding var companyName: String
    @Binding var userRole: String
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Full Name", text: $userName)
                    TextField("Email", text: $userEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $userPhone)
                        .keyboardType(.phonePad)
                }
                
                Section("Business Information") {
                    TextField("Company Name", text: $companyName)
                    TextField("Role/Title", text: $userRole)
                }
            }
            .navigationTitle("Edit Profile")
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
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}