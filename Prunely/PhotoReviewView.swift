//
//  PhotoReviewView.swift
//  Prunely
//
//  Photo review interface with filmstrip navigation and flexible reviewing.
//

import SwiftUI
import Photos
import AppKit

struct PhotoReviewView: View {
    let albumTitle: String
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    
    // All photos in the album (not pre-filtered)
    private let allPhotos: [PHAsset]
    
    @Environment(\.dismiss) private var dismiss
    // Track current photo by ID instead of index for stability
    @State private var currentPhotoId: String?
    @State private var currentImage: NSImage?
    @State private var isCompleted = false
    @State private var imageLoadFailed = false
    @State private var isLoading = false
    @State private var metadata: PhotoMetadata?
    @State private var isBackHovered = false
    @State private var feedback: ReviewFeedback?
    @State private var hideReviewed = false  // Default: show all photos
    @State private var thumbnailCache: [String: NSImage] = [:]
    
    init(albumTitle: String, photos: [PHAsset], photoLibrary: PhotoLibraryManager, decisionStore: PhotoDecisionStore) {
        self.albumTitle = albumTitle
        self.allPhotos = photos
        self.photoLibrary = photoLibrary
        self.decisionStore = decisionStore
    }
    
    // Photos to display based on toggle
    private var displayedPhotos: [PHAsset] {
        if hideReviewed {
            return allPhotos.filter { !decisionStore.isReviewed($0.localIdentifier) }
        } else {
            return allPhotos
        }
    }
    
    // Current index derived from photo ID
    private var currentIndex: Int {
        guard let photoId = currentPhotoId else { return 0 }
        return displayedPhotos.firstIndex(where: { $0.localIdentifier == photoId }) ?? 0
    }
    
    private var currentAsset: PHAsset? {
        guard let photoId = currentPhotoId else { return displayedPhotos.first }
        return displayedPhotos.first(where: { $0.localIdentifier == photoId })
    }
    
    private var progressText: String {
        let total = displayedPhotos.count
        let position = total > 0 ? currentIndex + 1 : 0
        if hideReviewed {
            return "\(position) / \(total) Unreviewed"
        } else {
            return "\(position) / \(total)"
        }
    }
    
    // Current photo's decision status
    private var currentDecisionStatus: DecisionStatus? {
        guard let asset = currentAsset else { return nil }
        if decisionStore.isArchived(asset.localIdentifier) {
            return .kept
        } else if decisionStore.isTrashed(asset.localIdentifier) {
            return .deleted
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top bar
                topBar
                
                // Metadata bar
                if let metadata = metadata, !isCompleted {
                    metadataBar(metadata: metadata)
                }
                
                // Photo area
                if isCompleted || displayedPhotos.isEmpty {
                    CompletionView(photoCount: allPhotos.count, reviewedCount: allPhotos.count - displayedPhotos.count) {
                        dismiss()
                    }
                } else {
                    photoArea
                        .padding(.bottom, 15)
                    
                    Divider()
                        .padding(.top, 5)
                    
                    filmstrip
                    
                    Divider()
                        .padding(.bottom, 5)
                    
                    controlsBar
                        .padding(.bottom, 5)
                }
            }
            
            // Feedback toast
            if let feedback = feedback {
                feedbackToast(feedback: feedback)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(hex: 0xFEFFFC))
        .navigationBarBackButtonHidden(true)
        .onAppear {
            initializeCurrentPhoto()
            loadCurrentImage()
            loadMetadata()
        }
        .onChange(of: currentPhotoId) { 
            loadCurrentImage()
            loadMetadata()
        }
        .onChange(of: hideReviewed) { oldValue, newValue in
            handleToggleChange(wasHiding: oldValue, nowHiding: newValue)
        }
    }
    
    // MARK: - Initialization
    
    private func initializeCurrentPhoto() {
        // Start at first unreviewed photo
        if let firstUnreviewed = allPhotos.first(where: { !decisionStore.isReviewed($0.localIdentifier) }) {
            currentPhotoId = firstUnreviewed.localIdentifier
        } else if let first = allPhotos.first {
            currentPhotoId = first.localIdentifier
        }
    }
    
    // MARK: - View Components
    
