import SwiftUI
import PhotosUI

enum ProfileStep: Int, CaseIterable {
    case basicInfo
    case healthGoals
    case allergies
    case medications
    case blacklistedItems
    case ingredientsToAvoid
    
    var title: String {
        switch self {
        case .basicInfo: return "Basic Information"
        case .healthGoals: return "Health Goals"
        case .allergies: return "Allergies"
        case .medications: return "Medications"
        case .blacklistedItems: return "Dietary Restrictions"
        case .ingredientsToAvoid: return "Ingredients to Avoid"
        }
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let dismissButton: Alert.Button
}

struct BlacklistItem: Codable {
    let item: String
    let alias: [String]
    let cause: String
}

struct BlacklistResponse: Codable {
    let blacklist: [BlacklistItem]
}

// Update the IngredientToAvoid model
struct IngredientToAvoid: Identifiable {
    let id = UUID()
    let name: String
    let reason: String
    let aliases: [String]
    var isSelected: Bool
    var isExpanded: Bool
    var selectedAliases: Set<String>
}

struct AliasPill: View {
    let alias: String
    var isSelected: Bool
    var onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            Text(alias)
                .font(.system(size: 12))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.primaryBlack : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// First, create a new model to hold both title parts
struct IngredientTitle {
    let name: String
    let reason: String
}

// Update ToggleButton to accept this new type
struct ToggleButton: View {
    let title: String? // Keep for backward compatibility
    let ingredientTitle: IngredientTitle?
    let isSelected: Bool
    let action: () -> Void
    
    // Original initializer for other uses
    init(title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.ingredientTitle = nil
        self.isSelected = isSelected
        self.action = action
    }
    
    // New initializer for ingredients
    init(ingredientTitle: IngredientTitle, isSelected: Bool, action: @escaping () -> Void) {
        self.title = nil
        self.ingredientTitle = ingredientTitle
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            if let ingredientTitle = ingredientTitle {
                // Styled ingredient view
                VStack(alignment: .leading, spacing: 4) {
                    Text(ingredientTitle.name)
                        .font(.system(size: 13, weight: .medium))
                    Text(ingredientTitle.reason)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(height: 24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.primaryBlack : Color.gray.opacity(0.3))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
            } else if let title = title {
                // Original single-text view
                Text(title)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isSelected ? Color.primaryBlack : Color.gray.opacity(0.3))
                    .foregroundColor(isSelected ? .white : .primary)
                    .cornerRadius(8)
            }
        }
    }
}
struct MultiStepUserProfileView: View {
    @StateObject private var viewModel = UserProfileViewModel()
    @State private var currentStep: ProfileStep = .basicInfo
    @State private var profileImage: UIImage?
    @State private var isProfileComplete = false
    @State private var alertItem: AlertItem?
    @State private var navigateToScanner = false
    




    
    // Form fields
    @State private var name = ""
    @State private var age = ""
    @State private var selectedGender: Gender = .male
    @State private var selectedHealthGoals: Set<HealthGoal> = []
    @State private var selectedAllergies: Set<String> = []
    @State private var medication = ""
    @State private var selectedBlacklistedItems: Set<String> = []

    // Ingredients to avoid
    @State private var ingredientsToAvoid: [IngredientToAvoid] = []
    @State private var isLoadingIngredients = false
    @State private var selectAllIngredients = true
    
    private let allergiesList = ["Peanuts", "Gluten", "Dairy", "Shellfish"]
    private let blacklistedItems = ["Sugar", "Processed Foods", "Soda", "Alcohol"]
    private let ingredientsService = IngredientsAnalysisService()

    var onSaveSuccess: (UserProfile) -> Void
    
