
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
        // Log the input text
        print("🔍 Input text to analyze: \(ingredientsText)")
        
        let ingredients = ingredientsText
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .joined(separator: " ")
            
        print("📝 Processed ingredients text: \(ingredients)")
        
        guard let url = URL(string: "\(self.baseURL)/analyze-text") else {
            print("❌ Invalid URL: \(self.baseURL)/analyze-text")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userProfile.fullName, forHTTPHeaderField: "X-User-Id")
        
        // Create and log request body
        let requestBody = ["text": ingredients]
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // Log the complete request details
        print("\n📡 API Request Details:")
        print("URL: \(url.absoluteString)")
        print("Method: \(request.httpMethod ?? "Unknown")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Log the response
            print("\n📥 API Response:")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response Data: \(responseString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("Status Code: \(httpResponse.statusCode)")
            
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
                    print("❌ Decoding error: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw response that failed to decode: \(responseString)")
                    }
                    throw APIError.decodingError(error)
                }
            default:
                throw APIError.serverError(httpResponse.statusCode)
            }
        } catch {
            print("❌ Network error: \(error)")
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
    let summary: String
    let status: String
}
