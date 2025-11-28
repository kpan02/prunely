//
//  PhotoReviewView.swift
//  Prunely
//
//  Tinder-style photo review interface for accepting, deleting, or skipping photos.
//

import SwiftUI
import Photos
import AppKit

struct PhotoReviewView: View {
    let albumTitle: String
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    
    // Freeze the photos array on init - won't react to decisionStore changes
    @State private var photos: [PHAsset]
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var currentImage: NSImage?
    @State private var isCompleted = false
    @State private var imageLoadFailed = false
    @State private var isLoading = false
    @State private var metadata: PhotoMetadata?
    @State private var isBackHovered = false
    @State private var feedback: ReviewFeedback?
    
    init(albumTitle: String, photos: [PHAsset], photoLibrary: PhotoLibraryManager, decisionStore: PhotoDecisionStore) {
        self.albumTitle = albumTitle
        self._photos = State(initialValue: photos)
        self.photoLibrary = photoLibrary
        self.decisionStore = decisionStore
    }
    
    private var currentAsset: PHAsset? {
        guard photos.indices.contains(currentIndex) else { return nil }
        return photos[currentIndex]
    }
    
    private var progressText: String {
        "\(currentIndex + 1) / \(photos.count)"
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isBackHovered ? Color.primary.opacity(0.06) : .clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.12)) {
                            isBackHovered = hovering
                        }
                    }
                    
                    Spacer()
                    
                    Text(albumTitle)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(progressText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // Metadata bar (moved above photo area)
                if let metadata = metadata, !isCompleted {
                    HStack(spacing: 20) {
                        Spacer()
                        // Date
                        HStack(spacing: 10) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(metadata.formattedDate)
                                .font(.caption)
                        }
                        
                        // File size
                        if let size = metadata.formattedSize {
                            HStack(spacing: 10) {
                                Image(systemName: "doc.fill")
                                    .font(.caption)
                                Text(size)
                                    .font(.caption)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .foregroundStyle(.secondary)
                }
                
                // Photo area
                if isCompleted {
                    CompletionView(photoCount: photos.count) {
                        dismiss()
                    }
                } else {
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
                                        .foregroundStyle(.white)
                                    Text("This photo may be corrupted or unavailable")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                    Button("Skip This Photo") {
                                        handleSkip()
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
                                    .tint(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    // Controls
                    HStack(spacing: 24) {
                        Button {
                            handleDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .frame(minWidth: 100)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.red)
                        .controlSize(.large)
                        .keyboardShortcut(.leftArrow, modifiers: [])
                        
                        Button {
                            handleSkip()
                        } label: {
                            Text("Skip")
                                .frame(minWidth: 100)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .keyboardShortcut(.downArrow, modifiers: [])
                        
                        Button {
                            handleAccept()
                        } label: {
                            Label("Keep", systemImage: "checkmark.circle")
                                .frame(minWidth: 100)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .controlSize(.large)
                        .keyboardShortcut(.rightArrow, modifiers: [])
                    }
                    .padding()
                    .background(Color.white)
                }
            }
            
            if let feedback = feedback {
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
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            loadCurrentImage()
            loadMetadata()
        }
        .onChange(of: currentIndex) { 
            loadCurrentImage()
            loadMetadata()
        }
    }
    
    // MARK: - Actions
    
    private func handleAccept() {
        guard let asset = currentAsset else { return }
        decisionStore.archive(asset.localIdentifier)
        showFeedback(.kept)
        advance()
    }
    
    private func handleDelete() {
        guard let asset = currentAsset else { return }
        decisionStore.trash(asset.localIdentifier)
        showFeedback(.deleted)
        advance()
    }
    
    private func handleSkip() {
        advance()
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
    
    private func advance() {
        if currentIndex < photos.count - 1 {
            currentIndex += 1
        } else {
            isCompleted = true
        }
    }
    
    private func loadCurrentImage() {
        guard let asset = currentAsset else { return }
        currentImage = nil
        imageLoadFailed = false
        isLoading = true
        
        // Add timeout to prevent indefinite loading
        let timeoutTask = DispatchWorkItem {
            DispatchQueue.main.async {
                if self.currentImage == nil && !self.imageLoadFailed {
                    print("Image load timeout for asset: \(asset.localIdentifier)")
                    self.imageLoadFailed = true
                    self.isLoading = false
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timeoutTask)
        
        photoLibrary.loadHighQualityImage(for: asset) { image in
            DispatchQueue.main.async {
                timeoutTask.cancel() // Cancel timeout if we got a response
                self.isLoading = false
                
                if let image = image {
                    self.currentImage = image
                    self.imageLoadFailed = false
                } else {
                    print("Failed to load image for asset: \(asset.localIdentifier)")
                    self.imageLoadFailed = true
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
}

struct PhotoMetadata {
    let formattedDate: String
    let formattedSize: String?
}

enum ReviewFeedback {
    case kept
    case deleted
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
    case .deleted:
        return ReviewFeedbackConfig(
            text: "Deleted",
            icon: "trash.fill",
            background: Color.red.opacity(0.9),
            shadow: Color.red.opacity(0.35)
        )
    }
}

struct CompletionView: View {
    let photoCount: Int
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

