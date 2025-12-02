//
//  ArchiveView.swift
//  Prune
//

import SwiftUI
import Photos

struct ArchiveGridView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    let columns: [GridItem]
    
    @State private var archivedPhotos: [PHAsset] = []
    @State private var isCalculatingStorage = false
    @State private var isLoading = true
    @State private var showRestoreAllConfirmation = false
    @State private var selectedPhoto: PHAsset?
    
    private var photoCount: Int {
        archivedPhotos.count
    }
    
    private var totalStorage: Int64 {
        decisionStore.totalArchivedStorage
    }
    
    private var formattedStorage: String {
        formatFileSize(totalStorage)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Archive")
                        .font(.system(size: 28, weight: .semibold))
                    
                    if !isLoading {
                        HStack(spacing: 8) {
                            Text("\(photoCount) \(photoCount == 1 ? "photo" : "photos")")
                            if isCalculatingStorage {
                                Text("•")
                                    .foregroundStyle(.secondary.opacity(0.5))
                                Text("Calculating...")
                                    .foregroundStyle(.secondary.opacity(0.7))
                            } else if totalStorage > 0 {
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
                
                // Action button
                if !archivedPhotos.isEmpty {
                    Button {
                        showRestoreAllConfirmation = true
                    } label: {
                        Label("Restore All", systemImage: "arrow.uturn.backward")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.bottom, 8)
            
            // Content
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if archivedPhotos.isEmpty {
                EmptyArchiveView()
            } else {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(archivedPhotos, id: \.localIdentifier) { asset in
                        ArchivePhotoThumbnail(
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
            loadArchivedPhotos()
        }
        .onChange(of: decisionStore.archivedPhotoIDs.count) { _, _ in
            loadArchivedPhotos()
        }
        .alert("Are you sure you want to restore all \(photoCount) photos from archive?", isPresented: $showRestoreAllConfirmation) {
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
                    albumTitle: "Archive",
                    photos: [asset],
                    photoLibrary: photoLibrary,
                    decisionStore: decisionStore
                )
            }
        }
    }
    
    private func loadArchivedPhotos() {
        isLoading = true
        
        // Validate and cleanup orphaned IDs before loading
        decisionStore.validateAndCleanup()
        
        let archivedIDs = decisionStore.archivedPhotoIDs
        
        guard !archivedIDs.isEmpty else {
            archivedPhotos = []
            isLoading = false
            return
        }
        
        let result = photoLibrary.fetchPhotos(byIDs: archivedIDs)
        archivedPhotos = result.photos
        
        // Clean up orphaned IDs from decision store
        if !result.orphanedIDs.isEmpty {
            // Remove orphaned IDs from the decision store
            for orphanedID in result.orphanedIDs {
                decisionStore.restore(orphanedID) // This removes it from both archived and trashed
            }
        }
        
        isLoading = false
        
        // Calculate storage async if cache is missing or invalid
        if decisionStore.totalArchivedStorage == 0 && !archivedPhotos.isEmpty {
            calculateStorageAsync()
        }
    }
    
    private func calculateStorageAsync() {
        guard !archivedPhotos.isEmpty else { return }
        
        isCalculatingStorage = true
        
        // Calculate storage on background thread
        Task.detached(priority: .userInitiated) { [archivedPhotos] in
            var storage: Int64 = 0
            
            // Calculate storage for all photos
            for asset in archivedPhotos {
                let resources = PHAssetResource.assetResources(for: asset)
                if let resource = resources.first,
                let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong {
                    storage += Int64(unsignedInt64)
                }
            }
            
            // Capture the final value before MainActor.run
            let finalStorage = storage
            
            // Update on main thread
            await MainActor.run {
                decisionStore.updateArchivedStorage(finalStorage)
                isCalculatingStorage = false
            }
        }
    }
    
    private func restorePhoto(_ asset: PHAsset) {
        decisionStore.restore(asset.localIdentifier)
        // Reload to update the view immediately
        loadArchivedPhotos()
    }
    
    private func restoreAll() {
        for asset in archivedPhotos {
            decisionStore.restore(asset.localIdentifier)
        }
        // Reload to update the view immediately
        loadArchivedPhotos()
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct ArchivePhotoThumbnail: View {
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
                        .strokeBorder(Color.green.opacity(0.4), lineWidth: 2)
                )
                .overlay(
                    // Green overlay to indicate archive/kept
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(isHovered ? 0.1 : 0.05))
                )
                
                // Archive badge (checkmark)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.green)
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

struct EmptyArchiveView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 56))
                .foregroundStyle(.secondary.opacity(0.6))
            
            Text("Archive is empty")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Photos you keep will appear here")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

