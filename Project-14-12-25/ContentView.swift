import SwiftUI

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var persistenceController = PersistenceController.shared
    @State private var showSplash = true
    @State private var showOnboarding = false
    
    var body: some View {
        Group {
            if persistenceController.isLoading {
                // Show loading state while Core Data is initializing
                ZStack {
                    ThemeManager.waterGradient
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            } else if persistenceController.hasError {
                // Show error state if Core Data failed to load
                ErrorView(error: persistenceController.lastError) {
                    // Retry option
                    persistenceController.hasError = false
                    // Note: In a real app, you might want to recreate the persistence controller
                }
            } else if showSplash {
                SplashScreen(isComplete: Binding(
                    get: { false },
                    set: { newValue in
                        if newValue {
                            showSplash = false
                            checkOnboardingStatus()
                        }
                    }
                ))
            } else if showOnboarding {
                OnboardingView(isComplete: Binding(
                    get: { false },
                    set: { newValue in
                        if newValue {
                            showOnboarding = false
                        }
                    }
                ))
            } else {
                MainTabView()
            }
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
    
    private func checkOnboardingStatus() {
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            showOnboarding = true
        }
    }
}

struct ErrorView: View {
    let error: PersistenceError?
    let onRetry: () -> Void
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("Data Loading Error")
                    .font(.system(size: 24, weight: .bold))
                
                Text(error?.errorDescription ?? "Unknown error occurred")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Please restart the app. If the problem persists, contact support.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Retry") {
                    onRetry()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
            
            TripsListView()
                .tabItem {
                    Label("Trips", systemImage: "fish.fill")
                }
            
            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            GearCatalogView()
                .tabItem {
                    Label("Gear", systemImage: "cart.fill")
                }
            
            BudgetGoalsView()
                .tabItem {
                    Label("Budget", systemImage: "target")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
