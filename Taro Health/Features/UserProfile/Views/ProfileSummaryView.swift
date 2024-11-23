import SwiftUI

struct ProfileSummaryView: View {
    let userProfile: UserProfile
    @State private var showingScannerView = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                HStack(spacing: 16) {
                    if let imageData = userProfile.profileImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(userProfile.fullName)
                            .font(.title2)
                            .bold()
                        Text("Age: \(userProfile.age)")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                
                // Scan Button
                Button(action: {
                    showingScannerView = true
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 40))
                        Text("Scan Food Item")
                            .font(.headline)
                        Text("Instantly analyze ingredients")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.primaryBlack)
                    .cornerRadius(15)
                }
                
                // Profile Details Sections
                GroupBox("Health Goals") {
                    FlowLayout(alignment: .leading, spacing: 8) {
                        ForEach(Array(userProfile.healthGoals), id: \.self) { goal in
                            Text(goal.rawValue)
                                .fixedSize(horizontal: false, vertical: false) // Enable text wrapping
                                .padding(.horizontal, 6)
                                .padding(.vertical, 6)
                                .background(Color.primaryBlack.opacity(0.1))
                                .foregroundColor(.primaryBlack)
                                .cornerRadius(8)
                                .font(.custom("Poppins-Medium", size: 12))
                        }
                    }
                }
                
                if !userProfile.allergies.isEmpty {
                    GroupBox("Allergies") {
                        FlowLayout(alignment: .leading, spacing: 8) {
                            ForEach(Array(userProfile.allergies), id: \.self) { allergy in
                                Text(allergy)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                if !userProfile.blacklistedItems.isEmpty {
                    GroupBox("Dietary Restrictions") {
                        FlowLayout(alignment: .leading, spacing: 8) {
                            ForEach(Array(userProfile.blacklistedItems), id: \.self) { item in
                                Text(item)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.1))
                                    .foregroundColor(.orange)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingScannerView) {
            ScannerView(userProfile: userProfile)
        }
    }
}

// Helper view for flowing layout of tags
struct FlowLayout: Layout {
    var alignment: HorizontalAlignment = .leading
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            alignment: alignment,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            alignment: alignment,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(at: CGPoint(x: point.x + bounds.minX, y: point.y + bounds.minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var positions: [CGPoint]
        var size: CGSize
        
        init(in maxWidth: CGFloat, subviews: Subviews, alignment: HorizontalAlignment, spacing: CGFloat) {
            var cursor = CGPoint.zero
            var positions: [CGPoint] = []
            var rowHeight: CGFloat = 0
            var rowMaxY: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if cursor.x + size.width > maxWidth, !positions.isEmpty {
                    cursor.x = 0
                    cursor.y = rowMaxY + spacing
                }
                
                positions.append(cursor)
                rowHeight = max(rowHeight, size.height)
                rowMaxY = cursor.y + rowHeight
                cursor.x += size.width + spacing
            }
            
            self.positions = positions
            self.size = CGSize(width: maxWidth, height: rowMaxY)
        }
    }
}
