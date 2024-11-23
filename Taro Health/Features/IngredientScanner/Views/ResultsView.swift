import SwiftUI

struct ResultsView: View {
    let analysis: IngredientAnalysis
    @Environment(\.dismiss) private var dismiss
    @State private var animateStatus = false
    @State private var animateSummary = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Status Card
                    VStack {
                        statusView
                            .scaleEffect(animateStatus ? 1 : 0.8)
                            .opacity(animateStatus ? 1 : 0)
                    }
                    .padding(.vertical)
                    
                    // Summary Card
                    VStack(alignment: .leading, spacing: 16) {
                        summaryView
                            .offset(y: animateSummary ? 0 : 20)
                            .opacity(animateSummary ? 1 : 0)
                    }
                }
                .padding()
            }
            .navigationTitle("Analysis Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateStatus = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                animateSummary = true
            }
        }
    }
    
    private var statusView: some View {
        VStack(spacing: 16) {
            // Circular status indicator
            ZStack {
                Circle()
                    .fill(getStatusColor().opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .stroke(getStatusColor(), lineWidth: 3)
                    .frame(width: 120, height: 120)
                
                Image(systemName: getStatusIcon())
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(getStatusColor())
            }
            
            Text(analysis.displayStatus)
                .font(.title2)
                .bold()
                .foregroundColor(getStatusColor())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Summary section
            VStack(alignment: .leading, spacing: 12) {
                Text("Summary")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(analysis.summary)
                    .font(.body)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Divider()
            
            // Date section
            VStack(alignment: .leading, spacing: 8) {
                Text("Analyzed on")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(analysis.formattedDate())
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private func getStatusIcon() -> String {
        switch analysis.status.lowercased() {
        case "skip":
            return "exclamationmark.triangle.fill"
        case "okay":
            return "checkmark.circle.fill"
        case "warning":
            return "exclamationmark.circle.fill"
        default:
            return "info.circle.fill"
        }
    }
    
    private func getStatusColor() -> Color {
        switch analysis.status.lowercased() {
        case "skip":
            return .red
        case "okay":
            return .green
        case "warning":
            return .yellow
        default:
            return .gray
        }
    }
}

// Preview Provider
struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        ResultsView(analysis: IngredientAnalysis(
            status: "okay",
            summary: "This product appears to be safe for consumption. All ingredients are recognized and within normal parameters."
        ))
    }
}
