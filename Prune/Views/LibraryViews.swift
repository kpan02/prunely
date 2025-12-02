//
//  LibraryViews.swift
//  Prune
//

import SwiftUI
import Photos

struct MediaGridView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    let columns: [GridItem]
    
    @State private var selectedAlbum: PHAssetCollection?
    
    private var albumsWithUnreviewedPhotos: [PHAssetCollection] {
        photoLibrary.utilityAlbums.filter { album in
            let allPhotos = photoLibrary.fetchPhotos(in: album)
            return allPhotos.contains { asset in
                !decisionStore.isReviewed(asset.localIdentifier)
            }
        }
    }
    
    var body: some View {
        if albumsWithUnreviewedPhotos.isEmpty {
            EmptyStateView(title: "All Done!", message: "You've reviewed all media albums")
        } else {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Media")
                            .font(.system(size: 28, weight: .semibold))
                        
                        Text("\(albumsWithUnreviewedPhotos.count) albums")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 8)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(albumsWithUnreviewedPhotos, id: \.localIdentifier) { album in
                        AlbumThumbnail(album: album, photoLibrary: photoLibrary, decisionStore: decisionStore)
                            .onTapGesture {
                                selectedAlbum = album
                            }
                    }
                }
            }
            .navigationDestination(item: $selectedAlbum) { album in
                // Pass all photos - filtering handled by PhotoReviewView toggle
                let allPhotos = photoLibrary.fetchPhotos(in: album)
                PhotoReviewView(
                    albumTitle: album.localizedTitle ?? "Album",
                    photos: allPhotos,
                    photoLibrary: photoLibrary,
                    decisionStore: decisionStore
                )
            }
        }
    }
}

struct AlbumsGridView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    let columns: [GridItem]
    
    @State private var selectedAlbum: PHAssetCollection?
    @State private var hideReviewedAlbums: Bool = true
    
    private var albumsWithUnreviewedPhotos: [PHAssetCollection] {
        photoLibrary.userAlbums.filter { album in
            let allPhotos = photoLibrary.fetchPhotos(in: album)
            return allPhotos.contains { asset in
                !decisionStore.isReviewed(asset.localIdentifier)
            }
        }
    }
    
    private var albumsToShow: [PHAssetCollection] {
        if hideReviewedAlbums {
            return albumsWithUnreviewedPhotos
        } else {
            return photoLibrary.userAlbums.filter { album in
                let allPhotos = photoLibrary.fetchPhotos(in: album)
                // Include if has unreviewed OR all are archived
                let hasUnreviewed = allPhotos.contains { !decisionStore.isReviewed($0.localIdentifier) }
                let allArchived = !allPhotos.isEmpty && allPhotos.allSatisfy { decisionStore.isArchived($0.localIdentifier) }
                return hasUnreviewed || allArchived
            }
        }
    }
    
    var body: some View {
        if albumsToShow.isEmpty {
            EmptyStateView(title: "All Done!", message: "You've reviewed all your albums")
        } else {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Albums")
                            .font(.system(size: 28, weight: .semibold))
                        
                        Text("\(albumsToShow.count) albums")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("Hide Reviewed Albums", isOn: $hideReviewedAlbums)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 13))
                }
                .padding(.bottom, 8)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(albumsToShow, id: \.localIdentifier) { album in
                        AlbumThumbnail(album: album, photoLibrary: photoLibrary, decisionStore: decisionStore)
                            .onTapGesture {
                                selectedAlbum = album
                            }
                    }
                }
            }
            .navigationDestination(item: $selectedAlbum) { album in
                // Pass all photos - filtering handled by PhotoReviewView toggle
                let allPhotos = photoLibrary.fetchPhotos(in: album)
                PhotoReviewView(
                    albumTitle: album.localizedTitle ?? "Album",
                    photos: allPhotos,
                    photoLibrary: photoLibrary,
                    decisionStore: decisionStore
                )
            }
        }
    }
}

