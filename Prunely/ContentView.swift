//
//  ContentView.swift
//  Prunely
//

import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var photoLibrary = PhotoLibraryManager()
    
    var body: some View {
        VStack(spacing: 20) {
            switch photoLibrary.authorizationStatus {
            case .authorized, .limited:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                Text("Photo Library Access Granted")
                    .font(.title2)
                
            case .denied, .restricted:
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)
                Text("Photo Library Access Denied")
                    .font(.title2)
                Text("Enable access in System Settings > Privacy & Security > Photos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
            case .notDetermined:
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                Text("Prunely needs access to your Photos")
                    .font(.title2)
                Button("Grant Access") {
                    photoLibrary.requestAccess()
                }
                .buttonStyle(.borderedProminent)
                
            @unknown default:
                Text("Unknown status")
            }
        }
        .padding(40)
        .onAppear {
            photoLibrary.checkAuthorizationStatus()
        }
    }
}

#Preview {
    ContentView()
}
