import SwiftUI

struct SplashScreen: View {
    @State private var rodOffset: CGFloat = -200
    @State private var waveOpacity: Double = 0
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.5
    @Binding var isComplete: Bool
    
    var body: some View {
        ZStack {
            ThemeManager.waterGradient
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Animated rod
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(45))
                    .offset(x: rodOffset, y: -50)
                    .animation(.easeOut(duration: 1.0), value: rodOffset)
                
                // Wave
                Image(systemName: "water.waves")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.6))
                    .opacity(waveOpacity)
                    .animation(.easeIn(duration: 0.8).delay(0.5), value: waveOpacity)
                
                // Logo and title
                VStack(spacing: 16) {
                    Image(systemName: "fish.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .opacity(logoOpacity)
                        .scaleEffect(logoScale)
                    
                    Text("Angler Finance Tracker")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(logoOpacity)
                }
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(1.2), value: logoOpacity)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Rod animation
        withAnimation {
            rodOffset = 0
        }
        
        // Wave appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            waveOpacity = 1.0
        }
        
        // Logo appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            logoOpacity = 1.0
            logoScale = 1.0
        }
        
        // Complete after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isComplete = true
        }
    }
}

#Preview {
    SplashScreen(isComplete: .constant(false))
}

