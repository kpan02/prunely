//
//  ContentView.swift
//  Prunely
//

import SwiftUI
import Photos

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

enum SidebarTab: String, CaseIterable {
    // Library section
    case media = "Media"
    case albums = "Albums"
    case months = "Months"
    // Utilities section
    case trash = "Trash"
    case dashboard = "Dashboard"
    case archive = "Archive"
    case help = "Help"
    
    var icon: String {
        switch self {
        case .media: return "photo.on.rectangle"
        case .albums: return "square.stack.3d.up.fill"
        case .months: return "calendar"
        case .trash: return "trash"
        case .dashboard: return "chart.bar.fill"
        case .archive: return "archivebox.fill"
        case .help: return "questionmark.circle"
        }
    }
    
    var section: SidebarSection {
        switch self {
        case .media, .albums, .months:
            return .library
        case .trash, .dashboard, .archive, .help:
            return .utilities
        }
    }
    
    static var libraryTabs: [SidebarTab] {
        allCases.filter { $0.section == .library }
    }
    
    static var utilityTabs: [SidebarTab] {
        allCases.filter { $0.section == .utilities }
    }
}

enum SidebarSection: String {
    case library = "Library"
    case utilities = "Utilities"
}

struct ContentView: View {
    @StateObject private var photoLibrary = PhotoLibraryManager()
    @StateObject private var decisionStore = PhotoDecisionStore()
    @State private var selectedTab: SidebarTab = .media
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Custom Sidebar
                Sidebar(selectedTab: $selectedTab, decisionStore: decisionStore)
                    .padding(.leading, 12)
                    .padding(.vertical, 12)
                
                // Main Content
                Group {
                    switch photoLibrary.authorizationStatus {
                    case .authorized, .limited:
                        TabContentView(selectedTab: selectedTab, photoLibrary: photoLibrary, decisionStore: decisionStore)
                        
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(40)
                        
                    @unknown default:
                        Text("Unknown status")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 700, minHeight: 450)
            .background(Color(hex: 0xFEFFFC)) // background color for the main content
            .toolbar(.hidden)
        }
        .onAppear {
            photoLibrary.checkAuthorizationStatus()
            if photoLibrary.authorizationStatus == .authorized || photoLibrary.authorizationStatus == .limited {
                photoLibrary.fetchAlbums()
            }
        }
    }
}

// MARK: - Custom Sidebar

struct Sidebar: View {
    @Binding var selectedTab: SidebarTab
    @ObservedObject var decisionStore: PhotoDecisionStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Library Section
            SidebarSectionHeader(title: "Library")
            
            VStack(spacing: 2) {
                ForEach(SidebarTab.libraryTabs, id: \.self) { tab in
                    SidebarItem(tab: tab, isSelected: selectedTab == tab) {
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 10)
            
            // Utilities Section
            SidebarSectionHeader(title: "Utilities")
                .padding(.top, 20)
            
            VStack(spacing: 2) {
                ForEach(SidebarTab.utilityTabs, id: \.self) { tab in
                    SidebarItem(tab: tab, isSelected: selectedTab == tab) {
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 10)
            
            Spacer()
            
            // Reset button at bottom (for testing)
            Button {
                decisionStore.resetAll()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12))
                    Text("Reset All")
                        .font(.system(size: 13))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .help("Clear all decisions (archived & trashed)")
        }
        .padding(.top, 12)
        .frame(width: 180)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: 0xF2F7FD))
                    //.fill(Color(hex: 0xF8F8FF))
                
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            }
        )
    }
}

struct SidebarSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
    }
}

struct SidebarItem: View {
    let tab: SidebarTab
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                Text(tab.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected ? Color.accentColor.opacity(0.15) :
                        isHovered ? Color.primary.opacity(0.06) : Color.clear
                    )
            )
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}

