import SwiftUI

class ScannerViewModel: ObservableObject {
    @Published var analysisResult: IngredientAnalysis?
    @Published var showingResults = false
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    
    private let analyzer: IngredientAnalyzerService
    
    init(userProfile: UserProfile) {
        self.analyzer = IngredientAnalyzerService(userProfile: userProfile)
    }
    
    func analyzeText(_ text: String) {
        isAnalyzing = true
        
        Task {
            do {
                let result = try await analyzer.analyzeIngredients(text)
                
                await MainActor.run {
                    self.analysisResult = result
                    self.showingResults = true
                    self.isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isAnalyzing = false
                }
            }
        }
    }
}
