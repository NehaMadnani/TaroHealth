import Foundation
import os

class IngredientAnalyzerService {
    private let userProfile: UserProfile
    private let baseURL = "https://f2ef-50-175-245-62.ngrok-free.app/api"
    private let logger = Logger(subsystem: "com.taro.health", category: "IngredientAnalysis")
    public let offlineCache = OfflineCacheService() // Move it here as a stored property
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
    }
    
    func analyzeIngredients(_ input: Any) async throws -> IngredientAnalysis {
        if let textInput = input as? String {
            do {
                return try await analyzeText(textInput)
            } catch let error as URLError where error.code == .notConnectedToInternet {
                if let offlineAnalysis = analyzeIngredientsOffline(textInput) {
                    logger.info("✅ Successfully performed offline analysis")
                    return offlineAnalysis
                } else {
                    throw APIError.networkError(error)
                }
            } catch {
                throw error
            }
        } else if let requestBody = input as? [String: Any] {
            return try await analyzeImage(requestBody)
        } else {
            throw APIError.invalidInput
        }
    }
    
    private func analyzeText(_ text: String) async throws -> IngredientAnalysis {
        let ingredients = text
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .joined(separator: " ")
        
        guard let url = URL(string: "\(baseURL)/analyze-text") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userProfile.fullName, forHTTPHeaderField: "X-User-Id")
        
        let requestBody = ["text": ingredients]
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        return try await performRequest(request)
    }
    
    private func analyzeImage(_ requestBody: [String: Any]) async throws -> IngredientAnalysis {
        guard let url = URL(string: "\(baseURL)/analyze-text") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userProfile.fullName, forHTTPHeaderField: "X-User-Id")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        return try await performRequest(request)
    }
    
    private func performRequest(_ request: URLRequest) async throws -> IngredientAnalysis {
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
                logger.error("Decoding error: \(error.localizedDescription)")
                throw APIError.decodingError(error)
            }
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}

// Update APIError enum
enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case serverError(Int)
    case decodingError(Error)
    case invalidInput
}

// Keep existing error and response structures

struct AnalysisResponse: Codable {
    let summary: String
    let status: String
}
