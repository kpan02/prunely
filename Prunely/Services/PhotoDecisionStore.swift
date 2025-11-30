//
//  PhotoDecisionStore.swift
//  Prunely
//
//  Manages persistence of user decisions (archive/trash) for photo review.
//

import Foundation
import Photos
import Combine

struct PhotoDecisions: Codable {
    var archivedPhotoIDs: Set<String>
    var trashedPhotoIDs: Set<String>
    var lastUpdated: Date
    var totalPhotosDeleted: Int?
    var totalStorageFreed: Int64?
    
    static var empty: PhotoDecisions {
        PhotoDecisions(
            archivedPhotoIDs: [],
            trashedPhotoIDs: [],
            lastUpdated: Date(),
            totalPhotosDeleted: 0,
            totalStorageFreed: 0
        )
    }
}

@MainActor
class PhotoDecisionStore: ObservableObject {
    @Published private(set) var archivedPhotoIDs: Set<String> = []
    @Published private(set) var trashedPhotoIDs: Set<String> = []
    @Published private(set) var totalPhotosDeleted: Int = 0
    @Published private(set) var totalStorageFreed: Int64 = 0
    
    private let fileURL: URL
    
    init() {
        // Set up file path: ~/Library/Application Support/Prunely/decisions.json
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let prunelyFolder = appSupport.appendingPathComponent("Prunely")
        self.fileURL = prunelyFolder.appendingPathComponent("decisions.json")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: prunelyFolder, withIntermediateDirectories: true)
        
        // Load existing decisions
        load()
    }
    
    // MARK: - Actions
    
    /// Mark a photo as accepted/archived
    func archive(_ photoID: String) {
        archivedPhotoIDs.insert(photoID)
        trashedPhotoIDs.remove(photoID) // Remove from trash if it was there
        save()
    }
    
    /// Mark a photo for deletion (pending)
    func trash(_ photoID: String) {
        trashedPhotoIDs.insert(photoID)
        archivedPhotoIDs.remove(photoID) // Remove from archive if it was there
        save()
    }
    
    /// Restore a photo from archive or trash back to unreviewed
    func restore(_ photoID: String) {
        archivedPhotoIDs.remove(photoID)
        trashedPhotoIDs.remove(photoID)
        save()
    }
    
    /// Clear all trashed IDs after actual deletion
    /// Also performs orphan cleanup on archived IDs
    /// Updates deletion statistics
    func emptyTrash(photosDeleted: Int, storageFreed: Int64) {
        trashedPhotoIDs.removeAll()
        totalPhotosDeleted += photosDeleted
        totalStorageFreed += storageFreed
        cleanupOrphanedIDs()
        save()
    }
    
    // MARK: - Queries
    
    func isArchived(_ photoID: String) -> Bool {
        archivedPhotoIDs.contains(photoID)
    }
    
    func isTrashed(_ photoID: String) -> Bool {
        trashedPhotoIDs.contains(photoID)
    }
    
    func isReviewed(_ photoID: String) -> Bool {
        isArchived(photoID) || isTrashed(photoID)
    }
    
    // MARK: - Persistence
    
    private func save() {
        let decisions = PhotoDecisions(
            archivedPhotoIDs: archivedPhotoIDs,
            trashedPhotoIDs: trashedPhotoIDs,
            lastUpdated: Date(),
            totalPhotosDeleted: totalPhotosDeleted,
            totalStorageFreed: totalStorageFreed
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(decisions)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save decisions: \(error)")
        }
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            // No existing file, start fresh
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decisions = try decoder.decode(PhotoDecisions.self, from: data)
            self.archivedPhotoIDs = decisions.archivedPhotoIDs
            self.trashedPhotoIDs = decisions.trashedPhotoIDs
            // Handle backward compatibility: if stats don't exist in old data, default to 0
            self.totalPhotosDeleted = decisions.totalPhotosDeleted ?? 0
            self.totalStorageFreed = decisions.totalStorageFreed ?? 0
        } catch {
            print("Failed to load decisions: \(error)")
            // Start fresh if file is corrupted
        }
    }
    
    // MARK: - Cleanup
    
    /// Remove IDs that no longer exist in the Photos library
    private func cleanupOrphanedIDs() {
        // Validate archived IDs
        if !archivedPhotoIDs.isEmpty {
            let archivedAssets = PHAsset.fetchAssets(withLocalIdentifiers: Array(archivedPhotoIDs), options: nil)
            var validArchived: Set<String> = []
            archivedAssets.enumerateObjects { asset, _, _ in
                validArchived.insert(asset.localIdentifier)
            }
            archivedPhotoIDs = validArchived
        }
        
        // Note: trashedPhotoIDs are already cleared by emptyTrash(),
        // so no need to validate them here
    }
    
    // MARK: - Debug
    
    func resetAll() {
        archivedPhotoIDs.removeAll()
        trashedPhotoIDs.removeAll()
        totalPhotosDeleted = 0
        totalStorageFreed = 0
        save()
    }
    
    var debugDescription: String {
        "PhotoDecisionStore: \(archivedPhotoIDs.count) archived, \(trashedPhotoIDs.count) trashed"
    }
}

