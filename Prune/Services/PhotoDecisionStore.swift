//
//  PhotoDecisionStore.swift
//  Prune
//
//  Manages persistence of user decisions (archive/trash) for photo review.
//

import Combine
import Foundation
import OSLog
import Photos

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
    private let logger = Logger(subsystem: "com.prune.app", category: "PhotoDecisionStore")

    init() {
        // Set up file path: ~/Library/Application Support/Prune/decisions.json
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access Application Support directory")
        }
        let pruneFolder = appSupport.appendingPathComponent("Prune")
        fileURL = pruneFolder.appendingPathComponent("decisions.json")

        try? FileManager.default.createDirectory(at: pruneFolder, withIntermediateDirectories: true)
        
        load()
    }

    // MARK: - Actions

    /// Mark a photo as accepted/archived
    func archive(_ photoID: String) {
        archivedPhotoIDs.insert(photoID)
        trashedPhotoIDs.remove(photoID) // Remove from trash if it was there
        totalArchivedStorage = 0
        save()
    }

    /// Mark a photo for deletion (pending)
    func trash(_ photoID: String) {
        let wasArchived = archivedPhotoIDs.contains(photoID)
        trashedPhotoIDs.insert(photoID)
        archivedPhotoIDs.remove(photoID) // Remove from archive if it was there
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
        Task {
            await validateAndCleanup()
        }
        save()
    }

    // MARK: - Queries

    func isArchived(_ photoID: String) -> Bool {
        archivedPhotoIDs.contains(photoID)
    }

    func isTrashed(_ photoID: String) -> Bool {
        trashedPhotoIDs.contains(photoID)
    }

    /// Determines if a photo has been reviewed (either archived or trashed).
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
            logger.error("Failed to save decisions: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decisions = try decoder.decode(PhotoDecisions.self, from: data)
            archivedPhotoIDs = decisions.archivedPhotoIDs
            trashedPhotoIDs = decisions.trashedPhotoIDs
            // Handle backward compatibility: if stats don't exist in old data, default to 0
            totalPhotosDeleted = decisions.totalPhotosDeleted ?? 0
            totalStorageFreed = decisions.totalStorageFreed ?? 0
            totalArchivedStorage = decisions.totalArchivedStorage ?? 0
        } catch {
            logger.error("Failed to load decisions: \(error.localizedDescription, privacy: .public). Starting fresh.")
            // Start fresh if file is corrupted
        }
    }

    // MARK: - Validation

    /// Validates and removes photo IDs that no longer exist in the Photos library.
    ///
    /// **When orphaned IDs occur:**
    /// - Photos are deleted outside of the app (e.g., in Photos app, iCloud sync)
    /// - Photos are moved to different albums or collections
    /// - Photos are removed from the library entirely
    ///
    /// **Process:**
    /// 1. Fetches all archived and trashed photo IDs from the Photos library
    /// 2. Compares with stored IDs to find orphaned entries
    /// 3. Removes orphaned IDs from both archived and trashed sets
    /// 4. Invalidates cached storage if archived IDs were removed
    /// 5. Saves the cleaned state
    ///
    /// **Performance:**
    /// - Runs on a background thread to avoid blocking the main thread
    /// - Photo library fetches can be slow for large sets
    /// - Called automatically after emptying trash, or manually from Archive/Trash views
    func validateAndCleanup() async {
        var hasChanges = false
        var validArchived: Set<String> = []
        var validTrashed: Set<String> = []

        // Validate archived IDs on background thread
        if !archivedPhotoIDs.isEmpty {
            let archivedIDs = archivedPhotoIDs // Capture on main actor
            let archivedAssets = await Task.detached(priority: .userInitiated) {
                PHAsset.fetchAssets(withLocalIdentifiers: Array(archivedIDs), options: nil)
            }.value

            archivedAssets.enumerateObjects { asset, _, _ in
                validArchived.insert(asset.localIdentifier)
            }
        }

        // Validate trashed IDs on background thread
        if !trashedPhotoIDs.isEmpty {
            let trashedIDs = trashedPhotoIDs // Capture on main actor
            let trashedAssets = await Task.detached(priority: .userInitiated) {
                PHAsset.fetchAssets(withLocalIdentifiers: Array(trashedIDs), options: nil)
            }.value

            trashedAssets.enumerateObjects { asset, _, _ in
                validTrashed.insert(asset.localIdentifier)
            }
        }

        // Update state on main actor
        await MainActor.run {
            if !archivedPhotoIDs.isEmpty, archivedPhotoIDs.count != validArchived.count {
                archivedPhotoIDs = validArchived
                hasChanges = true
                totalArchivedStorage = 0
            }

            if !trashedPhotoIDs.isEmpty, trashedPhotoIDs.count != validTrashed.count {
                trashedPhotoIDs = validTrashed
                hasChanges = true
            }

            if hasChanges {
                save()
            }
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
