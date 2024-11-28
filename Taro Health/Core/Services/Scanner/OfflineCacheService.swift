import Foundation
import os

// Service to handle caching of blacklist data
class OfflineCacheService {
    private let logger = Logger(subsystem: "com.taro.health", category: "OfflineCache")
    private let cache = UserDefaults.standard
    private let blacklistCacheKey = "cached_blacklist"
    private let lastUpdateKey = "blacklist_last_update"
    
    // Cache the blacklist response
    func cacheBlacklist(_ response: BlacklistResponse) {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(response)
                cache.set(data, forKey: blacklistCacheKey)
                cache.set(Date(), forKey: lastUpdateKey)
                logger.info("✅ Successfully cached blacklist data")
            } catch {
                logger.error("❌ Failed to cache blacklist: \(error.localizedDescription)")
            }
        }
        
        // Retrieve cached blacklist
        func getCachedBlacklist() -> BlacklistResponse? {
            guard let data = cache.data(forKey: blacklistCacheKey) else {
                logger.debug("No cached blacklist found")
                return nil
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(BlacklistResponse.self, from: data)
                logger.info("✅ Successfully retrieved cached blacklist")
                return response
            } catch {
                logger.error("❌ Failed to decode cached blacklist: \(error.localizedDescription)")
                return nil
            }
        }
        
        // Check if cache is valid (not older than 24 hours)
        func isCacheValid() -> Bool {
            guard let lastUpdate = cache.object(forKey: lastUpdateKey) as? Date else {
                return false
            }
            
            let twentyFourHours: TimeInterval = 24 * 60 * 60
            return Date().timeIntervalSince(lastUpdate) < twentyFourHours
        }
}

// Extension to IngredientsAnalyzerService to support offline functionality
extension IngredientAnalyzerService {
    
    func analyzeIngredientsOffline(_ text: String) -> IngredientAnalysis? {
        guard let cachedBlacklist = offlineCache.getCachedBlacklist() else {
            return nil
        }
        
        // Simple offline analysis logic
        let ingredients = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var foundItems: [BlacklistItem] = []
        
        for item in cachedBlacklist.blacklist {
            // Check main item name
            if ingredients.contains(item.item.lowercased()) {
                foundItems.append(item)
                continue
            }
            
            // Check aliases
            for alias in item.alias {
                if ingredients.contains(alias.lowercased()) {
                    foundItems.append(item)
                    break
                }
            }
        }
        
        // Generate analysis result
        if foundItems.isEmpty {
            return IngredientAnalysis(
                status: "okay",
                summary: "Based on cached data, no concerning ingredients were found."
            )
        } else {
            let itemNames = foundItems.map { $0.item }.joined(separator: ", ")
            return IngredientAnalysis(
                status: "warning",
                summary: "Found potentially concerning ingredients: \(itemNames). Note: This is based on cached data and may not be up to date."
            )
        }
    }
}//
//  OfflineCacheService.swift
//  Taro Health
//
//  Created by Neha Suresh on 11/27/24.
//

