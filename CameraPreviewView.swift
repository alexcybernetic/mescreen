//
//  CameraPreviewView.swift
//  MeScreen
//
//  Created by Alex on 19.03.26.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: NSViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeNSView(context: Context) -> CameraPreviewNSView {
        let view = CameraPreviewNSView()
        view.wantsLayer = true
        
        // Remove from any existing superlayer
        previewLayer.removeFromSuperlayer()
        
        previewLayer.videoGravity = .resizeAspectFill
        // Disable implicit Core Animation transitions so the layer
        // always tracks the view bounds without lagging behind.
        previewLayer.actions = ["bounds": NSNull(), "position": NSNull(), "frame": NSNull()]
        
        // Add to view – layout() will set the correct frame
        if let layer = view.layer {
            layer.addSublayer(previewLayer)
            print("🎬 CameraPreviewView: Preview layer added to view")
        }
        
        return view
    }
    
    func updateNSView(_ nsView: CameraPreviewNSView, context: Context) {
        // layout() handles frame updates; nothing extra needed here.
    }
}
// Custom NSView to handle layout
class CameraPreviewNSView: NSView {
    override func layout() {
        super.layout()

        // Keep all sublayers sized to the view bounds
        if let sublayers = layer?.sublayers {
            for sublayer in sublayers {
                sublayer.frame = bounds
            }
        }

        // Apply a circular mask so the preview is always round,
        // even during animated frame changes.
        if let layer = layer {
            let mask = CAShapeLayer()
            mask.path = CGPath(ellipseIn: bounds, transform: nil)
            layer.mask = mask
        }
    }
}

