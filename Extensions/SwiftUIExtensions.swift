import SwiftUI

// MARK: - Platform-specific imports
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Color Extensions for Cross-Platform Support
extension Color {
    #if os(iOS)
    static let systemBackground = Color(UIColor.systemBackground)
    static let secondarySystemBackground = Color(UIColor.secondarySystemBackground)
    static let systemGray6 = Color(UIColor.systemGray6)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    #elseif os(macOS)
    static let systemBackground = Color(NSColor.windowBackgroundColor)
    static let secondarySystemBackground = Color(NSColor.controlBackgroundColor)
    static let systemGray6 = Color(NSColor.quaternaryLabelColor)
    static let secondaryBackground = Color(NSColor.controlBackgroundColor)
    #endif
}

// MARK: - SwiftUI Extensions for Enhanced UX

extension View {
    /// Adds a subtle bounce animation when the view appears
    func bounceOnAppear(delay: Double = 0) -> some View {
        self
            .scaleEffect(0.8)
            .opacity(0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                    // Animation will be handled by the .animation modifier
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: true)
    }
    
    /// Adds haptic feedback for button interactions
    func withHapticFeedback(_ feedback: SensoryFeedback = .impact(flexibility: .soft, intensity: 0.5)) -> some View {
        self.sensoryFeedback(feedback, trigger: true)
    }
    
    /// Adds a subtle shadow with animation
    func animatedShadow(isActive: Bool = true) -> some View {
        self.shadow(
            color: .black.opacity(isActive ? 0.1 : 0),
            radius: isActive ? 8 : 0,
            x: 0,
            y: isActive ? 4 : 0
        )
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
    
    /// Adds a glassmorphism effect
    func glassMorphism() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
    }
    
    /// Adds a pulsing animation for loading states
    func pulseAnimation() -> some View {
        self
            .opacity(0.6)
            .scaleEffect(0.95)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: UUID())
    }
}

// MARK: - Custom Button Styles

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct GlassButtonStyle: ButtonStyle {
    let color: Color
    
    init(color: Color = .orange) {
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(configuration.isPressed ? 0.2 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Loading States

struct ShimmerView: View {
    @State private var startPoint = UnitPoint(x: -0.5, y: 0.5)
    @State private var endPoint = UnitPoint(x: 0.5, y: 1.5)
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.gray.opacity(0.1),
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.1)
            ],
            startPoint: startPoint,
            endPoint: endPoint
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                startPoint = UnitPoint(x: 1.5, y: -0.5)
                endPoint = UnitPoint(x: 2.5, y: 0.5)
            }
        }
    }
}

struct LoadingCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(ShimmerView())
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 16)
                    .overlay(ShimmerView())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 24)
                    .overlay(ShimmerView())
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(ShimmerView())
            }
        }
        .padding()
        .background(Color.secondarySystemBackground)
        .cornerRadius(12)
    }
}

// MARK: - Success Animation

struct SuccessCheckmarkView: View {
    @State private var trimEnd: CGFloat = 0
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green)
                .frame(width: 60, height: 60)
                .scaleEffect(scale)
                .opacity(opacity)
            
            Path { path in
                path.move(to: CGPoint(x: 20, y: 30))
                path.addLine(to: CGPoint(x: 26, y: 36))
                path.addLine(to: CGPoint(x: 40, y: 22))
            }
            .trim(from: 0, to: trimEnd)
            .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .frame(width: 60, height: 60)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                trimEnd = 1.0
            }
        }
    }
}

// MARK: - Error Animation

struct ErrorShakeView: View {
    @State private var offset: CGFloat = 0
    
    let content: AnyView
    
    init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }
    
    var body: some View {
        content
            .offset(x: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.1).repeatCount(6, autoreverses: true)) {
                    offset = 10
                }
            }
    }
}

// MARK: - Real-time Data Indicators

struct LiveDataIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .opacity(isAnimating ? 0.5 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            
            Text("LIVE")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct DataUpdateIndicator: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(systemName: "arrow.clockwise")
            .font(.caption)
            .foregroundColor(.orange)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Enhanced Card Views

struct EnhancedCard<Content: View>: View {
    let content: Content
    @State private var isVisible = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondarySystemBackground)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isVisible ? 1.0 : 0.9)
            .opacity(isVisible ? 1.0 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Search Components

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.systemGray6)
        .cornerRadius(10)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(color)
            .cornerRadius(12)
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: String
    let color: Color
    
    var body: some View {
        Text(status)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(8)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int?
    let action: () -> Void
    
    init(title: String, isSelected: Bool, count: Int? = nil, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.count = count
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let count = count {
                    Text("(\(count))")
                        .font(.caption2)
                        .fontWeight(.regular)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.orange : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

// MARK: - Equipment Image View

struct EquipmentImageView: View {
    let imageData: Data?
    let size: CGFloat
    
    init(imageData: Data?, size: CGFloat = 60) {
        self.imageData = imageData
        self.size = size
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: size, height: size)
            
            #if os(iOS)
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.gray)
            }
            #elseif os(macOS)
            if let imageData = imageData, let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.gray)
            }
            #endif
        }
    }
}

#if os(iOS)
// MARK: - Image Picker for Photo Library

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Camera Image Picker

struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraImagePicker
        
        init(_ parent: CameraImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#endif