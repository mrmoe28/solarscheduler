import SwiftUI

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
                                        .textInputAutocapitalization(.words)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("Enter your email", text: $email)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .textInputAutocapitalization(.never)
                                        .keyboardType(.emailAddress)
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
                                        .textInputAutocapitalization(.words)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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

#Preview {
    SignUpView()
}