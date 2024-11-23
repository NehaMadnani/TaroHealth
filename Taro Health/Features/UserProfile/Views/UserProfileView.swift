//import SwiftUI
//
//struct AlertItem: Identifiable {
//    let id = UUID()
//    let title: String
//    let message: String
//    let dismissButton: Alert.Button
//}
//
//struct UserProfileView: View {
//    @StateObject private var viewModel = UserProfileViewModel()
//    @State private var name = ""
//    @State private var age = ""
//    @State private var selectedGender: Gender = .male
//    @State private var selectedHealthGoals: Set<HealthGoal> = []
//    @State private var selectedAllergies: Set<String> = []
//    @State private var medication = ""
//    @State private var selectedBlacklistedItems: Set<String> = []
//    @State private var alertItem: AlertItem?
//    
//    // Callback for navigation
//    var onSaveSuccess: (UserProfile) -> Void
//    
//    // MARK: - Initialization
//    init(onSaveSuccess: @escaping (UserProfile) -> Void) {
//        self.onSaveSuccess = onSaveSuccess
//    }
//    
//    private let allergiesList = ["Peanuts", "Gluten", "Dairy", "Shellfish"]
//    private let blacklistedItems = ["Sugar", "Processed Foods", "Soda", "Alcohol"]
//    
//    var body: some View {
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                // Profile Header
//                ProfileHeaderView()
//                
//                // User Details Section
//                GroupBox(label: Text("User Details").bold()) {
//                    VStack(alignment: .leading, spacing: 15) {
//                        TextField("Enter your full name", text: $name)
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                        
//                        TextField("Age", text: $age)
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                            .keyboardType(.numberPad)
//                        
//                        // Gender Selection
//                        Picker("Gender", selection: $selectedGender) {
//                            Text("Male").tag(Gender.male)
//                            Text("Female").tag(Gender.female)
//                            Text("Other").tag(Gender.other)
//                        }
//                        .pickerStyle(SegmentedPickerStyle())
//                    }
//                }
//                
//                // Health Goals Section
//                GroupBox(label: Text("Health Goals").bold()) {
//                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 10) { // Changed to single column
//                        ForEach(Array(HealthGoal.allCases), id: \.self) { goal in
//                            ToggleButton(
//                                title: goal.rawValue,
//                                isSelected: selectedHealthGoals.contains(goal),
//                                action: {
//                                    if selectedHealthGoals.contains(goal) {
//                                        selectedHealthGoals.remove(goal)
//                                    } else {
//                                        selectedHealthGoals.insert(goal)
//                                    }
//                                }
//                            )
//                        }
//                    }
//                }
//                
//                // Allergies Section
//                GroupBox(label: Text("Allergies").bold()) {
//                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
//                        ForEach(allergiesList, id: \.self) { allergy in
//                            ToggleButton(
//                                title: allergy,
//                                isSelected: selectedAllergies.contains(allergy),
//                                action: {
//                                    if selectedAllergies.contains(allergy) {
//                                        selectedAllergies.remove(allergy)
//                                    } else {
//                                        selectedAllergies.insert(allergy)
//                                    }
//                                }
//                            )
//                        }
//                    }
//                }
//                
//                // Current Medication
//                    GroupBox(label: Text("Current Medication").bold()) {
//                                        TextField("Enter medications (comma separated)", text: $medication)
//                                            .textFieldStyle(.roundedBorder)
//                                            .frame(maxWidth: .infinity)
//                                            .padding(.vertical, 8)
//                                    }
//                
//                // Blacklisted Items
//                GroupBox(label: Text("Blacklisted Items").bold()) {
//                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
//                        ForEach(blacklistedItems, id: \.self) { item in
//                            ToggleButton(
//                                title: item,
//                                isSelected: selectedBlacklistedItems.contains(item),
//                                action: {
//                                    if selectedBlacklistedItems.contains(item) {
//                                        selectedBlacklistedItems.remove(item)
//                                    } else {
//                                        selectedBlacklistedItems.insert(item)
//                                    }
//                                }
//                            )
//                        }
//                    }
//                }
//                
//                    Button(action: saveProfile) {
//                                        if viewModel.isLoading {
//                                            ProgressView()
//                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
//                                        } else {
//                                            Text("Save & Continue to Scanner")
//                                                .bold()
//                                                .frame(maxWidth: .infinity)
//                                        }
//                                    }
//                                    .frame(maxWidth: .infinity)
//                                    .padding()
//                                    .background(Color.green)
//                                    .foregroundColor(.white)
//                                    .cornerRadius(10)
//                                }
//                                .padding()
//                                // Add bottom padding to avoid keyboard overlap
//                                .padding(.bottom, 50)
//                            }
//                            // Dismiss keyboard when tapping outside
//                            .onTapGesture {
//                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//                            }
//                            .navigationTitle("Health & Lifestyle")
//                            .alert(item: $alertItem) { alertItem in
//                                Alert(
//                                    title: Text(alertItem.title),
//                                    message: Text(alertItem.message),
//                                    dismissButton: alertItem.dismissButton
//                                )
//                            }
//                        }
//       
//    
//    private func saveProfile() {
//        // Basic validation
//        guard !name.isEmpty else {
//            alertItem = AlertItem(
//                title: "Invalid Input",
//                message: "Please enter your name",
//                dismissButton: .default(Text("OK"))
//            )
//            return
//        }
//        
//        guard let ageInt = Int(age), ageInt > 0 else {
//            alertItem = AlertItem(
//                title: "Invalid Input",
//                message: "Please enter a valid age",
//                dismissButton: .default(Text("OK"))
//            )
//            return
//        }
//        
//        // Create profile
//        let profile = UserProfile(
//            fullName: name,
//            username: "@\(name.lowercased().replacingOccurrences(of: " ", with: ""))",
//            age: ageInt,
//            gender: selectedGender,
//            healthGoals: selectedHealthGoals,
//            allergies: selectedAllergies,
//            currentMedications: medication.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
//            blacklistedItems: selectedBlacklistedItems
//        )
//        
//        print("Enters here");
//        
//        // Mock successful save and navigate
//        onSaveSuccess(profile)
//    }
//}
//
//// Helper Views
//struct ToggleButton: View {
//    let title: String
//    let isSelected: Bool
//    let action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            Text(title)
//                .frame(maxWidth: .infinity)
//                .padding(.vertical, 8)
//                .background(isSelected ? Color.green : Color.gray.opacity(0.3))
//                .foregroundColor(isSelected ? .white : .primary)
//                .cornerRadius(8)
//        }
//    }
//}
//
//struct ProfileHeaderView: View {
//    var body: some View {
//        HStack {
//            Image(systemName: "person.circle.fill")
//                .resizable()
//                .frame(width: 80, height: 80)
//                .foregroundColor(.gray)
//            
//            VStack(alignment: .leading) {
//                Text("Create Profile")
//                    .font(.title2)
//                    .bold()
//                Text("Enter your details below")
//                    .foregroundColor(.gray)
//            }
//            .padding(.leading)
//        }
//    }
//}
//
//#Preview {
//    UserProfileView { _ in
//        // Preview doesn't need to do anything with the profile
//    }
//}
