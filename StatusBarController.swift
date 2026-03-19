//
//  StatusBarController.swift
//  MeScreen
//
//  Created by Alex on 19.03.26.
//

import AppKit
import AVFoundation
import Combine

@MainActor
class StatusBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    private let cameraManager: CameraManager
    private var cancellables = Set<AnyCancellable>()
    
    init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
        
        // Observe camera and size changes to update menu
        cameraManager.$availableCameras
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        cameraManager.$currentCamera
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        cameraManager.$windowSize
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "video.circle.fill", accessibilityDescription: "MeScreen")
        }
        
        updateMenu()
    }
    
    func updateMenu() {
        let menu = NSMenu()
        
        // Size selection section with icon
        let sizeHeader = NSMenuItem(title: "Size", action: nil, keyEquivalent: "")
        sizeHeader.image = NSImage(systemSymbolName: "aspectratio", accessibilityDescription: "Size")
        menu.addItem(sizeHeader)
        menu.addItem(NSMenuItem.separator())
        
        for size in WindowSize.allCases {
            let sizeItem = NSMenuItem(title: size.displayName, action: #selector(selectSize(_:)), keyEquivalent: "")
            sizeItem.target = self
            sizeItem.representedObject = size
            sizeItem.state = size == cameraManager.windowSize ? .on : .off
            
            // Add icon based on size
            let iconName = switch size {
            case .small: "circle.fill"
            case .medium: "circle.circle"
            case .large: "circle.circle.fill"
            }
            sizeItem.image = NSImage(systemSymbolName: iconName, accessibilityDescription: size.displayName)
            menu.addItem(sizeItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Camera selection section with icon
        let cameraHeader = NSMenuItem(title: "Cameras", action: nil, keyEquivalent: "")
        cameraHeader.image = NSImage(systemSymbolName: "video", accessibilityDescription: "Cameras")
        menu.addItem(cameraHeader)
        menu.addItem(NSMenuItem.separator())
        
        if cameraManager.availableCameras.isEmpty {
            let noCamera = NSMenuItem(title: "No cameras found", action: nil, keyEquivalent: "")
            noCamera.isEnabled = false
            noCamera.image = NSImage(systemSymbolName: "video.slash", accessibilityDescription: "No cameras")
            menu.addItem(noCamera)
            
            // Add refresh option when no cameras found
            let refresh = NSMenuItem(title: "Refresh Cameras", action: #selector(refreshCameras), keyEquivalent: "r")
            refresh.target = self
            refresh.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Refresh")
            menu.addItem(refresh)
        } else {
            for camera in cameraManager.availableCameras {
                let menuItem = NSMenuItem(
                    title: camera.localizedName,
                    action: #selector(selectCamera(_:)),
                    keyEquivalent: ""
                )
                menuItem.target = self
                menuItem.representedObject = camera
                menuItem.state = camera == cameraManager.currentCamera ? .on : .off
                
                // Icon for camera type
                let iconName = camera.deviceType == .external ? "video.fill" : "video.circle.fill"
                menuItem.image = NSImage(systemSymbolName: iconName, accessibilityDescription: camera.localizedName)
                menu.addItem(menuItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit option with icon
        let quitItem = NSMenuItem(title: "Quit MeScreen", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: "Quit")
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        
        print("🔄 Menu updated with \(cameraManager.availableCameras.count) camera(s)")
    }
    
    @objc func selectSize(_ sender: NSMenuItem) {
        guard let size = sender.representedObject as? WindowSize else { return }
        print("📐 Changing size to: \(size.displayName)")
        cameraManager.changeSize(to: size)
    }
    
    @objc func refreshCameras() {
        print("🔄 User requested camera refresh")
        cameraManager.refreshCameras()
    }
    
    @objc func selectCamera(_ sender: NSMenuItem) {
        guard let camera = sender.representedObject as? AVCaptureDevice else { return }
        cameraManager.switchCamera(to: camera)
        updateMenu()
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
