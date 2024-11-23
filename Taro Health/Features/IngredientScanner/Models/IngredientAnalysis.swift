import Foundation

// Core analysis model
struct IngredientAnalysis: Identifiable {
    let id = UUID()
    let status: String
    let summary: String
    let scannedDate: Date = Date()
    
    // Helper method to format status for display
    var displayStatus: String {
        "Taro says \(status)"
    }
    
    // Helper method to format date
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
