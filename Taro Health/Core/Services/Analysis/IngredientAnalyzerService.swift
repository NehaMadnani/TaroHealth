import Foundation

struct IngredientAnalysis: Equatable {
    let isSafe: Bool
    let healthScore: Int
    let warnings: [String]
    let flaggedIngredients: [String]
    
    static func == (lhs: IngredientAnalysis, rhs: IngredientAnalysis) -> Bool {
        lhs.isSafe == rhs.isSafe &&
        lhs.healthScore == rhs.healthScore &&
        lhs.warnings == rhs.warnings &&
        lhs.flaggedIngredients == rhs.flaggedIngredients
    }
}

// Analysis Result Type
enum AnalysisResult {
    case safe
    case warning(String)
    case danger(String)
    
    var message: String {
        switch self {
        case .safe:
            return "Safe to consume"
        case .warning(let message), .danger(let message):
            return message
        }
    }
    
    var icon: String {
        switch self {
        case .safe:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .danger:
            return "xmark.circle.fill"
        }
    }
}
