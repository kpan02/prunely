//
//  ContentView.swift
//  Prunely
//

import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var photoLibrary = PhotoLibraryManager()
    
    var body: some View {
        NavigationStack {
            Group {
                switch photoLibrary.authorizationStatus {
                case .authorized, .limited:
                    AlbumsGridView(photoLibrary: photoLibrary)
                    
                case .denied, .restricted:
                    VStack(spacing: 20) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red)
                        Text("Photo Library Access Denied")
                            .font(.title2)
                        Text("Enable access in System Settings > Privacy & Security > Photos")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(40)
                    
                case .notDetermined:
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        Text("Prunely needs access to your Photos")
                            .font(.title2)
                        Button("Grant Access") {
                            photoLibrary.requestAccess()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(40)
                    
                @unknown default:
                    Text("Unknown status")
                }
            }
            .frame(minWidth: 600, minHeight: 400)
        }
        .onAppear {
            photoLibrary.checkAuthorizationStatus()
            if photoLibrary.authorizationStatus == .authorized || photoLibrary.authorizationStatus == .limited {
                photoLibrary.fetchAlbums()
            }
        }
    }
}

struct AlbumsGridView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Utilities Section
                if !photoLibrary.utilityAlbums.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Utilities")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(photoLibrary.utilityAlbums, id: \.localIdentifier) { album in
                                NavigationLink(destination: AlbumDetailView(album: album, photoLibrary: photoLibrary)) {
                                    AlbumThumbnail(album: album, photoLibrary: photoLibrary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                // User Albums Section
                if !photoLibrary.userAlbums.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        // Add extra top padding and a dividing line before this section
                        Divider()
                            .padding(.vertical, 24)
                        Text("Albums")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(photoLibrary.userAlbums, id: \.localIdentifier) { album in
                                NavigationLink(destination: AlbumDetailView(album: album, photoLibrary: photoLibrary)) {
                                    AlbumThumbnail(album: album, photoLibrary: photoLibrary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Library")
    }
}

struct AlbumThumbnail: View {
    let album: PHAssetCollection
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @State private var coverImage: NSImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image
            Group {
                if let image = coverImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 160, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Album name
            Text(album.localizedTitle ?? "Untitled")
                .font(.headline)
                .lineLimit(1)
            
            // Photo count
            Text("\(photoLibrary.getPhotoCount(for: album)) photos")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            loadCoverImage()
        }
    }
    
    private func loadCoverImage() {
        guard let coverAsset = photoLibrary.getCoverPhoto(for: album) else { return }
        photoLibrary.loadThumbnail(for: coverAsset, size: CGSize(width: 320, height: 320)) { image in
            DispatchQueue.main.async {
                self.coverImage = image
            }
        }
    }
}

#Preview {
    ContentView()
}