    var body: some View {
        if isProfileComplete, let profile = viewModel.userProfile {
                ProfileSummaryView(userProfile: profile)
                    .interactiveDismissDisabled()  // Prevent dismissal by gesture
            }  else {
            NavigationStack {  // Wrap the main content in NavigationStack
                
                VStack {
                    if currentStep != .ingredientsToAvoid {
                        ProgressView(value: Double(currentStep.rawValue), total: Double(ProfileStep.allCases.count - 2))
                            .padding()
                    }
                    
                    Text(currentStep.title)
                        .font(.title2)
                        .bold()
                        .padding(.bottom)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            switch currentStep {
                            case .basicInfo:
                                basicInfoView
                            case .healthGoals:
                                healthGoalsView
                            case .allergies:
                                allergiesView
                            case .medications:
                                medicationsView
                            case .blacklistedItems:
                                blacklistedItemsView
                            case .ingredientsToAvoid:
                                ingredientsToAvoidView
                            }
                        }
                        .padding()
                    }
                    
                    HStack {
                        if currentStep != .basicInfo {
                            Button(action: previousStep) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Previous")
                                }
                                .frame(maxWidth: 100)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        
                        Button(action: handleNextStep) {
                            HStack {
                                Text(buttonTitle)
                                if !isLastStep {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 10)
                    }
                    .padding()
                    
                }
                .alert(item: $alertItem) { item in
                    Alert(
                        title: Text(item.title),
                        message: Text(item.message),
                        dismissButton: item.dismissButton
                    )
                }
            }
            .navigationDestination(isPresented: $navigateToScanner) {
//                ScannerView()
            }
        }
    }
    private var isLastStep: Bool {
        currentStep == .ingredientsToAvoid
    }
    
    private var buttonTitle: String {
        switch currentStep {
        case .blacklistedItems:
            return "Review Ingredients"
        case .ingredientsToAvoid:
            return "Finish"
        default:
            return "Next"
        }
    }
    
    private var basicInfoView: some View {
            VStack(alignment: .leading, spacing: 15) {
                ProfileImageSelector(profileImage: $profileImage) // Use binding
                    .padding(.bottom)
                
                TextField("Enter your full name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineSpacing(10)
                
                TextField("Age", text: $age)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .lineSpacing(10)

                
                Picker("Gender", selection: $selectedGender) {
                    Text("Male").tag(Gender.male)
                    Text("Female").tag(Gender.female)
                    Text("Other").tag(Gender.other)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.top, 15)
                .frame(height: 50)
                .padding(.vertical, 4)
                .lineSpacing(14)

            }
        }
    
    private var healthGoalsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What matters most to you in life that good health would help you achieve?")  // Added descriptive text
                .font(.body)
                .foregroundColor(.gray)
            
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 14) {
                ForEach(Array(HealthGoal.allCases), id: \.self) { goal in
                    ToggleButton(
                        title: goal.rawValue,
                        isSelected: selectedHealthGoals.contains(goal),
                        action: {
                            if selectedHealthGoals.contains(goal) {
                                selectedHealthGoals.remove(goal)
                            } else {
                                selectedHealthGoals.insert(goal)
                            }
                        }
                    )
                    .padding(.horizontal, 12)  // Add horizontal padding
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var allergiesView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(allergiesList, id: \.self) { allergy in
                ToggleButton(
                    title: allergy,
                    isSelected: selectedAllergies.contains(allergy),
                    action: {
                        if selectedAllergies.contains(allergy) {
                            selectedAllergies.remove(allergy)
                        } else {
                            selectedAllergies.insert(allergy)
                        }
                    }
                )
            }
        }
    }
    
    private var medicationsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("List any current medications")
                .foregroundColor(.gray)
            
