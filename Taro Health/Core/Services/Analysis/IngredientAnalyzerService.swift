

import Foundation
import os

class IngredientAnalyzerService {
    private let userProfile: UserProfile
    private let baseURL = "https://f2ef-50-175-245-62.ngrok-free.app/api"
    private let logger = Logger(subsystem: "com.taro.health", category: "IngredientAnalysis")
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
    }
    
    
    func analyzeIngredients(_ ingredientsText: String) async throws -> IngredientAnalysis {
            // Prepare ingredients text
            let ingredients = ingredientsText
                .lowercased()
                .components(separatedBy: .whitespacesAndNewlines)
                .joined(separator: " ")
        print(ingredients)
            // Create URL and explicitly use self
            guard let url = URL(string: "\(self.baseURL)/analyze-text") else {
                self.logger.error("❌ Invalid URL: \(self.baseURL)/analyze-text")
                throw APIError.invalidURL
            }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userProfile.fullName, forHTTPHeaderField: "X-User-Id")
        
        // Create request body
        let requestBody = ["text": ingredients]
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    let decoder = JSONDecoder()
                    do {
                        let analysisResponse = try decoder.decode(AnalysisResponse.self, from: data)
                        return IngredientAnalysis(
                            status: analysisResponse.status,
                            summary: analysisResponse.summary
                        )
                    } catch {
                        logger.error("❌ Decoding error: \(error.localizedDescription)")
                        throw APIError.decodingError(error)
                    }
                default:
                    throw APIError.serverError(httpResponse.statusCode)
                }
            } catch {
                logger.error("❌ Network error: \(error.localizedDescription)")
                throw APIError.networkError(error)
            }
        }
}

// Add these structures for API interaction
enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case serverError(Int)
    case decodingError(Error)
}

struct AnalysisResponse: Codable {
    let isSafe: Bool
    let healthScore: Int
    let warnings: [String]
    let flaggedIngredients: [String]
    let summary: String
    let status: String
}
