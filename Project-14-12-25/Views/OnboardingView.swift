import SwiftUI

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(
            icon: "fish.fill",
            title: "Fishing is more than a hobby",
            subtitle: "It's an investment of time and money"
        ),
        OnboardingPage(
            icon: "dollarsign.circle.fill",
            title: "Track every dollar",
            subtitle: "Spent and earned on the water"
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "100% private, offline",
            subtitle: "And yours forever"
        )
    ]
    
    var body: some View {
        ZStack {
            ThemeManager.waterGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Bottom buttons
                HStack {
                    if currentPage > 0 {
                        Button("Previous") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    } else {
                        Button("Get Started") {
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                            withAnimation {
                                isComplete = true
                            }
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(ThemeManager.primaryGreen)
                        .cornerRadius(24)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: page.icon)
                .font(.system(size: 100))
                .foregroundColor(.white)
                .symbolEffect(.pulse, options: .repeating)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isComplete: .constant(false))
}

