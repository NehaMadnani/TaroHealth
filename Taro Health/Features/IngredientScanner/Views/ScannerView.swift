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
            CameraPreviewView(scannerService: scannerService)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
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
        scannerService.captureAndAnalyze { recognizedText, imageData in
            Task {
                do {
                    let analysis: IngredientAnalysis
                    
                    if let text = recognizedText, !text.isEmpty {
                        // Flow 1: Text detected
                        analysis = try await analyzer.analyzeIngredients(text)
                    } else if let imageData = imageData {
                        // Flow 2: No text detected, use image
                        let base64String = imageData.base64EncodedString()
                        let imageType = getImageType(from: imageData)
                        
                        let requestBody: [String: Any] = [
                            "image": [
                                "type": imageType,
                                "data": base64String
                            ]
                        ]
                        
                        analysis = try await analyzer.analyzeIngredients(requestBody)
                    } else {
                        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to capture image or text"])
                    }
                    
                    await MainActor.run {
                        self.analysisResult = analysis
                        self.showingResults = true
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                        self.showingError = true
                    }
                }
            }
        }
    }
    
    private func getImageType(from imageData: Data) -> String {
        let bytes = [UInt8](imageData)
        
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
            return "jpeg"
        } else if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return "png"
        } else if bytes.starts(with: [0x47, 0x49, 0x46, 0x38]) {
            return "gif"
        } else {
            return "unknown"
        }
    }
}