            TextField("Enter medications (comma separated)", text: $medication)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
        }
    }
    
    private var blacklistedItemsView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(blacklistedItems, id: \.self) { item in
                ToggleButton(
                    title: item,
                    isSelected: selectedBlacklistedItems.contains(item),
                    action: {
                        if selectedBlacklistedItems.contains(item) {
                            selectedBlacklistedItems.remove(item)
                        } else {
                            selectedBlacklistedItems.insert(item)
                        }
                    }
                )
            }
        }
    }
    
    private var ingredientsToAvoidView: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoadingIngredients {
                ProgressView("Analyzing your profile...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Based on your profile, here are ingredients you should consider avoiding:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Button(action: toggleAllIngredients) {
                        HStack {
                            Text(selectAllIngredients ? "Unselect All" : "Select All")
                                .foregroundColor(.primaryBlack)
                            Spacer()
                        }
                    }
                    
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 10) {
                        ForEach(ingredientsToAvoid) { ingredient in
                            ToggleButton(
                                ingredientTitle: IngredientTitle(
                                    name: ingredient.name,
                                    reason: ingredient.reason
                                ),
                                isSelected: isIngredientSelected(ingredient),
                                action: { toggleIngredient(ingredient) }
                            )
                            .padding(.horizontal, 8)
                        }
                    }
                }
            }
        }
    }
    
    private func isIngredientSelected(_ ingredient: IngredientToAvoid) -> Bool {
        ingredientsToAvoid.first(where: { $0.id == ingredient.id })?.isSelected ?? false
    }
    
    private func toggleIngredient(_ ingredient: IngredientToAvoid) {
        if let index = ingredientsToAvoid.firstIndex(where: { $0.id == ingredient.id }) {
            ingredientsToAvoid[index].isSelected.toggle()
            updateSelectAllState()
        }
    }
    
    private func toggleAllIngredients() {
        selectAllIngredients.toggle()
        ingredientsToAvoid = ingredientsToAvoid.map { ingredient in
            var updatedIngredient = ingredient
            updatedIngredient.isSelected = selectAllIngredients
            return updatedIngredient
        }
    }
    
    private func updateSelectAllState() {
        selectAllIngredients = ingredientsToAvoid.allSatisfy { $0.isSelected }
    }
    
    private func handleNextStep() {
        switch currentStep {
        case .blacklistedItems:
            fetchIngredientsToAvoid()
        case .ingredientsToAvoid:
            completeProfile()
        default:
            if validateCurrentStep() {
                nextStep()
            }
        }
    }
    
    private func nextStep() {
        withAnimation {
            currentStep = ProfileStep(rawValue: currentStep.rawValue + 1) ?? .basicInfo
        }
    }
    
    private func previousStep() {
        withAnimation {
            currentStep = ProfileStep(rawValue: currentStep.rawValue - 1) ?? .basicInfo
        }
    }
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case .basicInfo:
            guard !name.isEmpty else {
                showAlert("Please enter your name")
                return false
            }
            guard let ageInt = Int(age), ageInt > 0 else {
                showAlert("Please enter a valid age")
                return false
            }
            return true
            
        case .healthGoals:
            guard !selectedHealthGoals.isEmpty else {
                showAlert("Please select at least one health goal")
                return false
            }
            return true
            
        default:
            return true
        }
    }
    
    private func showAlert(_ message: String) {
        alertItem = AlertItem(
            title: "Invalid Input",
            message: message,
            dismissButton: .default(Text("OK"))
        )
    }
    
    private func fetchIngredientsToAvoid() {
        isLoadingIngredients = true
        
        // Create a Task for async operation
        Task {
            do {
                // Add slight delay for UI consistency
                try await Task.sleep(nanoseconds: 1_000_000) // 1 msecond
                
                let response = try await ingredientsService.fetchIngredientsToAvoid(
                    dietary: selectedBlacklistedItems,
                    health: selectedHealthGoals,
                    allergies: selectedAllergies
                )
                
                // Update UI on main thread
                await MainActor.run {
                    self.ingredientsToAvoid = response.blacklist.map { item in
                        IngredientToAvoid(
                            name: item.item,
                            reason: item.cause,
                            aliases: item.alias,
                            isSelected: true,
                            isExpanded: false,
                            selectedAliases: Set(item.alias)
                        )
                    }
                    isLoadingIngredients = false
                    currentStep = .ingredientsToAvoid
                }
            } catch {
                // Fallback to mock data if API fails
                print("API call failed: \(error.localizedDescription)")
                
                // Use mock data
                let jsonString = """
                {"blacklist":[{"item":"Gluten","alias":["Triticum vulgare","Secale cereale","Hordeum vulgare","wheat protein","wheat starch","modified food starch","hydrolyzed wheat protein","seitan","wheat germ"],"cause":"gluten-free dietary restriction"},{"item":"Peanuts","alias":["Arachis hypogaea","ground nuts","beer nuts","mixed nuts","artificial nuts","peanut oil","peanut flour"],"cause":"peanut allergy"}]}
                """
                
                if let jsonData = jsonString.data(using: .utf8),
                   let response = try? JSONDecoder().decode(BlacklistResponse.self, from: jsonData) {
                    
                    await MainActor.run {
                        self.ingredientsToAvoid = response.blacklist.map { item in
                            IngredientToAvoid(
                                name: item.item,
                                reason: item.cause,
                                aliases: item.alias,
                                isSelected: true,
                                isExpanded: false,
                                selectedAliases: Set(item.alias)
                            )
                        }
                        isLoadingIngredients = false
                        currentStep = .ingredientsToAvoid
                    }
                }
            }
        }
    }

    
