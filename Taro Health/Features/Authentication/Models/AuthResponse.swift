import Foundation

struct GoogleSignInResponse: Codable {
    let url: String
}

struct UserSession: Codable {
    let accessToken: String
    let userId: String
}