    private var topBar: some View {
        // Back button
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(isBackHovered ? 0.13 : 0.07))
                    )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.12)) {
                    isBackHovered = hovering
                }
            }
            
            Spacer()
        }

        // Album title
        .overlay(
            Text(albumTitle)
                .font(.system(size: 24, weight: .semibold))
        )

        // Progress text 
        .overlay(alignment: .trailing) {
            Text(progressText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(minWidth: 140, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }
    
    private func metadataBar(metadata: PhotoMetadata) -> some View {
        HStack(spacing: 20) {
            Spacer()
            
            // Decision status badge
            if let status = currentDecisionStatus {
                HStack(spacing: 5) {
                    Image(systemName: status == .kept ? "checkmark.circle.fill" : "trash.fill")
                        .font(.caption)
                    Text(status == .kept ? "Marked as Keep" : "Marked as Delete")
                        .font(.caption.weight(.medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(status == .kept ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                )
                .foregroundStyle(status == .kept ? .green : .red)
            }
            
            // Date
            HStack(spacing: 5) {
                Image(systemName: "calendar")
                    .font(.caption)
                Text(metadata.formattedDate)
                    .font(.caption)
            }
            
            // File size
            if let size = metadata.formattedSize {
                HStack(spacing: 5) {
                    Image(systemName: "doc.fill")
                        .font(.caption)
                    Text(size)
                        .font(.caption)
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 4)
        .padding(.bottom, 12)
        .background(Color.white)
        .foregroundStyle(.secondary)
    }
    
    private var photoArea: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white
                
                if imageLoadFailed {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundStyle(.yellow)
                        Text("Unable to load this photo")
                            .font(.headline)
                            .foregroundStyle(.gray)
                        Text("This photo may be corrupted or unavailable")
                            .font(.caption)
                            .foregroundStyle(.gray.opacity(0.7))
                        Button("Skip This Photo") {
                            goToNext()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if let image = currentImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: proxy.size.width, maxHeight: proxy.size.height)
                } else if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var filmstrip: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 4) {
                    ForEach(displayedPhotos, id: \.localIdentifier) { asset in
                        FilmstripThumbnail(
                            asset: asset,
                            isSelected: asset.localIdentifier == currentPhotoId,
                            decisionStatus: getDecisionStatus(for: asset),
                            thumbnail: thumbnailCache[asset.localIdentifier]
                        )
                        .id(asset.localIdentifier)
                        .onAppear {
                            loadThumbnail(for: asset)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(height: 80)
            .background(Color(hex: 0xFEFFFC))
            .onChange(of: currentPhotoId) { _, newId in
                if let newId = newId {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scrollProxy.scrollTo(newId, anchor: .center)
                    }
                }
            }
            .onAppear {
                // Initial scroll to current position
                if let photoId = currentPhotoId {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollProxy.scrollTo(photoId, anchor: .center)
                    }
                }
            }
        }
    }
    
    private var controlsBar: some View {
        ZStack {
            // Navigation and decision buttons - centered
            HStack(spacing: 16) {
                // Navigation: Back Button
                Button {
                    goToPrevious()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .frame(width: 68, height: 44, alignment: .center)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut(.leftArrow, modifiers: [])
                
                // Keep and Delete Buttons
                VStack(spacing: 8) {
                    Button {
                        handleAccept()
                    } label: {
                        Label("Keep  ", systemImage: "arrow.up")
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.large)
                    .keyboardShortcut(.upArrow, modifiers: [])
                    
                    Button {
                        handleDelete()
                    } label: {
                        Label("Delete", systemImage: "arrow.down")
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.red)
                    .controlSize(.large)
                    .keyboardShortcut(.downArrow, modifiers: [])
                }
                
                // Navigation: Next Button
                Button {
                    goToNext()
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .frame(width: 68, height: 44, alignment: .center)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut(.rightArrow, modifiers: [])
            }
            
            // Hide reviewed toggle - bottom right
            HStack {
                Spacer()
                Toggle(isOn: $hideReviewed) {
                    Text("Hide Reviewed Photos  ")
                        .font(.subheadline)
                }
                .toggleStyle(.checkbox)
                .help("Show only unreviewed photos")
            }
        }
        .padding()
        .background(Color.white)

        // Hidden button for spacebar to clear decision
        .background(
            Button("") { handleClearDecision() }
                .keyboardShortcut(.space, modifiers: [])
                .opacity(0)
        )
    }
    
    private func feedbackToast(feedback: ReviewFeedback) -> some View {
        VStack {
            let config = feedbackConfig(for: feedback)
            
            HStack(spacing: 6) {
                Image(systemName: config.icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(config.text)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(config.background)
            )
            .foregroundStyle(Color.white)
            .shadow(color: config.shadow, radius: 8, x: 0, y: 4)
            
            Spacer()
        }
        .padding(.top, 60)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Actions
    
    private func handleAccept() {
        guard let asset = currentAsset else { return }
        let photoId = asset.localIdentifier
        decisionStore.archive(photoId)
        showFeedback(.kept)
        advanceAfterDecision(from: photoId)
    }
    
    private func handleDelete() {
        guard let asset = currentAsset else { return }
        let photoId = asset.localIdentifier
        decisionStore.trash(photoId)
        showFeedback(.deleted)
        advanceAfterDecision(from: photoId)
    }
    
    private func handleClearDecision() {
        guard let asset = currentAsset else { return }
        // Only clear if photo is currently reviewed
        guard decisionStore.isReviewed(asset.localIdentifier) else { return }
        decisionStore.restore(asset.localIdentifier)
        showFeedback(.cleared)
    }
    
    private func goToNext() {
        let idx = currentIndex
        if idx < displayedPhotos.count - 1 {
            currentPhotoId = displayedPhotos[idx + 1].localIdentifier
        } else {
            isCompleted = true
        }
    }
    
    private func goToPrevious() {
        let idx = currentIndex
        if idx > 0 {
            currentPhotoId = displayedPhotos[idx - 1].localIdentifier
        }
    }
    
    private func advanceAfterDecision(from photoId: String) {
        if hideReviewed {
            // When hiding reviewed, the current photo disappears from displayedPhotos
            // We need to find the next unreviewed photo
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                // Find what would be the next photo after the one we just reviewed
                // Look in allPhotos to find position, then find next unreviewed
                if let originalIndex = allPhotos.firstIndex(where: { $0.localIdentifier == photoId }) {
                    // Look for next unreviewed photo after this position
                    for i in (originalIndex + 1)..<allPhotos.count {
                        if !decisionStore.isReviewed(allPhotos[i].localIdentifier) {
                            currentPhotoId = allPhotos[i].localIdentifier
                            return
                        }
                    }
                    // No more after, try from beginning
                    for i in 0..<originalIndex {
                        if !decisionStore.isReviewed(allPhotos[i].localIdentifier) {
                            currentPhotoId = allPhotos[i].localIdentifier
                            return
                        }
                    }
                    // All reviewed
                    isCompleted = true
                } else {
                    isCompleted = true
                }
            }
        } else {
            // When showing all, just advance to next
            goToNext()
        }
    }
    
    private func handleToggleChange(wasHiding: Bool, nowHiding: Bool) {
        guard let photoId = currentPhotoId else {
            // No current photo, initialize
            if let first = displayedPhotos.first {
                currentPhotoId = first.localIdentifier
            }
            return
        }
        
        // Check if current photo is still in the new displayed list
        if displayedPhotos.contains(where: { $0.localIdentifier == photoId }) {
            // Photo still visible, no change needed - just trigger a scroll update
            // The filmstrip will update automatically
            return
        }
        
        // Photo is no longer visible (it was reviewed and we're now hiding reviewed)
        // Find the nearest photo in the new list
        if let originalIndex = allPhotos.firstIndex(where: { $0.localIdentifier == photoId }) {
            // Try to find closest unreviewed photo
            // First look forward
            for i in originalIndex..<allPhotos.count {
                if displayedPhotos.contains(where: { $0.localIdentifier == allPhotos[i].localIdentifier }) {
                    currentPhotoId = allPhotos[i].localIdentifier
                    return
                }
            }
            // Then look backward
            for i in stride(from: originalIndex - 1, through: 0, by: -1) {
                if displayedPhotos.contains(where: { $0.localIdentifier == allPhotos[i].localIdentifier }) {
                    currentPhotoId = allPhotos[i].localIdentifier
                    return
                }
            }
        }
        
        // Fallback to first in list
        if let first = displayedPhotos.first {
            currentPhotoId = first.localIdentifier
        } else {
            isCompleted = true
        }
    }

    private func showFeedback(_ type: ReviewFeedback) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            feedback = type
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeOut(duration: 0.18)) {
                if feedback == type {
                    feedback = nil
                }
            }
        }
    }
    
    // MARK: - Image Loading
    
    private func loadCurrentImage() {
        guard let asset = currentAsset else { return }
        currentImage = nil
        imageLoadFailed = false
        isLoading = true
        
        let assetId = asset.localIdentifier
        
        // Add timeout to prevent indefinite loading
        let timeoutTask = DispatchWorkItem {
            DispatchQueue.main.async {
                // Only apply timeout if still on same photo
                if self.currentPhotoId == assetId && self.currentImage == nil && !self.imageLoadFailed {
                    print("Image load timeout for asset: \(assetId)")
                    self.imageLoadFailed = true
                    self.isLoading = false
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timeoutTask)
        
        photoLibrary.loadHighQualityImage(for: asset) { image in
            DispatchQueue.main.async {
                timeoutTask.cancel()
                // Only update if still on same photo
                guard self.currentPhotoId == assetId else { return }
                
                self.isLoading = false
                
                if let image = image {
                    self.currentImage = image
                    self.imageLoadFailed = false
                } else {
                    print("Failed to load image for asset: \(assetId)")
                    self.imageLoadFailed = true
                }
            }
        }
    }
    
    private func loadThumbnail(for asset: PHAsset) {
        guard thumbnailCache[asset.localIdentifier] == nil else { return }
        
        photoLibrary.loadThumbnail(for: asset, size: CGSize(width: 120, height: 120)) { image in
            DispatchQueue.main.async {
                if let image = image {
                    self.thumbnailCache[asset.localIdentifier] = image
                }
            }
        }
    }
    
    private func loadMetadata() {
        guard let asset = currentAsset else {
            metadata = nil
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = asset.creationDate.map { dateFormatter.string(from: $0) } ?? "Unknown"
        
        let fileSize = photoLibrary.getFileSize(for: asset)
        let sizeString = fileSize.map { formatFileSize($0) }
        
        metadata = PhotoMetadata(
            formattedDate: dateString,
            formattedSize: sizeString
        )
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func getDecisionStatus(for asset: PHAsset) -> DecisionStatus? {
        if decisionStore.isArchived(asset.localIdentifier) {
            return .kept
        } else if decisionStore.isTrashed(asset.localIdentifier) {
            return .deleted
        }
        return nil
    }
}

// MARK: - Supporting Types

enum DecisionStatus {
    case kept
    case deleted
}

struct PhotoMetadata {
    let formattedDate: String
    let formattedSize: String?
}

enum ReviewFeedback {
    case kept
    case deleted
    case cleared
}

private struct ReviewFeedbackConfig {
    let text: String
    let icon: String
    let background: Color
    let shadow: Color
}

private func feedbackConfig(for feedback: ReviewFeedback) -> ReviewFeedbackConfig {
    switch feedback {
    case .kept:
        return ReviewFeedbackConfig(
            text: "Kept",
            icon: "checkmark.circle.fill",
            background: Color.green.opacity(0.9),
            shadow: Color.green.opacity(0.35)
        )
    case .cleared:
        return ReviewFeedbackConfig(
            text: "Cleared",
            icon: "arrow.uturn.backward.circle.fill",
            background: Color.gray.opacity(0.9),
            shadow: Color.gray.opacity(0.35)
        )
    case .deleted:
        return ReviewFeedbackConfig(
            text: "Deleted",
            icon: "trash.fill",
            background: Color.red.opacity(0.9),
            shadow: Color.red.opacity(0.35)
        )
    }
}

// MARK: - Filmstrip Thumbnail

struct FilmstripThumbnail: View {
    let asset: PHAsset
    let isSelected: Bool
    let decisionStatus: DecisionStatus?
    let thumbnail: NSImage?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail image
            Group {
                if let thumbnail = thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.5)
                        )
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor, lineWidth: isSelected ? 3 : 1)
            )
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
            
            // Decision indicator
            if let status = decisionStatus {
                Circle()
                    .fill(status == .kept ? Color.green : Color.red)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Image(systemName: status == .kept ? "checkmark" : "trash.fill")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .offset(x: 4, y: -4)
            }
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .accentColor
        } else if decisionStatus == .kept {
            return .green.opacity(0.5)
        } else if decisionStatus == .deleted {
            return .red.opacity(0.5)
        }
        return .gray.opacity(0.3)
    }
}

// MARK: - Completion View

struct CompletionView: View {
    let photoCount: Int
    let reviewedCount: Int
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Review Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("You've reviewed all \(photoCount) photos in this album")
                .font(.body)
                .foregroundStyle(.secondary)
            
            Button("Back to Albums") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

