import Foundation

struct IngredientAnalysis: Identifiable {
    let id = UUID()
    let isSafe: Bool
    let healthScore: Int
    let warnings: [String]
    let flaggedIngredients: [String]
    let scannedDate: Date = Date()
    
    // Computed property for overall safety status text
    var safetyStatus: String {
        isSafe ? "Safe to Consume" : "Use Caution"
    }
    
    // Computed property for health score description
    var healthScoreDescription: String {
        switch healthScore {
        case 9...10:
            return "Excellent"
        case 7...8:
            return "Good"
        case 5...6:
            return "Fair"
        case 3...4:
            return "Poor"
        default:
            return "Concerning"
        }
    }
    
    // Helper method to format scanned date
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: scannedDate)
    }
}

// MARK: - Equatable
extension IngredientAnalysis: Equatable {
    static func == (lhs: IngredientAnalysis, rhs: IngredientAnalysis) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension IngredientAnalysis: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Codable
extension IngredientAnalysis: Codable {
    // Codable conformance is automatic since all properties are Codable
}
