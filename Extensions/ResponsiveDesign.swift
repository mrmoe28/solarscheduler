import SwiftUI

// MARK: - Device Type Detection
enum DeviceType {
    case iPhone
    case iPad
    case mac
    
    static var current: DeviceType {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
        #elseif os(macOS)
        return .mac
        #endif
    }
}

// MARK: - Size Classes
enum SizeClass {
    case compact
    case regular
    case large
    
    static func horizontal(_ sizeClass: UserInterfaceSizeClass?) -> SizeClass {
        #if os(iOS)
        switch sizeClass {
        case .compact:
            return .compact
        case .regular:
            return .regular
        case .none:
            return .regular
        @unknown default:
            return .regular
        }
        #else
        return .large
        #endif
    }
}

// MARK: - Responsive Values
struct ResponsiveValue<T> {
    let compact: T
    let regular: T
    let large: T
    
    func value(for sizeClass: SizeClass) -> T {
        switch sizeClass {
        case .compact:
            return compact
        case .regular:
            return regular
        case .large:
            return large
        }
    }
}

// MARK: - View Extensions for Responsive Design
extension View {
    func responsive<T>(_ keyPath: WritableKeyPath<Self, T>, 
                      compact: T, 
                      regular: T, 
                      large: T) -> some View {
        self.modifier(ResponsiveModifier(
            compact: compact,
            regular: regular,
            large: large,
            keyPath: keyPath
        ))
    }
    
    func adaptiveFont(_ style: Font.TextStyle, sizeModifier: CGFloat = 1.0) -> some View {
        self.modifier(AdaptiveFontModifier(style: style, sizeModifier: sizeModifier))
    }
    
    func adaptivePadding(_ edges: Edge.Set = .all, 
                        compact: CGFloat = 8, 
                        regular: CGFloat = 16, 
                        large: CGFloat = 24) -> some View {
        self.modifier(AdaptivePaddingModifier(
            edges: edges,
            compact: compact,
            regular: regular,
            large: large
        ))
    }
    
    func adaptiveFrame(maxWidth: CGFloat? = nil, 
                      maxHeight: CGFloat? = nil,
                      idealWidth: CGFloat? = nil,
                      idealHeight: CGFloat? = nil) -> some View {
        self.modifier(AdaptiveFrameModifier(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            idealWidth: idealWidth,
            idealHeight: idealHeight
        ))
    }
}

// MARK: - Responsive Modifiers
struct ResponsiveModifier<T>: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    let compact: T
    let regular: T
    let large: T
    let keyPath: WritableKeyPath<AnyView, T>
    
    func body(content: Content) -> some View {
        let sizeClass = SizeClass.horizontal(horizontalSizeClass)
        let value = ResponsiveValue(compact: compact, regular: regular, large: large)
            .value(for: sizeClass)
        
        return content
    }
}

struct AdaptiveFontModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let style: Font.TextStyle
    let sizeModifier: CGFloat
    
    func body(content: Content) -> some View {
        content.font(.system(style, design: .default))
            .scaleEffect(scaleFactor)
    }
    
    private var scaleFactor: CGFloat {
        let baseScale: CGFloat
        
        switch DeviceType.current {
        case .iPhone:
            baseScale = 1.0
        case .iPad:
            baseScale = 1.1
        case .mac:
            baseScale = 1.0
        }
        
        return baseScale * sizeModifier
    }
}

struct AdaptivePaddingModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    let edges: Edge.Set
    let compact: CGFloat
    let regular: CGFloat
    let large: CGFloat
    
    func body(content: Content) -> some View {
        let sizeClass = SizeClass.horizontal(horizontalSizeClass)
        let padding = ResponsiveValue(compact: compact, regular: regular, large: large)
            .value(for: sizeClass)
        
        return content.padding(edges, padding)
    }
}

struct AdaptiveFrameModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    let maxWidth: CGFloat?
    let maxHeight: CGFloat?
    let idealWidth: CGFloat?
    let idealHeight: CGFloat?
    
    func body(content: Content) -> some View {
        Group {
            switch DeviceType.current {
            case .iPhone:
                content
                    .frame(maxWidth: .infinity, maxHeight: maxHeight)
            case .iPad:
                content
                    .frame(maxWidth: maxWidth ?? 800, maxHeight: maxHeight)
                    .frame(idealWidth: idealWidth ?? 600, idealHeight: idealHeight)
            case .mac:
                content
                    .frame(minWidth: 300, idealWidth: idealWidth ?? 800, maxWidth: maxWidth ?? .infinity,
                           minHeight: 200, idealHeight: idealHeight ?? 600, maxHeight: maxHeight ?? .infinity)
            }
        }
    }
}

// MARK: - Adaptive Grid
struct AdaptiveGrid<Content: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var columns: [GridItem] {
        switch DeviceType.current {
        case .iPhone:
            return [GridItem(.flexible())]
        case .iPad:
            if horizontalSizeClass == .regular {
                return Array(repeating: GridItem(.flexible()), count: 2)
            } else {
                return [GridItem(.flexible())]
            }
        case .mac:
            return Array(repeating: GridItem(.flexible()), count: 3)
        }
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            content
        }
    }
}

// MARK: - Navigation Style
extension View {
    func adaptiveNavigationStyle() -> some View {
        Group {
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                self.navigationViewStyle(DoubleColumnNavigationViewStyle())
            } else {
                self.navigationViewStyle(StackNavigationViewStyle())
            }
            #else
            self
            #endif
        }
    }
}

// MARK: - Screen Size Helpers
struct ScreenSize {
    static var width: CGFloat {
        #if os(iOS)
        return UIScreen.main.bounds.width
        #elseif os(macOS)
        return NSScreen.main?.frame.width ?? 1200
        #endif
    }
    
    static var height: CGFloat {
        #if os(iOS)
        return UIScreen.main.bounds.height
        #elseif os(macOS)
        return NSScreen.main?.frame.height ?? 800
        #endif
    }
    
    static var isCompact: Bool {
        width < 600
    }
    
    static var isRegular: Bool {
        width >= 600 && width < 1000
    }
    
    static var isLarge: Bool {
        width >= 1000
    }
}