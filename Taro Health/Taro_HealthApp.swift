import SwiftUI

@main
struct Taro_HealthApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    ContentView()
                } else if authViewModel.skipToProfile {
                    ContentView() // Ensure this file is in your project
                } else {
                    LoginView()
                }
            }
            .onOpenURL { url in
                Task {
                    do {
                        let session = try await AuthService.shared.handleAuthCallback(url: url)
                        await MainActor.run {
                            authViewModel.handleSuccessfulAuth(session: session)
                        }
                    } catch {
                        await MainActor.run {
                            authViewModel.handleAuthError(error)
                        }
                    }
                }
            }
            .environmentObject(authViewModel)
        }
    }
}
