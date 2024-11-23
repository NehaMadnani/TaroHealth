import SwiftUI
import AVFoundation

// Camera Preview UIViewRepresentable
struct CameraPreviewView: UIViewRepresentable {
    let scannerService: ScannerService
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        if let previewLayer = scannerService.getPreviewLayer() {
            previewLayer.frame = view.frame
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct ScannerView: View {
    let userProfile: UserProfile
    
    @StateObject private var scannerService = ScannerService()
    @State private var analysisResult: IngredientAnalysis?
    @State private var showingResults = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let analyzer: IngredientAnalyzerService
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
        self.analyzer = IngredientAnalyzerService(userProfile: userProfile)
    }
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(scannerService: scannerService)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // Capture button
                Button(action: handleCapture) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 2)
                        )
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingResults) {
            if let analysis = analysisResult {
                ResultsView(analysis: analysis)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            scannerService.startScanning()
        }
        .onDisappear {
            scannerService.stopScanning()
        }
    }
    
    private func handleCapture() {
        scannerService.captureAndAnalyze { recognizedText in
            if let text = recognizedText {
                let analysis = analyzer.analyzeIngredients(text)
                analysisResult = analysis
                showingResults = true
            } else {
                errorMessage = "Failed to recognize text from the image. Please try again."
                showingError = true
            }
        }
    }
}

// Original ResultsView remains unchanged
struct ResultsView: View {
    let analysis: IngredientAnalysis
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Safety Status
                    HStack {
                        Image(systemName: analysis.isSafe ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(analysis.isSafe ? .green : .red)
                            .font(.title)
                        
                        Text(analysis.isSafe ? "Safe to Consume" : "Use Caution")
                            .font(.title2)
                            .bold()
                    }
                    
                    // Health Score
                    VStack(alignment: .leading) {
                        Text("Health Score")
                            .font(.headline)
                        
                        HStack {
                            Text("\(analysis.healthScore)")
                                .font(.system(size: 48))
                                .bold()
                            Text("/ 10")
                                .font(.title)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Warnings
                    if !analysis.warnings.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Warnings")
                                .font(.headline)
                            
                            ForEach(analysis.warnings, id: \.self) { warning in
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.yellow)
                                    Text(warning)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    // Flagged Ingredients
                    if !analysis.flaggedIngredients.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Flagged Ingredients")
                                .font(.headline)
                            
                            ForEach(analysis.flaggedIngredients, id: \.self) { ingredient in
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                    Text(ingredient)
                                }
                                .padding(.vertical, 4)
                            }
                        }
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
    }
}
