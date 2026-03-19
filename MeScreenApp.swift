//
//  MeScreenApp.swift
//  MeScreen
//
//  Created by Alex on 19.03.26.
//

import SwiftUI
import Combine

@main
struct MeScreenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.cameraManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // Remove most menu items but keep Quit working
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .saveItem) { }
            CommandGroup(replacing: .printItem) { }
            
            // Ensure Quit works
            CommandGroup(replacing: .appTermination) {
                Button("Quit MeScreen") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var window: NSWindow?
    let cameraManager = CameraManager()
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Use the compiled bundle icon instead of looking for a loose PNG file.
        if let appIcon = NSImage(named: NSImage.applicationIconName) {
            NSApp.applicationIconImage = appIcon
        }
        
        // Setup status bar first
        statusBarController = StatusBarController(cameraManager: cameraManager)
        statusBarController?.setupStatusBar()
        
        // Hide dock icon (make app accessory)
        NSApp.setActivationPolicy(.accessory)
        
        // Observe size changes and update window size
        cameraManager.$windowSize
            .sink { [weak self] _ in
                self?.updateWindowSize()
            }
            .store(in: &cancellables)
        
        // Wait a bit for the window to be created
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.configureWindow()
        }
    }
    
    func configureWindow() {
        guard let window = NSApplication.shared.windows.first else {
            print("⚠️ No window found")
            return
        }
        self.window = window
        
        print("🪟 Configuring window...")
        
        // Make window float on top and draggable
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear  // Transparent background!
        window.isOpaque = false
        window.hasShadow = false  // Turn OFF window shadow - ContentView has its own
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask = [.borderless, .fullSizeContentView]
        window.ignoresMouseEvents = false
        
        // Set the content size based only on cameraManager.windowSize.rawValue
        let contentSize = cameraManager.windowSize.rawValue
        window.setContentSize(NSSize(width: contentSize, height: contentSize))
        
        // Position in top-right corner
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - contentSize - 20
            let y = screenFrame.maxY - contentSize - 20
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        print("✅ Window configured - draggable: \(window.isMovableByWindowBackground)")
    }
    
    func updateWindowSize() {
        guard let window = window else { return }
        
        let contentSize = cameraManager.windowSize.rawValue
        
        print("📐 Updating window size to: \(contentSize)×\(contentSize)")
        
        // Animate the size change
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setContentSize(NSSize(width: contentSize, height: contentSize))
        }
    }
}
