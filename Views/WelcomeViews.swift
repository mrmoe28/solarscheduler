import SwiftUI

// MARK: - Welcome View
struct WelcomeView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.1),
                        Color.blue.opacity(0.05),
                        Color.green.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Skip button
                    HStack {
                        Spacer()
                        Button("Skip") {
                            hasCompletedOnboarding = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                    }
                    
                    // Content
                    TabView(selection: $currentPage) {
                        WelcomePageView(
                            title: "Welcome to Solar Scheduler",
                            subtitle: "Streamline your solar business operations with our comprehensive management platform",
                            imageName: "sun.max.fill",
                            backgroundColor: .orange,
                            features: [
                                "Manage installations and projects",
                                "Track customer relationships",
                                "Schedule site visits and work"
                            ]
                        )
                        .tag(0)
                        
                        WelcomePageView(
                            title: "Powerful Dashboard",
                            subtitle: "Get real-time insights into your business performance and project pipeline",
                            imageName: "chart.bar.xaxis",
                            backgroundColor: .blue,
                            features: [
                                "Track revenue and goals",
                                "Monitor installation progress",
                                "View recent activity feed"
                            ]
                        )
                        .tag(1)
                        
                        WelcomePageView(
                            title: "Smart Scheduling",
                            subtitle: "Efficiently manage installations, site visits, and team schedules in one place",
                            imageName: "calendar.badge.plus",
                            backgroundColor: .green,
                            features: [
                                "Interactive calendar view",
                                "Color-coded job status",
                                "Easy installation scheduling"
                            ]
                        )
                        .tag(2)
                        
                        WelcomePageView(
                            title: "Customer CRM",
                            subtitle: "Track leads, prospects, and customers throughout your entire sales pipeline",
                            imageName: "person.2.fill",
                            backgroundColor: .purple,
                            features: [
                                "Lead management system",
                                "Project value tracking",
                                "Communication history"
                            ]
                        )
                        .tag(3)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Page indicators and controls
                    VStack(spacing: 24) {
                        // Page indicators
                        HStack(spacing: 8) {
                            ForEach(0..<4, id: \.self) { index in
                                Circle()
                                    .fill(currentPage == index ? Color.orange : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                            }
                        }
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            if currentPage < 3 {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        currentPage += 1
                                    }
                                } label: {
                                    Text("Continue")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.orange)
                                        )
                                }
                                .padding(.horizontal, 20)
                                
                                if currentPage > 0 {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            currentPage -= 1
                                        }
                                    } label: {
                                        Text("Back")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            } else {
                                // Final page - Get Started button
                                Button {
                                    withAnimation(.easeInOut(duration: 0.8)) {
                                        hasCompletedOnboarding = true
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("Get Started")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                                }
                                .padding(.horizontal, 20)
                                .scaleEffect(1.02)
                                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Welcome Page View
struct WelcomePageView: View {
    let title: String
    let subtitle: String
    let imageName: String
    let backgroundColor: Color
    let features: [String]
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Main illustration
            VStack(spacing: 24) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(backgroundColor.opacity(0.1))
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .fill(backgroundColor.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    // Icon
                    Image(systemName: imageName)
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(backgroundColor)
                }
                .scaleEffect(1.1)
            }
            
            // Text content
            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Text(subtitle)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 30)
            }
            
            // Features list
            VStack(spacing: 12) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(backgroundColor)
                        
                        Text(feature)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                }
            }
            
            Spacer()
            Spacer()
        }
    }
}