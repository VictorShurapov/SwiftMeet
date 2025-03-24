//
//  ContentView.swift
//  SwiftMeet
//
//  Created by Yaro4ka on 20.03.2025.
//

import SwiftUI
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @Environment(VideoCaptureManager.self) private var captureManager
    @State private var showingDisconnectedAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Device Picker
            Picker("Select Camera", selection: Binding(
                get: { captureManager.selectedDevice },
                set: { captureManager.selectedDevice = $0 }
            )) {
                if captureManager.devices.isEmpty {
                    Text("No cameras available").tag(AVCaptureDevice?.none)
                } else {
                    Text("None").tag(AVCaptureDevice?.none)
                    
                    ForEach(captureManager.devices, id: \.uniqueID) { device in
                        Text(device.localizedName).tag(Optional(device))
                    }
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            // Video Preview
            if let image = captureManager.currentFrame {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 600, maxHeight: 400)
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.2))
                    .frame(width: 600, height: 400)
                    .cornerRadius(8)
                    .overlay(Text("Video Preview").foregroundColor(.gray))
            }
            
            // Start/Stop Video Preview
            HStack(spacing: 15) {
                Button("Start") {
                    captureManager.startSession()
                }
                .disabled(captureManager.selectedDevice == nil || captureManager.session.isRunning)
                
                Button("Stop") {
                    captureManager.stopSession()
                }
                .disabled(!captureManager.session.isRunning)
            }
            
            // Device Status Indicator
            HStack {
                Circle()
                    .fill(captureManager.deviceActive ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(captureManager.deviceActive ? "Preview Running" : "Preview Stopped")
                    .foregroundColor(captureManager.deviceActive ? .green : .red)
                    .font(.caption)
            }
        }
        .padding()
        .frame(width: 650)
        .alert("Device Disconnected", isPresented: Binding(
            get: { captureManager.showDeviceDisconnectedAlert },
            set: { captureManager.showDeviceDisconnectedAlert = $0 }
        )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The selected device has been disconnected. Please reconnect or select another device.")
        }
    }

}

#Preview {
    ContentView()
}
