//
//  PhotoDecisionStore.swift
//  Prune
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
    var totalArchivedStorage: Int64?
    
    static var empty: PhotoDecisions {
        PhotoDecisions(
            archivedPhotoIDs: [],
            trashedPhotoIDs: [],
            lastUpdated: Date(),
            totalPhotosDeleted: 0,
            totalStorageFreed: 0,
            totalArchivedStorage: 0
        )
    }
}

@MainActor
class PhotoDecisionStore: ObservableObject {
    @Published private(set) var archivedPhotoIDs: Set<String> = []
    @Published private(set) var trashedPhotoIDs: Set<String> = []
    @Published private(set) var totalPhotosDeleted: Int = 0
    @Published private(set) var totalStorageFreed: Int64 = 0
    @Published private(set) var totalArchivedStorage: Int64 = 0
    
    private let fileURL: URL
    
    init() {
        // Set up file path: ~/Library/Application Support/Prune/decisions.json
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let pruneFolder = appSupport.appendingPathComponent("Prune")
        self.fileURL = pruneFolder.appendingPathComponent("decisions.json")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: pruneFolder, withIntermediateDirectories: true)
        
        // Load existing decisions
        load()
    }
    
    // MARK: - Actions
    
    /// Mark a photo as accepted/archived
    func archive(_ photoID: String) {
        archivedPhotoIDs.insert(photoID)
        trashedPhotoIDs.remove(photoID) // Remove from trash if it was there
        // Invalidate cached storage - will be recalculated when Archive view loads
        totalArchivedStorage = 0
        save()
    }
    
    /// Mark a photo for deletion (pending)
    func trash(_ photoID: String) {
        let wasArchived = archivedPhotoIDs.contains(photoID)
        trashedPhotoIDs.insert(photoID)
        archivedPhotoIDs.remove(photoID) // Remove from archive if it was there
        // Invalidate cached storage if photo was archived
        if wasArchived {
            totalArchivedStorage = 0
        }
        save()
    }
    
    /// Restore a photo from archive or trash back to unreviewed
    func restore(_ photoID: String) {
        let wasArchived = archivedPhotoIDs.contains(photoID)
        archivedPhotoIDs.remove(photoID)
        trashedPhotoIDs.remove(photoID)
        // Invalidate cached storage if photo was archived
        if wasArchived {
            totalArchivedStorage = 0
        }
        save()
    }
    
    /// Clear all trashed IDs after actual deletion
    /// Also performs orphan cleanup on archived IDs
    /// Updates deletion statistics
    func emptyTrash(photosDeleted: Int, storageFreed: Int64) {
        trashedPhotoIDs.removeAll()
        totalPhotosDeleted += photosDeleted
        totalStorageFreed += storageFreed
        validateAndCleanup()
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
            totalStorageFreed: totalStorageFreed,
            totalArchivedStorage: totalArchivedStorage
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
            self.totalArchivedStorage = decisions.totalArchivedStorage ?? 0
        } catch {
            print("Failed to load decisions: \(error)")
            // Start fresh if file is corrupted
        }
    }
    
    // MARK: - Validation
    
    /// Validate and remove IDs that no longer exist in the Photos library
    /// Checks both archived and trashed photo IDs
    func validateAndCleanup() {
        var hasChanges = false
        
        // Validate archived IDs
        if !archivedPhotoIDs.isEmpty {
            let archivedAssets = PHAsset.fetchAssets(withLocalIdentifiers: Array(archivedPhotoIDs), options: nil)
            var validArchived: Set<String> = []
            archivedAssets.enumerateObjects { asset, _, _ in
                validArchived.insert(asset.localIdentifier)
            }
            if archivedPhotoIDs.count != validArchived.count {
                archivedPhotoIDs = validArchived
                hasChanges = true
                totalArchivedStorage = 0
            }
        }
        
        // Validate trashed IDs
        if !trashedPhotoIDs.isEmpty {
            let trashedAssets = PHAsset.fetchAssets(withLocalIdentifiers: Array(trashedPhotoIDs), options: nil)
            var validTrashed: Set<String> = []
            trashedAssets.enumerateObjects { asset, _, _ in
                validTrashed.insert(asset.localIdentifier)
            }
            if trashedPhotoIDs.count != validTrashed.count {
                trashedPhotoIDs = validTrashed
                hasChanges = true
            }
        }
        
        if hasChanges {
            save()
        }
    }
    
    // MARK: - Debug
    
    func resetAll() {
        archivedPhotoIDs.removeAll()
        trashedPhotoIDs.removeAll()
        totalPhotosDeleted = 0
        totalStorageFreed = 0
        totalArchivedStorage = 0
        save()
    }
    
    /// Update the cached archived storage value (called after async calculation)
    func updateArchivedStorage(_ storage: Int64) {
        totalArchivedStorage = storage
        save()
    }
    
    var debugDescription: String {
        "PhotoDecisionStore: \(archivedPhotoIDs.count) archived, \(trashedPhotoIDs.count) trashed"
    }
}

