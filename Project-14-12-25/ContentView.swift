import SwiftUI

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var persistenceController = PersistenceController.shared
    
    @State private var showSplash = true
    @State private var showError = false
    
    @State private var remoteUrlString: String?
    @State private var urlFetchStatus: UrlFetchStatus = .pending
    @State private var navigationState: AppNavigationState = .initialScreen
    
    
    var body: some View {
        Group {
            
            ZStack {
                switch navigationState {
                case .initialScreen:
                    SplashScreen()
                    
                case .primaryInterface:
                    MainTabView()
                    
                case .browserContent(let urlString):
                    if let validUrl = URL(string: urlString) {
                        WebContentView(targetUrl: validUrl.absoluteString)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                            .ignoresSafeArea(.all, edges: .bottom)
                    } else {
                        Text("Invalid URL")
                    }
                    
                case .failureMessage(let errorMessage):
                    VStack(spacing: 20) {
                        Text("Error")
                            .font(.title)
                            .foregroundColor(.red)
                        Text(errorMessage)
                        Button("Retry") {
                            Task { await loadRemoteConfiguration() }
                        }
                    }
                    .padding()
                }
            }
            .task {
                await loadRemoteConfiguration()
            }
            .onChange(of: urlFetchStatus, initial: true) { oldValue, newValue in
                if case .completed = newValue, let url = remoteUrlString, !url.isEmpty {
                    Task {
                        await validateAndNavigateToUrl(targetUrl: url)
                    }
                }
            }
            
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
    
    
    private func loadRemoteConfiguration() async {
        await MainActor.run { navigationState = .initialScreen }
        
        let (url, state) = await RemoteUrlProvider.shared.fetchRemoteUrl()
        print("URL: \(url)")
        print("State: \(state)")
        
        await MainActor.run {
            self.remoteUrlString = url
            self.urlFetchStatus = state
        }
        
        if url == nil || url?.isEmpty == true {
            navigateToPrimaryInterface()
        }
    }
    
    private func navigateToPrimaryInterface() {
        withAnimation {
            navigationState = .primaryInterface
        }
    }
    
    private func validateAndNavigateToUrl(targetUrl: String) async {
        guard let url = URL(string: targetUrl) else {
            navigateToPrimaryInterface()
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "HEAD"
        urlRequest.timeoutInterval = 10
        
        do {
            let (_, httpResponse) = try await URLSession.shared.data(for: urlRequest)
            
            if let response = httpResponse as? HTTPURLResponse,
               (200...299).contains(response.statusCode) {
                await MainActor.run {
                    navigationState = .browserContent(targetUrl)
                }
            } else {
                navigateToPrimaryInterface()
            }
        } catch {
            navigateToPrimaryInterface()
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
