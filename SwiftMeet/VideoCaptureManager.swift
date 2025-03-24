//
//  VideoCaptureManager.swift
//  SwiftMeet
//
//  Created by Yaro4ka on 20.03.2025.
//

import SwiftUI
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins

@Observable class VideoCaptureManager: NSObject {
    private(set) var session = AVCaptureSession()
    var devices: [AVCaptureDevice] = []
    var selectedDevice: AVCaptureDevice? {
        didSet {
            guard oldValue?.uniqueID != selectedDevice?.uniqueID else { return }
            stopSession()
        }
    }

    var deviceActive: Bool = false
    var showDeviceDisconnectedAlert: Bool = false

    private var videoOutput = AVCaptureVideoDataOutput()
    private let context = CIContext()
    private var filter = CIFilter.sepiaTone()

    var currentFrame: NSImage?
    
    override init() {
        super.init()

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            loadDevices()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.loadDevices()
                    } else {
                        print("Camera access denied by user.")
                    }
                }
            }
        case .denied, .restricted:
            print("Camera access previously denied or restricted.")
        @unknown default:
            print("Unknown authorization status.")
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(globalDeviceConnected),
            name: AVCaptureDevice.wasConnectedNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(globalDeviceDisconnected),
            name: AVCaptureDevice.wasDisconnectedNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func loadDevices() {
        devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .external],
            mediaType: .video,
            position: .unspecified
        ).devices
        print("Devices: \(devices)")
    }

    func startSession() {
        guard !session.isRunning else { return }
        
        session.beginConfiguration()

        guard let selectedDevice = selectedDevice,
              let input = try? AVCaptureDeviceInput(device: selectedDevice),
              session.canAddInput(input),
              session.canAddOutput(videoOutput)
        else {
            deviceActive = false
            session.commitConfiguration()
            return
        }

        session.addInput(input)
        session.addOutput(videoOutput)

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))

        session.commitConfiguration()
        session.startRunning()

        deviceActive = true
    }
    
    @objc private func globalDeviceDisconnected(notification: Notification) {
        guard let device = notification.object as? AVCaptureDevice else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.loadDevices()

            if device.uniqueID == self.selectedDevice?.uniqueID {
                self.selectedDevice = nil
                self.deviceActive = false
                self.stopSession()
                self.showDeviceDisconnectedAlert = true
            }
        }
    }

    @objc private func globalDeviceConnected(notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.loadDevices()
        }
    }
    
    func stopSession() {
        session.stopRunning()
        
        session.inputs.forEach(session.removeInput)
        session.outputs.forEach(session.removeOutput)

        deviceActive = false
    }


}

extension VideoCaptureManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Apply sepia filter (video processing example)
        filter.inputImage = ciImage
        filter.intensity = 0.8

        guard let filteredImage = filter.outputImage,
              let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent)
        else { return }

        let size = NSSize(width: filteredImage.extent.width, height: filteredImage.extent.height)

        DispatchQueue.main.async {
            self.currentFrame = NSImage(cgImage: cgImage, size: size)
        }
    }
}
