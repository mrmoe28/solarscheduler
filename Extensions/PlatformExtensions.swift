import SwiftUI

// MARK: - Platform-specific type aliases
#if os(iOS)
import UIKit
public typealias PlatformImage = UIImage
public typealias PlatformColor = UIColor
#elseif os(macOS)
import AppKit
public typealias PlatformImage = NSImage
public typealias PlatformColor = NSColor
#endif

// MARK: - Cross-platform View Extensions
extension View {
    func platformNavigationStyle() -> some View {
        #if os(iOS)
        return self.navigationViewStyle(StackNavigationViewStyle())
        #elseif os(macOS)
        return self
        #endif
    }
    
    func platformListStyle() -> some View {
        #if os(iOS)
        return self.listStyle(InsetGroupedListStyle())
        #elseif os(macOS)
        return self.listStyle(SidebarListStyle())
        #endif
    }
}

// MARK: - Image Data Extensions
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

// MARK: - Phone Call Handling
struct PhoneCallButton: View {
    let phoneNumber: String
    
    var body: some View {
        Button(action: makeCall) {
            Label("Call", systemImage: "phone.fill")
        }
    }
    
    private func makeCall() {
        #if os(iOS)
        if let url = URL(string: "tel://\(phoneNumber)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        #elseif os(macOS)
        // On macOS, we can't make phone calls directly
        // Could open FaceTime or copy number to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(phoneNumber, forType: .string)
        #endif
    }
}