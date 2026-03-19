//
//  CameraManager.swift
//  MeScreen
//
//  Created by Alex on 19.03.26.
//

@preconcurrency import AVFoundation
import AppKit
import Combine
import SwiftUI

enum WindowSize: CGFloat, CaseIterable {
    case small = 100
    case medium = 150
    case large = 200
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
}

@MainActor
class CameraManager: NSObject, ObservableObject {
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var availableCameras: [AVCaptureDevice] = []
    @Published var currentCamera: AVCaptureDevice?
    @Published var windowSize: WindowSize = .medium
    @Published var isTransitioning: Bool = false
    
    private var captureSession: AVCaptureSession?
    
    override init() {
        super.init()
        Task {
            await checkPermissions()
        }
    }
    
    func checkPermissions() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("📹 Camera authorization status: \(status.rawValue)")
        print("   0 = notDetermined, 1 = restricted, 2 = denied, 3 = authorized")
        
        switch status {
        case .authorized:
            print("✅ Camera authorized, setting up...")
            setupCamera()
        case .notDetermined:
            print("❓ Camera permission not determined, requesting...")
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            print("📹 Permission request result: \(granted)")
            if granted {
                print("✅ Permission granted! Setting up camera...")
                setupCamera()
            } else {
                print("❌ Camera permission denied")
                print("⚠️ Please enable camera access in System Settings > Privacy & Security > Camera")
            }
        case .denied:
            print("❌ Camera permission denied by user")
            print("⚠️ To fix: System Settings > Privacy & Security > Camera > Enable MeScreen")
        case .restricted:
            print("🚫 Camera access restricted (parental controls or MDM)")
        @unknown default:
            print("⚠️ Unknown camera authorization status")
        }
    }
    
    func setupCamera(with device: AVCaptureDevice? = nil) {
        print("🎥 Setting up camera...")
        print("🔍 Checking authorization status again: \(AVCaptureDevice.authorizationStatus(for: .video).rawValue)")
        
        // Stop existing session and wait for it to stop
        if let existingSession = captureSession, existingSession.isRunning {
            print("⏹️ Stopping existing session...")
            existingSession.stopRunning()
        }
        previewLayer = nil
        
        let session = AVCaptureSession()
        
        // Try starting session configuration
        session.beginConfiguration()
        session.sessionPreset = .medium
        
        // Discover available cameras - try ALL methods
        var discoveredCameras: [AVCaptureDevice] = []
        
        // Method 1: Discovery session with various device types
        print("🔍 Method 1: Discovery session...")
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .external
        ]
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .unspecified
        )
        discoveredCameras = discoverySession.devices
        print("   Found: \(discoveredCameras.map { $0.localizedName })")
        
        // Method 2 removed - deprecated API
        
        // Method 3: Try default device
        print("🔍 Method 3: Default device...")
        if let defaultCamera = AVCaptureDevice.default(for: .video) {
            print("   Found: \(defaultCamera.localizedName)")
            if !discoveredCameras.contains(where: { $0.uniqueID == defaultCamera.uniqueID }) {
                discoveredCameras.append(defaultCamera)
            }
        } else {
            print("   No default camera")
        }
        
        // Method 4: Try specific device types individually (macOS Sequoia fix)
        print("🔍 Method 4: Individual device type queries...")
        if let builtIn = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified) {
            print("   Found built-in: \(builtIn.localizedName)")
            if !discoveredCameras.contains(where: { $0.uniqueID == builtIn.uniqueID }) {
                discoveredCameras.append(builtIn)
            }
        }
        
        if let external = AVCaptureDevice.default(.external, for: .video, position: .unspecified) {
            print("   Found external: \(external.localizedName)")
            if !discoveredCameras.contains(where: { $0.uniqueID == external.uniqueID }) {
                discoveredCameras.append(external)
            }
        }
        
        availableCameras = discoveredCameras
        print("📷 Total found: \(availableCameras.count) camera(s): \(availableCameras.map { $0.localizedName })")
        
        // Select camera
        let selectedDevice = device ?? availableCameras.first
        guard let camera = selectedDevice else {
            print("❌ No camera available to use")
            session.commitConfiguration()
            return
        }
        currentCamera = camera
        print("✅ Selected camera: \(camera.localizedName)")
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
                print("✅ Camera input added to session")
            } else {
                print("❌ Cannot add camera input to session")
            }
            
            session.commitConfiguration()
            
            self.captureSession = session
            
            // Start session on background thread, THEN create preview layer
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                session.startRunning()
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    print("✅ Camera session started running")
                    print("   Session is running: \(session.isRunning)")
                    
                    // Create preview layer AFTER session starts
                    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                    previewLayer.videoGravity = .resizeAspectFill
                    // The frame will be set by CameraPreviewNSView.layout()
                    self.previewLayer = previewLayer
                    print("✅ Preview layer created and published!")
                }
            }
        } catch {
            print("❌ Error setting up camera: \(error.localizedDescription)")
            session.commitConfiguration()
        }
    }
    
    func switchCamera(to device: AVCaptureDevice) {
        print("🔄 Switching to camera: \(device.localizedName)")
        // Clear preview layer first
        previewLayer = nil
        // Then setup new camera
        setupCamera(with: device)
    }
    
    func stopCamera() {
        print("🛑 Stopping camera")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
        previewLayer = nil
    }
    
    // Manual refresh method to try finding cameras again
    func refreshCameras() {
        print("🔄 Manually refreshing cameras...")
        setupCamera()
    }

    /// Animated size change: hide stream → resize window → show stream
    func changeSize(to newSize: WindowSize) {
        guard newSize != windowSize else { return }

        // Step 1: instantly hide the stream
        isTransitioning = true

        // Step 2: on the next run-loop tick (stream is now hidden),
        // change the size — AppDelegate observes this and animates the window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.windowSize = newSize
            // Step 3 is handled by AppDelegate's animation completionHandler
            // calling finishTransition()
        }
    }

    /// Called by AppDelegate after the window resize animation completes
    func finishTransition() {
        // Small extra delay so the preview layer has settled at the new size
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.25)) {
                self.isTransitioning = false
            }
        }
    }
}
