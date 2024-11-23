import Foundation

enum Gender: String, Codable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
}

enum HealthGoal: String, Codable, CaseIterable {
    case children = "Be there for your family, for years to come"
    case energy = "Having the energy to pursue your passions"
    case independence = "Maintain independence & freedom as you age"
    case loseWeight = "Eat to reach target weight"
    case buildMuscle = "Nourish and build Muscle"
    case improveStamina = "Improve Stamina"
    case familyHealth = "Improve overall family health"
    case immunity = "Support your immune system"

}

struct UserProfile: Codable {
    var fullName: String
    var username: String
    var age: Int
    var gender: Gender
    var healthGoals: Set<HealthGoal>
    var allergies: Set<String>
    var currentMedications: [String]
    var blacklistedItems: Set<String>
    var profileImageData: Data? // Add this property
    
    var profileImageUrl: URL?
}
