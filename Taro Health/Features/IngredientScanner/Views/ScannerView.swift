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
                Task {
                    do {
                        let analysis = try await analyzer.analyzeIngredients(text)
                        // Since we're updating UI state, ensure we're on the main thread
                        await MainActor.run {
                            self.analysisResult = analysis
                            self.showingResults = true
                        }
                    } catch {
                        // Handle specific API errors if needed
                        await MainActor.run {
                            switch error {
                            case APIError.networkError:
                                self.errorMessage = "Network error. Please check your connection and try again."
                            case APIError.serverError:
                                self.errorMessage = "Server error. Please try again later."
                            case APIError.invalidResponse, APIError.decodingError:
                                self.errorMessage = "Error processing the response. Please try again."
                            default:
                                self.errorMessage = error.localizedDescription
                            }
                            self.showingError = true
                        }
                    }
                }
            } else {
                errorMessage = "Failed to recognize text from the image. Please try again."
                showingError = true
            }
        }
    }
}

