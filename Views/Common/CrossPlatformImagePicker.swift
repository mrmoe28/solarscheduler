import SwiftUI

#if os(iOS)
import UIKit

struct CrossPlatformImagePicker: View {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    
    var body: some View {
        ImagePicker(image: $image)
    }
}

#elseif os(macOS)
import AppKit

struct CrossPlatformImagePicker: View {
    @Binding var image: NSImage?
    @Binding var isPresented: Bool
    
    var body: some View {
        MacImagePicker(image: $image, isPresented: $isPresented)
    }
}

struct MacImagePicker: NSViewRepresentable {
    @Binding var image: NSImage?
    @Binding var isPresented: Bool
    
    func makeNSView(context: Context) -> NSView {
        return NSView()
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if isPresented {
            DispatchQueue.main.async {
                self.showImagePicker()
            }
        }
    }
    
    private func showImagePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                if let nsImage = NSImage(contentsOf: url) {
                    self.image = nsImage
                }
            }
            self.isPresented = false
        }
    }
}
#endif

// Cross-platform image type
#if os(iOS)
typealias PlatformImage = UIImage
#elseif os(macOS)
typealias PlatformImage = NSImage
#endif

// Extension to convert image to Data
extension PlatformImage {
    func jpegData(compressionQuality: CGFloat) -> Data? {
        #if os(iOS)
        return self.jpegData(compressionQuality: compressionQuality)
        #elseif os(macOS)
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
        #endif
    }
}