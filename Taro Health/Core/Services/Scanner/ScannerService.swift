import Foundation
import AVFoundation
import UIKit
import Vision
import VisionKit

class ScannerService: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var lastRecognizedText: String?
    @Published var error: String?
    @Published var isScanning = false
    @Published var capturedImage: UIImage?
    @Published var isCapturing = false // For capture animation
    
    private var session: AVCaptureSession
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let output = AVCapturePhotoOutput()
    private var completionHandler: ((String?, Data?) -> Void)?
    
    override init() {
        self.session = AVCaptureSession()
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        session.sessionPreset = .photo
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .back) else {
            self.error = "No camera available"
            return
        }
        
        guard let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            self.error = "Could not create video input"
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.connection?.videoOrientation = .portrait
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return previewLayer
    }
    
    func startScanning() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func stopScanning() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }
    
    func captureAndAnalyze(completion: @escaping (String?, Data?) -> Void) {
        self.completionHandler = completion
        
        DispatchQueue.main.async {
            self.isCapturing = true
            
            // Add haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        output.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async {
            self.isCapturing = false
        }
        
        if let error = error {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
                self.completionHandler?(nil, nil)
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.error = "Could not process captured image"
                self.completionHandler?(nil, nil)
            }
            return
        }
        
        DispatchQueue.main.async {
            self.capturedImage = image
        }
        
        // Perform text recognition
        recognizeText(in: image) { [weak self] recognizedText in
            DispatchQueue.main.async {
                self?.lastRecognizedText = recognizedText
                self?.completionHandler?(recognizedText, imageData)
            }
        }
    }
    
    private func recognizeText(in image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Text recognition error: \(error)")
                completion(nil)
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            let fullText = recognizedStrings.joined(separator: "\n")
            completion(fullText)
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Failed to perform recognition: \(error)")
            completion(nil)
        }
    }
}
