import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false
    @Published var error: AuthError?
    @Published var skipToProfile = false  // Chan
        
    private let authService: AuthServiceProtocol
    
    
    init(authService: AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
    }
    
    func signInWithGoogle() {
        Task {
            isLoading = true
            do {
                let signInURL = try await authService.initiateGoogleSignIn()
                if let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    await UIApplication.shared.open(signInURL, options: [:], completionHandler: nil)
                }
            } catch {
                self.error = error as? AuthError ?? .unknown
            }
            isLoading = false
        }
    }
    
    func handleSuccessfulAuth(session: UserSession) {
        isAuthenticated = true
        // Store session info if needed
    }
    
    func handleAuthError(_ error: Error) {
        self.error = error as? AuthError ?? .unknown
        isAuthenticated = false
    }
    
        
        func skipSignIn() {
            skipToProfile = true
        }
}