struct TabContentView: View {
    let selectedTab: SidebarTab
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch selectedTab {
                // Library tabs
                case .media:
                    MediaGridView(photoLibrary: photoLibrary, decisionStore: decisionStore, columns: columns)
                case .albums:
                    AlbumsGridView(photoLibrary: photoLibrary, decisionStore: decisionStore, columns: columns)
                case .months:
                    MonthsGridView(photoLibrary: photoLibrary, decisionStore: decisionStore, columns: columns)
                // Utility tabs
                case .trash:
                    TrashGridView(photoLibrary: photoLibrary, decisionStore: decisionStore, columns: columns)
                case .dashboard:
                    UtilityPlaceholderView(title: "Dashboard", icon: "chart.bar.fill", description: "View your photo library statistics")
                case .archive:
                    UtilityPlaceholderView(title: "Archive", icon: "archivebox.fill", description: "Photos marked as kept will appear here")
                case .help:
                    UtilityPlaceholderView(title: "Help", icon: "questionmark.circle", description: "Get help using Prunely")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Utility Placeholder View

struct UtilityPlaceholderView: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(.secondary.opacity(0.6))
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Coming Soon")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

struct MonthsGridView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    let columns: [GridItem]
    
    @State private var selectedMonthAlbum: MonthAlbum?
    
    private var albumsWithUnreviewedPhotos: [MonthAlbum] {
        photoLibrary.monthAlbums.filter { monthAlbum in
            monthAlbum.photos.contains { asset in
                !decisionStore.isReviewed(asset.localIdentifier)
            }
        }
    }
    
    var body: some View {
        if albumsWithUnreviewedPhotos.isEmpty {
            EmptyStateView(title: "All Done!", message: "You've reviewed all photos in your library")
        } else {
            VStack(spacing: 10) {
                VStack(spacing: 4) {
                    Text("Months")
                        .font(.system(size: 28, weight: .semibold))
                    
                    Text("\(albumsWithUnreviewedPhotos.count) albums")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(albumsWithUnreviewedPhotos) { monthAlbum in
                        MonthAlbumThumbnail(monthAlbum: monthAlbum, photoLibrary: photoLibrary, decisionStore: decisionStore)
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
            VStack(spacing: 10) {
                VStack(spacing: 4) {
                    Text("Media")
                        .font(.system(size: 28, weight: .semibold))
                    
                    Text("\(albumsWithUnreviewedPhotos.count) albums")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

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
    
    private var albumsWithUnreviewedPhotos: [PHAssetCollection] {
        photoLibrary.userAlbums.filter { album in
            let allPhotos = photoLibrary.fetchPhotos(in: album)
            return allPhotos.contains { asset in
                !decisionStore.isReviewed(asset.localIdentifier)
            }
        }
    }
    
    var body: some View {
        if albumsWithUnreviewedPhotos.isEmpty {
            EmptyStateView(title: "All Done!", message: "You've reviewed all your albums")
        } else {
            VStack(spacing: 10) {
                VStack(spacing: 4) {
                    Text("Albums")
                        .font(.system(size: 28, weight: .semibold))
                    
                    Text("\(albumsWithUnreviewedPhotos.count) albums")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

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

struct EmptyStateView: View {
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
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
    
    private var unreviewedCount: Int {
        let allPhotos = photoLibrary.fetchPhotos(in: album)
        return allPhotos.filter { asset in
            !decisionStore.isReviewed(asset.localIdentifier)
        }.count
    }
    
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

// MARK: - Trash Grid View

struct TrashGridView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    let columns: [GridItem]
    
    @State private var trashedPhotos: [PHAsset] = []
    @State private var isLoading = true
    @State private var showEmptyTrashConfirmation = false
    @State private var selectedPhoto: PHAsset?
    
    private var photoCount: Int {
        trashedPhotos.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trash")
                        .font(.system(size: 28, weight: .semibold))
                    
                    if !isLoading {
                        Text("\(photoCount) \(photoCount == 1 ? "photo" : "photos")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Action buttons
                if !trashedPhotos.isEmpty {
                    HStack(spacing: 12) {
                        Button {
                            restoreAll()
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
        let trashedIDs = decisionStore.trashedPhotoIDs
        
        guard !trashedIDs.isEmpty else {
            trashedPhotos = []
            isLoading = false
            return
        }
        
        let result = photoLibrary.fetchPhotos(byIDs: trashedIDs)
        trashedPhotos = result.photos
        
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
    
    private func emptyTrash() {
        // Permanently delete all trashed photos
        let assetsToDelete = trashedPhotos
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSArray)
        }, completionHandler: { success, error in
            if success {
                // Clear the trashed IDs from decision store
                Task { @MainActor in
                    decisionStore.emptyTrash()
                }
            } else if let error = error {
                print("Error deleting photos: \(error.localizedDescription)")
            }
        })
    }
}

// MARK: - Trash Photo Thumbnail

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

// MARK: - Empty Trash View

struct EmptyTrashView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trash")
                .font(.system(size: 56))
                .foregroundStyle(.secondary.opacity(0.6))
            
            Text("Trash is empty")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Photos you mark for deletion will appear here")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

#Preview {
    ContentView()
}
