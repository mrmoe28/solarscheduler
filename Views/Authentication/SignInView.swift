import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @State private var userSession = UserSession.shared
    @State private var email = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.1),
                        Color.blue.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
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
                    
                    // Sign In Options
                    VStack(spacing: 16) {
                        // Apple Sign In
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                handleSignInWithApple(result)
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(10)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                            
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 10)
                        
                        // Demo Account
                        Button(action: signInAsDemo) {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .font(.title3)
                                
                                Text("Continue with Demo Account")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading)
                        
                        // Guest Mode
                        Button(action: continueAsGuest) {
                            Text("Continue as Guest")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Footer
                    VStack(spacing: 8) {
                        Text("By continuing, you agree to our")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            Button("Terms of Service") {
                                // Handle terms
                            }
                            .font(.caption)
                            
                            Button("Privacy Policy") {
                                // Handle privacy
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.bottom, 20)
                }
                
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.orange)
                }
            }
        }
        .alert("Sign In Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Sign In Methods
    
    private func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                showError("Invalid Apple ID credentials")
                return
            }
            
            isLoading = true
            
            let userID = appleIDCredential.user
            let email = appleIDCredential.email ?? "apple.user@example.com"
            let fullName = appleIDCredential.fullName
            
            let displayName = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
                .isEmpty ? "Apple User" : [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            Task {
                do {
                    try await userSession.signIn(email: email, name: displayName)
                    isLoading = false
                } catch {
                    isLoading = false
                    showError(error.localizedDescription)
                }
            }
            
        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                showError(error.localizedDescription)
            }
        }
    }
    
    private func signInAsDemo() {
        isLoading = true
        
        Task {
            do {
                try await userSession.signIn(email: "demo@solarscheduler.app", name: "Demo User")
                isLoading = false
            } catch {
                isLoading = false
                showError(error.localizedDescription)
            }
        }
    }
    
    private func continueAsGuest() {
        isLoading = true
        
        Task {
            do {
                try await userSession.signIn(email: "guest@solarscheduler.app", name: "Guest User")
                isLoading = false
            } catch {
                isLoading = false
                showError(error.localizedDescription)
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

#Preview {
    SignInView()
}