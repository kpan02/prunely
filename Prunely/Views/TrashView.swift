//
//  TrashView.swift
//  Prunely
//

import SwiftUI
import Photos

struct TrashGridView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    let columns: [GridItem]
    
    @State private var trashedPhotos: [PHAsset] = []
    @State private var totalStorage: Int64 = 0
    @State private var isLoading = true
    @State private var showEmptyTrashConfirmation = false
    @State private var showRestoreAllConfirmation = false
    @State private var selectedPhoto: PHAsset?
    
    private var photoCount: Int {
        trashedPhotos.count
    }
    
    private var formattedStorage: String {
        formatFileSize(totalStorage)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trash")
                        .font(.system(size: 28, weight: .semibold))
                    
                    if !isLoading {
                        HStack(spacing: 8) {
                            Text("\(photoCount) \(photoCount == 1 ? "photo" : "photos")")
                            if totalStorage > 0 {
                                Text("•")
                                    .foregroundStyle(.secondary.opacity(0.5))
                                Text(formattedStorage)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Action buttons
                if !trashedPhotos.isEmpty {
                    HStack(spacing: 12) {
                        Button {
                            showRestoreAllConfirmation = true
                        } label: {
                            Label("Restore All", systemImage: "arrow.uturn.backward")
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            showEmptyTrashConfirmation = true
                        } label: {
                            Label("Empty Trash", systemImage: "trash.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
            }
            .padding(.bottom, 8)
            
            // Content
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if trashedPhotos.isEmpty {
                EmptyTrashView()
            } else {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(trashedPhotos, id: \.localIdentifier) { asset in
                        TrashPhotoThumbnail(
                            asset: asset,
                            photoLibrary: photoLibrary,
                            decisionStore: decisionStore,
                            onRestore: {
                                restorePhoto(asset)
                            },
                            onSelect: {
                                selectedPhoto = asset
                            }
                        )
                    }
                }
            }
        }
        .onAppear {
            loadTrashedPhotos()
        }
        .onChange(of: decisionStore.trashedPhotoIDs.count) { _, _ in
            loadTrashedPhotos()
        }
        .alert("Empty Trash", isPresented: $showEmptyTrashConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                emptyTrash()
            }
        } message: {
            Text("Are you sure you want to permanently delete all \(photoCount) photos in trash? This action cannot be undone.")
        }
        .alert("Are you sure you want to restore all \(photoCount) photos from trash?", isPresented: $showRestoreAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Restore All", role: .destructive) {
                restoreAll()
            }
        } message: {
            Text("They will be marked as unreviewed.")
        }
        .navigationDestination(
            isPresented: Binding<Bool>(
                get: { selectedPhoto != nil },
                set: { if !$0 { selectedPhoto = nil } }
            )
        ) {
            if let asset = selectedPhoto {
                PhotoReviewView(
                    albumTitle: "Trash",
                    photos: [asset],
                    photoLibrary: photoLibrary,
                    decisionStore: decisionStore
                )
            }
        }
    }
    
    private func loadTrashedPhotos() {
        isLoading = true
        
        // Validate and cleanup orphaned IDs before loading
        decisionStore.validateAndCleanup()
        
        let trashedIDs = decisionStore.trashedPhotoIDs
        
        guard !trashedIDs.isEmpty else {
            trashedPhotos = []
            totalStorage = 0
            isLoading = false
            return
        }
        
        let result = photoLibrary.fetchPhotos(byIDs: trashedIDs)
        trashedPhotos = result.photos
        
        // Calculate total storage
        var storage: Int64 = 0
        for asset in trashedPhotos {
            if let fileSize = photoLibrary.getFileSize(for: asset) {
                storage += fileSize
            }
        }
        totalStorage = storage
        
        // Clean up orphaned IDs from decision store
        if !result.orphanedIDs.isEmpty {
            // Remove orphaned IDs from the decision store
            for orphanedID in result.orphanedIDs {
                decisionStore.restore(orphanedID) // This removes it from both archived and trashed
            }
        }
        
        isLoading = false
    }
    
    private func restorePhoto(_ asset: PHAsset) {
        decisionStore.restore(asset.localIdentifier)
        // Reload to update the view immediately
        loadTrashedPhotos()
    }
    
    private func restoreAll() {
        for asset in trashedPhotos {
            decisionStore.restore(asset.localIdentifier)
        }
        // Reload to update the view immediately
        loadTrashedPhotos()
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func emptyTrash() {
        // Calculate statistics BEFORE deletion (while assets still exist)
        let photosDeleted = trashedPhotos.count
        var storageFreed: Int64 = 0
        
        // Sum up file sizes for all photos being deleted
        for asset in trashedPhotos {
            if let fileSize = photoLibrary.getFileSize(for: asset) {
                storageFreed += fileSize
            }
        }
        
        // Permanently delete all trashed photos
        let assetsToDelete = trashedPhotos
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSArray)
        }, completionHandler: { success, error in
            if success {
                // Update statistics in decision store after successful deletion
                Task { @MainActor in
                    decisionStore.emptyTrash(photosDeleted: photosDeleted, storageFreed: storageFreed)
                }
            } else if let error = error {
                print("Error deleting photos: \(error.localizedDescription)")
            }
        })
    }
}

struct TrashPhotoThumbnail: View {
    let asset: PHAsset
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    let onRestore: () -> Void
    let onSelect: () -> Void
    
    @State private var thumbnail: NSImage?
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // Thumbnail
                Group {
                    if let thumbnail = thumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    }
                }
                .frame(width: 160, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.red.opacity(0.4), lineWidth: 2)
                )
                .overlay(
                    // Red overlay to indicate trash
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(isHovered ? 0.1 : 0.05))
                )
                
                // Trash badge
                Image(systemName: "trash.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.red)
                    )
                    .padding(8)
                
                // Restore button on hover
                if isHovered {
                    VStack {
                        Spacer()
                        Button {
                            onRestore()
                        } label: {
                            Label("Restore", systemImage: "arrow.uturn.backward")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.blue)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 8)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        guard thumbnail == nil else { return }
        photoLibrary.loadThumbnail(for: asset, size: CGSize(width: 320, height: 320)) { image in
            DispatchQueue.main.async {
                self.thumbnail = image
            }
        }
    }
}

struct EmptyTrashView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trash")
                .font(.system(size: 56))
                .foregroundStyle(.secondary.opacity(0.6))
            
            Text("Trash is empty")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Photos you delete will appear here")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

