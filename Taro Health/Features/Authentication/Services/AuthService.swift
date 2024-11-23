import Foundation
import UIKit

protocol AuthServiceProtocol {
    func initiateGoogleSignIn() async throws -> URL
    func handleAuthCallback(url: URL) async throws -> UserSession
}

class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    private init() {}
    
    func initiateGoogleSignIn() async throws -> URL {
        guard let url = URL(string: "https://f2ef-50-175-245-62.ngrok-free.app/auth/google-signin") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.invalidResponse
        }
        
        let signInResponse = try JSONDecoder().decode(GoogleSignInResponse.self, from: data)
        guard let signInURL = URL(string: signInResponse.url) else {
            throw AuthError.invalidURL
        }
        
        return signInURL
    }
    
    func handleAuthCallback(url: URL) async throws -> UserSession {
        // Implement callback handling based on your Supabase setup
        // This is a placeholder implementation
        return UserSession(accessToken: "token", userId: "userId")
    }
}
