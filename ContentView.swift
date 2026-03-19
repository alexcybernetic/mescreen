//
//  ContentView.swift
//  MeScreen
//
//  Created by Alex on 19.03.26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var cameraManager: CameraManager

    var body: some View {
        let size = cameraManager.windowSize.rawValue

        ZStack {
            // Black background – always visible, gives a clean base
            // during the fade transition.
            Circle()
                .fill(Color.black)

            if let previewLayer = cameraManager.previewLayer {
                CameraPreviewView(previewLayer: previewLayer)
                    .clipShape(Circle())
                    .opacity(cameraManager.isTransitioning ? 0 : 1)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "video.slash")
                                .font(.system(size: size * 0.27))
                                .foregroundColor(.white)
                            Text("No Camera")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(Color.white, lineWidth: 3)
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(CameraManager())
}
