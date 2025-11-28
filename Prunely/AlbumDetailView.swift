//
//  AlbumDetailView.swift
//  Prunely
//

import SwiftUI
import Photos

struct AlbumDetailView: View {
    let album: PHAssetCollection
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @State private var photos: [PHAsset] = []
    
    private let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 2)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(photos, id: \.localIdentifier) { asset in
                    PhotoThumbnail(asset: asset, photoLibrary: photoLibrary)
                        .aspectRatio(1, contentMode: .fill)
                }
            }
            .padding(2)
        }
        .navigationTitle(album.localizedTitle ?? "Album")
        .onAppear {
            photos = photoLibrary.fetchPhotos(in: album)
        }
    }
}

struct PhotoThumbnail: View {
    let asset: PHAsset
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @State private var image: NSImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
        }
        .frame(minWidth: 120, minHeight: 120)
        .clipped()
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        photoLibrary.loadThumbnail(for: asset, size: CGSize(width: 240, height: 240)) { loadedImage in
            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }
    }
}

