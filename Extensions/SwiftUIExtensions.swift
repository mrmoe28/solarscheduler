import SwiftUI

// MARK: - SwiftUI Extensions for Enhanced UX

extension View {
    /// Adds a subtle bounce animation when the view appears
    func bounceOnAppear(delay: Double = 0) -> some View {
        self
            .scaleEffect(0.8)
            .opacity(0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                    self
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
        .background(Color(UIColor.secondarySystemBackground))
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
                    .fill(Color(UIColor.secondarySystemBackground))
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