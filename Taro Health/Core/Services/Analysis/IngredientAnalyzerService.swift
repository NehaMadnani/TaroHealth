import Foundation

class IngredientAnalyzerService {
    private let userProfile: UserProfile
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
    }
    
    func analyzeIngredients(_ ingredientsText: String) -> IngredientAnalysis {
        
        let ingredients = ingredientsText
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .joined(separator: " ")
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        print(ingredients)
        var warnings: [String] = []
        var flaggedIngredients: [String] = []
        
        // Check allergies
        for allergy in userProfile.allergies {
            if ingredients.contains(where: { $0.contains(allergy.lowercased()) }) {
                warnings.append("Contains \(allergy) - Listed in your allergies")
                flaggedIngredients.append(allergy)
            }
        }
        
        // Check blacklisted items
        for item in userProfile.blacklistedItems {
            if ingredients.contains(where: { $0.contains(item.lowercased()) }) {
                warnings.append("Contains \(item) - Listed in your blacklist")
                flaggedIngredients.append(item)
            }
        }
        
        // Calculate health score (1-10)
        let healthScore = calculateHealthScore(ingredients: ingredients)
        
        return IngredientAnalysis(
            isSafe: warnings.isEmpty,
            healthScore: healthScore,
            warnings: warnings,
            flaggedIngredients: flaggedIngredients
        )
    }
    
    private func calculateHealthScore(ingredients: [String]) -> Int {
        var score = 10
        
        // Common unhealthy ingredients
        let unhealthyIngredients = [
            "sugar", "corn syrup", "artificial", "preservative",
            "msg", "hydrogenated", "food coloring", "sodium"
        ]
        
        // Healthy ingredients
        let healthyIngredients = [
            "vitamin", "fiber", "protein", "omega",
            "natural", "organic", "whole grain"
        ]
        
        // Deduct points for unhealthy ingredients
        for ingredient in unhealthyIngredients {
            if ingredients.contains(where: { $0.contains(ingredient) }) {
                score -= 1
            }
        }
        
        // Add points for healthy ingredients
        for ingredient in healthyIngredients {
            if ingredients.contains(where: { $0.contains(ingredient) }) {
                score += 1
            }
        }
        
        // Ensure score stays within 1-10 range
        return min(max(score, 1), 10)
    }
}