struct MonthsGridView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    let columns: [GridItem]
    
    @State private var selectedMonthAlbum: MonthAlbum?
    @State private var hideReviewedAlbums: Bool = true
    
    private var albumsWithUnreviewedPhotos: [MonthAlbum] {
        photoLibrary.monthAlbums.filter { monthAlbum in
            monthAlbum.photos.contains { asset in
                !decisionStore.isReviewed(asset.localIdentifier)
            }
        }
    }
    
    private var albumsToShow: [MonthAlbum] {
        if hideReviewedAlbums {
            return albumsWithUnreviewedPhotos
        } else {
            return photoLibrary.monthAlbums.filter { monthAlbum in
                // Include if has unreviewed OR all are archived
                let hasUnreviewed = monthAlbum.photos.contains { !decisionStore.isReviewed($0.localIdentifier) }
                let allArchived = !monthAlbum.photos.isEmpty && monthAlbum.photos.allSatisfy { decisionStore.isArchived($0.localIdentifier) }
                return hasUnreviewed || allArchived
            }
        }
    }
    
    var body: some View {
        if albumsToShow.isEmpty {
            EmptyStateView(title: "All Done!", message: "You've reviewed all photos in your library")
        } else {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Months")
                            .font(.system(size: 28, weight: .semibold))
                        
                        Text("\(albumsToShow.count) albums")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("Hide Reviewed Albums", isOn: $hideReviewedAlbums)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 13))
                }
                .padding(.bottom, 8)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(albumsToShow) { monthAlbum in
                        MonthAlbumThumbnail(monthAlbum: monthAlbum, photoLibrary: photoLibrary, decisionStore: decisionStore)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedMonthAlbum = monthAlbum
                            }
                    }
                }
            }
            .navigationDestination(
                isPresented: Binding<Bool>(
                    get: { selectedMonthAlbum != nil },
                    set: { if !$0 { selectedMonthAlbum = nil } }
                )
            ) {
                if let monthAlbum = selectedMonthAlbum {
                    // Pass all photos - filtering handled by PhotoReviewView toggle
                    PhotoReviewView(
                        albumTitle: monthAlbum.title,
                        photos: monthAlbum.photos,
                        photoLibrary: photoLibrary,
                        decisionStore: decisionStore
                    )
                }
            }
        }
    }
}

struct MonthAlbumThumbnail: View {
    let monthAlbum: MonthAlbum
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    @State private var coverImage: NSImage?
    @State private var isHovered = false
    
    private var unreviewedCount: Int {
        monthAlbum.photos.filter { asset in
            !decisionStore.isReviewed(asset.localIdentifier)
        }.count
    }
    
    private var isFullyReviewed: Bool {
        !monthAlbum.photos.isEmpty && monthAlbum.photos.allSatisfy { decisionStore.isArchived($0.localIdentifier) }
    }
    
    private func unarchiveAlbum() {
        let archivedPhotos = monthAlbum.photos.filter { decisionStore.isArchived($0.localIdentifier) }
        for photo in archivedPhotos {
            decisionStore.restore(photo.localIdentifier)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image
            ZStack {
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
                .opacity(isFullyReviewed ? 0.4 : 1.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(isFullyReviewed ? 0.6 : 0))
                )
                
                // Unarchive button on hover for reviewed albums
                if isHovered && isFullyReviewed {
                    Button {
                        unarchiveAlbum()
                    } label: {
                        Label("Unarchive Album", systemImage: "arrow.uturn.backward")
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            )
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Month name
            Text(monthAlbum.title)
                .font(.headline)
                .lineLimit(1)
                .padding(.bottom, 0)
            
            // Photo count (unreviewed)
            Text("\(unreviewedCount) photos")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color.primary.opacity(0.03) : Color.clear)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(color: .black.opacity(isHovered ? 0.15 : 0), radius: 10, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            loadCoverImage()
        }
    }
    
    private func loadCoverImage() {
        guard let coverAsset = monthAlbum.coverPhoto else { return }
        photoLibrary.loadThumbnail(for: coverAsset, size: CGSize(width: 320, height: 320)) { image in
            DispatchQueue.main.async {
                self.coverImage = image
            }
        }
    }
}

struct AlbumThumbnail: View {
    let album: PHAssetCollection
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    @State private var coverImage: NSImage?
    @State private var isHovered = false
    
    private var allPhotos: [PHAsset] {
        photoLibrary.fetchPhotos(in: album)
    }
    
    private var unreviewedCount: Int {
        allPhotos.filter { asset in
            !decisionStore.isReviewed(asset.localIdentifier)
        }.count
    }
    
    private var isFullyReviewed: Bool {
        !allPhotos.isEmpty && allPhotos.allSatisfy { decisionStore.isArchived($0.localIdentifier) }
    }
    
    private func unarchiveAlbum() {
        let archivedPhotos = allPhotos.filter { decisionStore.isArchived($0.localIdentifier) }
        for photo in archivedPhotos {
            decisionStore.restore(photo.localIdentifier)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image
            ZStack {
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
                .opacity(isFullyReviewed ? 0.4 : 1.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(isFullyReviewed ? 0.6 : 0))
                )
                
                // Unarchive button on hover for reviewed albums
                if isHovered && isFullyReviewed {
                    Button {
                        unarchiveAlbum()
                    } label: {
                        Label("Unarchive Album", systemImage: "arrow.uturn.backward")
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            )
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Album name
            Text(album.localizedTitle ?? "Untitled")
                .font(.headline)
                .lineLimit(1)
                .padding(.bottom, 0)
            
            // Photo count (unreviewed)
            Text("\(unreviewedCount) photos")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color.primary.opacity(0.03) : Color.clear)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(color: .black.opacity(isHovered ? 0.15 : 0), radius: 10, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
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

