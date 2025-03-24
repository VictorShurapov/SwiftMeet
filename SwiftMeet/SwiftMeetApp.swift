//
//  SwiftMeetApp.swift
//  SwiftMeet
//
//  Created by Yaro4ka on 20.03.2025.
//

import SwiftUI

@main
struct SwiftMeetApp: App {
    @State private var captureManager = VideoCaptureManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(captureManager)
        }
    }
}
