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
    let analyzer: IngredientAnalyzerService
    @StateObject private var scannerService = ScannerService()
    @State private var showingPermissionAlert = false
    @State private var permissionStatus = "Not Determined"
    @State private var analysisResult: IngredientAnalysis?
    @State private var showingResults = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
        self.analyzer = IngredientAnalyzerService(userProfile: userProfile)
    }
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreviewView(scannerService: scannerService)
                .edgesIgnoringSafeArea(.all)
            
            // Flash animation overlay
            if scannerService.isCapturing {
                Color.white
                    .opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
            }
            
            VStack {
                // Status text
                Text("Camera: \(permissionStatus)")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.top)
                
                Spacer()
                
                // Capture button
                Button(action: handleCapture) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.2), lineWidth: 2)
                            )
                        
                        if scannerService.isCapturing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(1.5)
                        }
                    }
                }
                .disabled(scannerService.isCapturing)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            checkCameraPermission()
        }
        .alert("Camera Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings", role: .none) {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable camera access in Settings to use the scanner.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingResults) {
            if let result = analysisResult {
                ResultsView(analysis: result)
            }
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionStatus = "Authorized"
            scannerService.startScanning()
        case .notDetermined:
            permissionStatus = "Not Determined"
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    permissionStatus = granted ? "Authorized" : "Denied"
                    if granted {
                        scannerService.startScanning()
                    } else {
                        showingPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            permissionStatus = "Denied"
            showingPermissionAlert = true
        @unknown default:
            permissionStatus = "Unknown"
            showingPermissionAlert = true
        }
    }
    
    private func handleCapture() {
        scannerService.captureAndAnalyze { recognizedText, imageData in
            Task {
                do {
                    if let text = recognizedText, !text.isEmpty {
                        let analysis = try await analyzer.analyzeIngredients(text)
                        
                        await MainActor.run {
                            analysisResult = analysis
                            showingResults = true
                        }
                    } else {
                        throw NSError(domain: "", code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: "No text was detected in the image. Please try capturing the ingredients text more clearly."])
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showingError = true
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
