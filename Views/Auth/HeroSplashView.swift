import SwiftUI

struct HeroSplashView: View {
    @State private var isActive = false
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                AnimatedSplashView(isComplete: $isActive)
                    .transition(.opacity)
            } else {
                RootView()
                    .transition(.opacity)
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}

struct AnimatedSplashView: View {
    @State private var isAnimating = false
    @State private var showLogo = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showRays = false
    @State private var sunRotation = 0.0
    @State private var rayOpacity = 0.0
    @State private var particlesVisible = false
    @Binding var isComplete: Bool
    
    // Colors
    let sunGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.8, blue: 0.2),
            Color(red: 1.0, green: 0.6, blue: 0.1),
            Color(red: 1.0, green: 0.4, blue: 0.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.1, green: 0.1, blue: 0.2),
            Color(red: 0.2, green: 0.1, blue: 0.3),
            Color(red: 0.3, green: 0.2, blue: 0.4)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
                .ignoresSafeArea()
                .overlay(
                    // Animated particles
                    GeometryReader { geometry in
                        ForEach(0..<20, id: \.self) { index in
                            Circle()
                                .fill(Color.yellow.opacity(0.3))
                                .frame(width: CGFloat.random(in: 2...6))
                                .position(
                                    x: CGFloat.random(in: 0...geometry.size.width),
                                    y: CGFloat.random(in: 0...geometry.size.height)
                                )
                                .opacity(particlesVisible ? 1 : 0)
                                .animation(
                                    Animation.easeIn(duration: 2)
                                        .delay(Double(index) * 0.1)
                                        .repeatForever(autoreverses: true),
                                    value: particlesVisible
                                )
                        }
                    }
                )
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated Sun Logo
                ZStack {
                    // Sun rays
                    ForEach(0..<12, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(sunGradient)
                            .frame(width: 4, height: 20)
                            .offset(y: -70)
                            .rotationEffect(.degrees(Double(index) * 30))
                            .scaleEffect(showRays ? 1 : 0.3)
                            .opacity(showRays ? rayOpacity : 0)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.05),
                                value: showRays
                            )
                    }
                    
                    // Main sun circle
                    Circle()
                        .fill(sunGradient)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.8), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: .orange.opacity(0.6), radius: 20, x: 0, y: 0)
                        .scaleEffect(showLogo ? 1 : 0)
                        .rotationEffect(.degrees(sunRotation))
                }
                .frame(height: 150)
                
                // Title and Subtitle
                VStack(spacing: 16) {
                    Text("Solar Scheduler")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 0.9, green: 0.9, blue: 1.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .scaleEffect(showTitle ? 1 : 0.8)
                        .opacity(showTitle ? 1 : 0)
                    
                    Text("Powering Your Solar Business")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .scaleEffect(showSubtitle ? 1 : 0.8)
                        .opacity(showSubtitle ? 1 : 0)
                }
                
                Spacer()
                
                // Loading indicator
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 10, height: 10)
                            .scaleEffect(isAnimating ? 1.2 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Logo animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            showLogo = true
        }
        
        // Sun rotation
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            sunRotation = 360
        }
        
        // Rays animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showRays = true
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                rayOpacity = 1
            }
        }
        
        // Title animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showTitle = true
            }
        }
        
        // Subtitle animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showSubtitle = true
            }
        }
        
        // Loading dots
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isAnimating = true
        }
        
        // Particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            particlesVisible = true
        }
        
        // Complete splash after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                isComplete = true
            }
        }
    }
}

#Preview {
    HeroSplashView()
}