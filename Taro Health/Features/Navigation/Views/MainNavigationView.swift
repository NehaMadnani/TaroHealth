import SwiftUI

/// Represents the main navigation paths in the app
enum NavigationPath {
    case userProfile
    case ingredientScanner
}

/// MainNavigationView coordinates navigation between different screens in the app
struct MainNavigationView: View {
    // MARK: - Properties
    @State private var selectedPath: NavigationPath = .userProfile
    @State private var userProfile: UserProfile?
    @StateObject private var authViewModel = AuthViewModel()

    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Group {
                       if authViewModel.isAuthenticated {
                           // Your existing main app navigation
                       } else {
                           LoginView()
                       }
                   }
            VStack {
                switch selectedPath {
                case .userProfile:
                    MultiStepUserProfileView { profile in
                        // Handle the completed profile
                        // e.g., save to storage and navigate to scanner
                    }
                    
                case .ingredientScanner:
                    if let profile = userProfile {
                        VStack {
                            // Back button
                            HStack {
                                Button(action: handleBackToProfile) {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                        Text("Back to Profile")
                                    }
                                }
                                Spacer()
                            }
                            .padding()
                            
                            ScannerView(userProfile: profile)
                        }
                    } else {
                        Text("Please complete your profile first")
                            .onAppear {
                                selectedPath = .userProfile
                            }
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }
    
    // MARK: - Private Methods
    private func handleProfileSave(_ profile: UserProfile) {
        print ("Saving profile: \(profile)")
        self.userProfile = profile
        withAnimation {
            self.selectedPath = .ingredientScanner
        }
    }
    
    private func handleBackToProfile() {
        withAnimation {
            selectedPath = .userProfile
        }
    }
}

// MARK: - Preview
#Preview {
    MainNavigationView()
}
