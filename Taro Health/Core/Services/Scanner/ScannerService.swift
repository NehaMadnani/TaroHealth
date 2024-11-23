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
    
    private var session: AVCaptureSession
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let output = AVCapturePhotoOutput()
    private var completionHandler: ((String?) -> Void)?
    
    override init() {
        self.session = AVCaptureSession()
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        // Configure capture session
        session.sessionPreset = AVCaptureSession.Preset.high
        
        // Get camera device
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                      for: .video,
                                                      position: .back) else {
            self.error = "No camera available"
            return
        }
        
        // Create input
        guard let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            self.error = "Could not create video input"
            return
        }
        
        // Add inputs and outputs
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        // Create and configure preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        self.previewLayer = previewLayer
        
        // Start session
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return previewLayer
    }
    
    func startScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if !(self?.session.isRunning ?? true) {
                self?.session.startRunning()
            }
        }
    }
    
    func stopScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if self?.session.isRunning ?? false {
                self?.session.stopRunning()
            }
        }
    }
    
    func captureAndAnalyze(completion: @escaping (String?) -> Void) {
        self.completionHandler = completion
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
                self.completionHandler?(nil)
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.error = "Could not process captured image"
                self.completionHandler?(nil)
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
                self?.completionHandler?(recognizedText)
            }
        }
    }
    
    private func recognizeText(in image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        // Create request handler
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Create text recognition request
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Text recognition error: \(error)")
                completion(nil)
                return
            }
            
            // Process results
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
        
        // Configure the recognition level
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // Perform request
        do {
            try requestHandler.perform([request])
        } catch {
            print("Failed to perform recognition: \(error)")
            completion(nil)
        }
    }
}
