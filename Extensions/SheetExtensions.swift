import SwiftUI

extension View {
    /// Applies platform-specific sheet sizing
    func platformSheet<Item, Content>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View where Item: Identifiable, Content: View {
        #if os(iOS)
        return self.sheet(item: item, onDismiss: onDismiss, content: content)
        #elseif os(macOS)
        return self.sheet(item: item, onDismiss: onDismiss) { item in
            content(item)
                .frame(minWidth: 600, idealWidth: 800, minHeight: 400, idealHeight: 600)
        }
        #endif
    }
    
    /// Applies platform-specific sheet sizing for boolean presentation
    func platformSheet<Content>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Content: View {
        #if os(iOS)
        return self.sheet(isPresented: isPresented, onDismiss: onDismiss, content: content)
        #elseif os(macOS)
        return self.sheet(isPresented: isPresented, onDismiss: onDismiss) {
            content()
                .frame(minWidth: 600, idealWidth: 800, minHeight: 400, idealHeight: 600)
        }
        #endif
    }
}

// MARK: - Form Sheet Sizes
struct SheetSize {
    #if os(macOS)
    static let small = CGSize(width: 500, height: 400)
    static let medium = CGSize(width: 700, height: 500)
    static let large = CGSize(width: 900, height: 700)
    #endif
}

// MARK: - Platform Navigation
extension View {
    func platformNavigationBarTitle(_ title: String) -> some View {
        #if os(iOS)
        return self.navigationBarTitle(title)
        #elseif os(macOS)
        return self.navigationTitle(title)
        #endif
    }
}