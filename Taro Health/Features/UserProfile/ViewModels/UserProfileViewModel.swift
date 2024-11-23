import Foundation
import SwiftUI

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let storageService: StorageService
    
    init(storageService: StorageService = StorageService.shared) {
        self.storageService = storageService
    }
    
    func saveProfile(_ profile: UserProfile) {
        isLoading = true
        
        storageService.save(profile, forKey: "userProfile") { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                switch result {
                case .success:
                    self?.userProfile = profile
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func loadProfile() {
        isLoading = true
        
        storageService.load(forKey: "userProfile", as: UserProfile.self) { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                switch result {
                case .success(let profile):
                    self?.userProfile = profile
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}