//    private func fetchIngredientsToAvoid() {
//        isLoadingIngredients = true
//        
//        // Simulate API call with a delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//            // Parse the JSON response
//            let jsonString = """
//            {"blacklist":[{"item":"Gluten","alias":["Triticum vulgare","Secale cereale","Hordeum vulgare","wheat protein","wheat starch","modified food starch","hydrolyzed wheat protein","seitan","wheat germ"],"cause":"gluten-free dietary restriction"},{"item":"Peanuts","alias":["Arachis hypogaea","ground nuts","beer nuts","mixed nuts","artificial nuts","peanut oil","peanut flour"],"cause":"peanut allergy"}]}
//            """
//            
//            if let jsonData = jsonString.data(using: .utf8),
//               let response = try? JSONDecoder().decode(BlacklistResponse.self, from: jsonData) {
//                
//                // Transform the API response into our model
//                self.ingredientsToAvoid = response.blacklist.map { item in
//                    IngredientToAvoid(
//                        name: item.item,
//                        reason: item.cause,
//                        aliases: item.alias,
//                        isSelected: true,
//                        isExpanded: false,
//                        selectedAliases: Set(item.alias)
//                    )
//                }
//            }
//            
//            isLoadingIngredients = false
//            currentStep = .ingredientsToAvoid
//        }
//    }
    
