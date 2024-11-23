import SwiftUI

class ScannerViewModel: ObservableObject {
    @Published var scannerService: ScannerService
    @Published var analysis: IngredientAnalysis?
    @Published var isAnalyzing = false
    
    let userProfile: UserProfile
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
        self.scannerService = ScannerService()
    }
    
    func analyzeIngredients() {
        isAnalyzing = true
        
        scannerService.captureAndAnalyze { [weak self] recognizedText in
            guard let self = self,
                  let text = recognizedText else {
                self?.isAnalyzing = false
                return
            }
            
            // Process the ingredients text
            self.processIngredients(text)
        }
    }
    
    private func processIngredients(_ text: String) {
        // Split text into individual ingredients
        let ingredients = text
            .components(separatedBy: .init(charactersIn: ",[]()\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Check against user's profile for warnings
        var warnings: [String] = []
        var flaggedIngredients: [String] = []
        
        for ingredient in ingredients {
            // Check allergies
            if userProfile.allergies.contains(where: { ingredient.lowercased().contains($0.lowercased()) }) {
                warnings.append("Contains allergen: \(ingredient)")
                flaggedIngredients.append(ingredient)
            }
            
            // Check blacklisted items
            if userProfile.blacklistedItems.contains(where: { ingredient.lowercased().contains($0.lowercased()) }) {
                warnings.append("Contains restricted item: \(ingredient)")
                flaggedIngredients.append(ingredient)
            }
        }
        
        // Calculate health score (simple example)
        let healthScore = calculateHealthScore(ingredients: ingredients)
        
        // Create analysis result
        let analysis = IngredientAnalysis(
            isSafe: warnings.isEmpty,
            healthScore: healthScore,
            warnings: warnings,
            flaggedIngredients: flaggedIngredients
        )
        
        DispatchQueue.main.async {
            self.analysis = analysis
            self.isAnalyzing = false
        }
    }
    
    private func calculateHealthScore(ingredients: [String]) -> Int {
        // Simple scoring example - you can make this more sophisticated
        let totalIngredients = ingredients.count
        let flaggedCount = ingredients.filter { ingredient in
            userProfile.allergies.contains(where: { ingredient.lowercased().contains($0.lowercased()) }) ||
            userProfile.blacklistedItems.contains(where: { ingredient.lowercased().contains($0.lowercased()) })
        }.count
        
        let score = 10 - (Double(flaggedCount) / Double(totalIngredients) * 10)
        return max(0, min(10, Int(score)))
    }
}
