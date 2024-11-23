import SwiftUI

struct ResultsView: View {
    let analysis: IngredientAnalysis
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Status with Icon
                    HStack(spacing: 12) {
                        Image(systemName: getStatusIcon())
                            .font(.title)
                            .foregroundColor(getStatusColor())
                        
                        Text(analysis.displayStatus)
                            .font(.title2)
                            .bold()
                    }
                    .padding(.bottom, 8)
                    
                    // Summary
                    Text(analysis.summary)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Scanned Date
                    Text(analysis.formattedDate())
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
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
    }
    
    private func getStatusIcon() -> String {
        switch analysis.status.lowercased() {
        case "skip":
            return "exclamationmark.triangle.fill"
        case "proceed":
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
        case "proceed":
            return .green
        case "warning":
            return .yellow
        default:
            return .gray
        }
    }
}
