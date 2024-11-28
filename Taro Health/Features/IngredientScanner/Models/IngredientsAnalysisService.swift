import Foundation
import SwiftUI
import os // For logging

class IngredientsAnalysisService {
    private let baseURL = "https://f2ef-50-175-245-62.ngrok-free.app/api"
    private let logger = Logger(subsystem: "com.taro.health", category: "IngredientAnalysis")
    private let offlineCache = OfflineCacheService() // Add the property here in main class

    
    enum APIError: Error {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case serverError(Int)
        case decodingError(Error)
    }
    
    struct AnalysisRequest: Encodable {
        let dietary: [String]
        let health: [String]
        let allergies: [String]
    }
    
    func fetchIngredientsToAvoid(
        dietary: Set<String>,
        health: Set<HealthGoal>,
        allergies: Set<String>,
        name: String
    ) async throws -> BlacklistResponse {
        let offlineCache = OfflineCacheService()
        
        guard let url = URL(string: "\(baseURL)/analyze") else {
            logger.error("❌ Invalid URL: \(self.baseURL)/analyze")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        print(name)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(name, forHTTPHeaderField: "X-User-Id")
        request.timeoutInterval = 30 // 30 seconds timeout
        
        let healthStrings = health.map { $0.rawValue }
        let analysisRequest = AnalysisRequest(
            dietary: Array(dietary),
            health: healthStrings,
            allergies: Array(allergies)
        )
        
        // Log request
        logger.debug("📤 Request URL: \(url.absoluteString)")
        logger.debug("📤 Request Body: \(String(describing: analysisRequest))")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(analysisRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Log raw response
            if let responseString = String(data: data, encoding: .utf8) {
                logger.debug("📥 Raw Response: \(responseString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("❌ Invalid response type")
                throw APIError.invalidResponse
            }
            
            // Log response status
            logger.debug("📥 Response Status Code: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                do {
                    let response = try decoder.decode(BlacklistResponse.self, from: data)
                    logger.info("✅ Successfully decoded response with \(response.blacklist.count) items")
                    
                    // Cache successful response
                    offlineCache.cacheBlacklist(response)
                    logger.info("✅ Successfully cached blacklist data for offline use")
                    
                    return response
                } catch {
                    logger.error("❌ Decoding error: \(error.localizedDescription)")
                    throw APIError.decodingError(error)
                }
            case 400:
                logger.error("❌ Bad request - Status: \(httpResponse.statusCode)")
                throw APIError.serverError(httpResponse.statusCode)
            case 401:
                logger.error("❌ Unauthorized - Status: \(httpResponse.statusCode)")
                throw APIError.serverError(httpResponse.statusCode)
            case 404:
                logger.error("❌ Not found - Status: \(httpResponse.statusCode)")
                throw APIError.serverError(httpResponse.statusCode)
            case 500...599:
                logger.error("❌ Server error - Status: \(httpResponse.statusCode)")
                throw APIError.serverError(httpResponse.statusCode)
            default:
                logger.error("❌ Unexpected status code: \(httpResponse.statusCode)")
                throw APIError.serverError(httpResponse.statusCode)
            }
        } catch let error as URLError where error.code == .notConnectedToInternet {
            logger.warning("⚠️ No internet connection, attempting to use cached data")
            
            // Try to use cached data if available
            if let cachedResponse = offlineCache.getCachedBlacklist() {
                if offlineCache.isCacheValid() {
                    logger.info("✅ Successfully retrieved valid cached blacklist data")
                    return cachedResponse
                } else {
                    logger.warning("⚠️ Cached data is outdated")
                    throw APIError.networkError(error)
                }
            } else {
                logger.error("❌ No cached data available")
                throw APIError.networkError(error)
            }
        } catch {
            logger.error("❌ Network error: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
}