//    private func completeProfile() {
//            let selectedIngredients = ingredientsToAvoid.filter { $0.isSelected }
//            
//            let profile = UserProfile(
//                fullName: name,
//                username: "@\(name.lowercased().replacingOccurrences(of: " ", with: ""))",
//                age: Int(age) ?? 0,
//                gender: selectedGender,
//                healthGoals: selectedHealthGoals,
//                allergies: selectedAllergies,
//                currentMedications: medication.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
//                blacklistedItems: selectedBlacklistedItems,
//                profileImageData: profileImage?.jpegData(compressionQuality: 0.7)
//            )
//            
//            viewModel.saveProfile(profile)
//            isProfileComplete = true
//            onSaveSuccess(profile)
//            navigateToScanner = true  // Trigger navigation to scanner
//        }
    
    private func completeProfile() {
        let selectedIngredients = ingredientsToAvoid.filter { $0.isSelected }
        
        let profile = UserProfile(
            fullName: name,
            username: "@\(name.lowercased().replacingOccurrences(of: " ", with: ""))",
            age: Int(age) ?? 0,
            gender: selectedGender,
            healthGoals: selectedHealthGoals,
            allergies: selectedAllergies,
            currentMedications: medication.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            blacklistedItems: selectedBlacklistedItems,
            profileImageData: profileImage?.jpegData(compressionQuality: 0.7),
            profileImageUrl: nil  // Add this if required
        )
        
        viewModel.saveProfile(profile)
        isProfileComplete = true  // This will trigger the navigation
    }
    
    struct ProfileImageSelector: View {
        @Binding var profileImage: UIImage?
        @State private var photoPickerItem: PhotosPickerItem?
        
        var body: some View {
            VStack {
                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                        )
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                }
                
                PhotosPicker(selection: $photoPickerItem,
                            matching: .images) {
                    HStack {
                        Image(systemName: "camera")
                        Text(profileImage == nil ? "Add Photo" : "Change Photo")
                    }
                    .foregroundColor(.primaryBlack)
                }
                .onChange(of: photoPickerItem) { newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                profileImage = uiImage
                            }
                        }
                    }
                }
                
                if profileImage != nil {
                    Button(role: .destructive) {
                        withAnimation {
                            profileImage = nil
                        }
                    } label: {
                        Text("Remove Photo")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    struct IngredientRow: View {
        @Binding var ingredient: IngredientToAvoid
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Main header
                Button(action: {
                    withAnimation {
                        ingredient.isExpanded.toggle()
                    }
                }) {
                    HStack(alignment: .top, spacing: 12) {
                        Toggle("", isOn: Binding(
                            get: { ingredient.isSelected },
                            set: { newValue in
                                ingredient.isSelected = newValue
                                if newValue {
                                    ingredient.selectedAliases = Set(ingredient.aliases)
                                } else {
                                    ingredient.selectedAliases.removeAll()
                                }
                            }
                        ))
                        .labelsHidden()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ingredient.name)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                            
                            Text(ingredient.reason)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: ingredient.isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(ingredient.isSelected ? Color.primaryBlack : Color(.systemGray6))
                .foregroundColor(ingredient.isSelected ? .white : .primary)
                
                if ingredient.isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Common forms and aliases:")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 8) {
                                ForEach(ingredient.aliases, id: \.self) { alias in
                                    AliasPill(
                                        alias: alias,
                                        isSelected: ingredient.selectedAliases.contains(alias)
                                    ) {
                                        toggleAlias(alias)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom)
                    }
                    .background(Color(.systemGray6))
                }
            }
            .cornerRadius(10)
        }
        
        private func toggleAlias(_ alias: String) {
            if ingredient.selectedAliases.contains(alias) {
                ingredient.selectedAliases.remove(alias)
            } else {
                ingredient.selectedAliases.insert(alias)
            }
            ingredient.isSelected = !ingredient.selectedAliases.isEmpty
        }
    }
    
        

    // Add a FlowLayout to handle the wrapping of alias pills
    struct FlowLayout: Layout {
        var spacing: CGFloat = 8
        
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let rows = computeRows(proposal: proposal, subviews: subviews)
            return computeSize(rows: rows, proposal: proposal)
        }
        
        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let rows = computeRows(proposal: proposal, subviews: subviews)
            placeRows(rows, in: bounds)
        }
        
        private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
            var rows: [[LayoutSubviews.Element]] = [[]]
            var currentRow = 0
            var remainingWidth = proposal.width ?? 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if size.width > remainingWidth {
                    currentRow += 1
                    rows.append([])
                    remainingWidth = (proposal.width ?? 0) - size.width - spacing
                    rows[currentRow].append(subview)
                } else {
                    remainingWidth -= size.width + spacing
                    rows[currentRow].append(subview)
                }
            }
            
            return rows
        }
        
        private func computeSize(rows: [[LayoutSubviews.Element]], proposal: ProposedViewSize) -> CGSize {
            var height: CGFloat = 0
            var width: CGFloat = 0
            
            for row in rows {
                var rowWidth: CGFloat = 0
                var rowHeight: CGFloat = 0
                
                for subview in row {
                    let size = subview.sizeThatFits(.unspecified)
                    rowWidth += size.width + spacing
                    rowHeight = max(rowHeight, size.height)
                }
                
                width = max(width, rowWidth)
                height += rowHeight + spacing
            }
            
            return CGSize(width: width, height: height)
        }
        
        private func placeRows(_ rows: [[LayoutSubviews.Element]], in bounds: CGRect) {
            var y = bounds.minY
            
            for row in rows {
                var x = bounds.minX
                let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
                
                for subview in row {
                    let size = subview.sizeThatFits(.unspecified)
                    subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                    x += size.width + spacing
                }
                
                y += rowHeight + spacing
            }
        }
    }

    
    struct PrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 18, weight: .medium))
                .frame(maxWidth: .infinity) // Makes primary button expand
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color.primaryBlack)
                .foregroundColor(.white)
                .cornerRadius(10)
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
        }
    }

    struct SecondaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 18, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(10)
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
        }
    }
    
//    #Preview {
//        MultiStepUserProfileView { _ in
//            // Preview doesn't need to do anything with the profile
//        }
//    }
}
