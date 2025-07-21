import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif

// MARK: - Profile Settings View
struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var userSession = UserSession.shared
    @State private var fullName = ""
    @State private var email = ""
    @State private var companyName = ""
    @State private var phoneNumber = ""
    @State private var profileImageData: Data?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Profile Image
                    HStack {
                        Spacer()
                        
                        VStack {
                            if let imageData = profileImageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.orange, lineWidth: 3)
                                    )
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 120))
                                    .foregroundColor(.gray)
                            }
                            
                            Menu {
                                Button(action: { showingCamera = true }) {
                                    Label("Take Photo", systemImage: "camera")
                                }
                                
                                Button(action: { showingImagePicker = true }) {
                                    Label("Choose from Library", systemImage: "photo")
                                }
                                
                                if profileImageData != nil {
                                    Divider()
                                    
                                    Button(action: { profileImageData = nil }) {
                                        Label("Remove Photo", systemImage: "trash")
                                    }
                                }
                            } label: {
                                Text(profileImageData == nil ? "Add Photo" : "Change Photo")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Personal Information") {
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disabled(true) // Email cannot be changed
                        .foregroundColor(.secondary)
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section("Company Information") {
                    TextField("Company Name", text: $companyName)
                        .textContentType(.organizationName)
                }
            }
            .navigationTitle("Profile Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadUserData()
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            #if os(iOS)
            .sheet(isPresented: $showingImagePicker) {
                ProfileImagePicker(imageData: $profileImageData, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingCamera) {
                ProfileImagePicker(imageData: $profileImageData, sourceType: .camera)
            }
            #endif
        }
    }
    
    private func loadUserData() {
        guard let user = userSession.currentUser else { return }
        
        fullName = user.fullName
        email = user.email
        companyName = user.companyName ?? ""
        phoneNumber = user.phoneNumber ?? ""
        profileImageData = user.profileImageData
    }
    
    private func saveProfile() {
        guard let user = userSession.currentUser else {
            alertMessage = "No user found"
            showingAlert = true
            return
        }
        
        user.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        user.companyName = companyName.isEmpty ? nil : companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        user.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        user.profileImageData = profileImageData
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = "Failed to save profile: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// MARK: - Profile Image Picker
#if os(iOS)
struct ProfileImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ProfileImagePicker
        
        init(_ parent: ProfileImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image: UIImage?
            
            if let editedImage = info[.editedImage] as? UIImage {
                image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                image = originalImage
            } else {
                image = nil
            }
            
            if let image = image,
               let imageData = image.jpegData(compressionQuality: 0.7) {
                parent.imageData = imageData
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif