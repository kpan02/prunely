//
//  PhotoLibraryManager.swift
//  Prunely
//

import Photos
import PhotosUI
import Combine
import AppKit

struct MonthAlbum: Identifiable {
    let id: String
    let title: String
    let date: Date
    let photos: [PHAsset]
    
    var coverPhoto: PHAsset? {
        photos.first
    }
    
    var photoCount: Int {
        photos.count
    }
}

@MainActor
class PhotoLibraryManager: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var monthAlbums: [MonthAlbum] = []
    @Published var utilityAlbums: [PHAssetCollection] = []
    @Published var userAlbums: [PHAssetCollection] = []
    
    private let imageManager = PHCachingImageManager()
    private var albumPhotosCache: [String: [PHAsset]] = [:]
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func requestAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            Task { @MainActor in
                self.authorizationStatus = status
                if status == .authorized || status == .limited {
                    self.fetchAlbums()
                }
            }
        }
    }
    
    func fetchAlbums() {
        albumPhotosCache.removeAll()
        fetchMonthAlbums()
        fetchUtilityAndUserAlbums()
    }
    
    private func fetchMonthAlbums() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        
        let results = PHAsset.fetchAssets(with: fetchOptions)
        
        // Group photos by month
        var groupedPhotos: [String: (date: Date, photos: [PHAsset])] = [:]
        let calendar = Calendar.current
        
        results.enumerateObjects { asset, _, _ in
            guard let creationDate = asset.creationDate else { return }
            
            let components = calendar.dateComponents([.year, .month], from: creationDate)
            guard let year = components.year, let month = components.month else { return }
            
            let key = "\(year)-\(String(format: "%02d", month))"
            
            if groupedPhotos[key] == nil {
                // Use first day of month for sorting
                let monthDate = calendar.date(from: components) ?? creationDate
                groupedPhotos[key] = (date: monthDate, photos: [])
            }
            groupedPhotos[key]?.photos.append(asset)
        }
        
        // Convert to MonthAlbum array and sort by date (newest first)
        self.monthAlbums = groupedPhotos.map { key, value in
            MonthAlbum(
                id: key,
                title: dateFormatter.string(from: value.date),
                date: value.date,
                photos: value.photos
            )
        }.sorted { $0.date > $1.date }
    }
    
    private func fetchUtilityAndUserAlbums() {
        var utilities: [PHAssetCollection] = []
        var user: [PHAssetCollection] = []
        
        // Fetch utility albums (Recents, Favorites, Screenshots, etc.)
        let smartAlbums = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .any,
            options: nil
        )
        smartAlbums.enumerateObjects { collection, _, _ in
            // Only include albums that have photos (images only)
            let imageFetchOptions = PHFetchOptions()
            imageFetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            let assetCount = PHAsset.fetchAssets(in: collection, options: imageFetchOptions).count
            if assetCount > 0 {
                utilities.append(collection)
            }
        }
        
        // Fetch user-created albums (excluding shared albums)
        let albums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: nil
        )
        albums.enumerateObjects { collection, _, _ in
            // Skip shared albums
            if collection.assetCollectionSubtype == .albumCloudShared {
                return
            }
            let imageFetchOptions = PHFetchOptions()
            imageFetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            let assetCount = PHAsset.fetchAssets(in: collection, options: imageFetchOptions).count
            if assetCount > 0 {
                user.append(collection)
            }
        }
        
        self.utilityAlbums = utilities
        self.userAlbums = user
    }
    
    func fetchPhotos(in album: PHAssetCollection) -> [PHAsset] {
        // Return cached photos if available
        if let cached = albumPhotosCache[album.localIdentifier] {
            return cached
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        
        let results = PHAsset.fetchAssets(in: album, options: fetchOptions)
        
        var assets: [PHAsset] = []
        results.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        // Cache results for subsequent calls
        albumPhotosCache[album.localIdentifier] = assets
        
        return assets
    }
    
    func getPhotoCount(for album: PHAssetCollection) -> Int {
        return PHAsset.fetchAssets(in: album, options: nil).count
    }
    
    func loadThumbnail(for asset: PHAsset, size: CGSize, completion: @escaping (NSImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        
        imageManager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            completion(image)
        }
    }
    
    func loadHighQualityImage(for asset: PHAsset, completion: @escaping (NSImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true // Allow downloading from iCloud if needed
        options.resizeMode = .fast
        
        imageManager.requestImage(
            for: asset,
            targetSize: CGSize(width: 2000, height: 2000),
            contentMode: .aspectFit,
            options: options
        ) { image, info in
            // Check for errors
            if let error = info?[PHImageErrorKey] as? Error {
                print("Error loading image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            // Check if this is a degraded/low-quality version
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            
            // Only complete with high-quality images or if we got an error
            if !isDegraded || image == nil {
                completion(image)
            }
        }
    }
    
    func getCoverPhoto(for album: PHAssetCollection) -> PHAsset? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        
        let results = PHAsset.fetchAssets(in: album, options: fetchOptions)
        return results.firstObject
    }
    
    func getFileSize(for asset: PHAsset) -> Int64? {
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first else { return nil }
        
        if let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong {
            return Int64(unsignedInt64)
        }
        return nil
    }
    
    /// Fetch photos by their local identifiers, filtering out any that no longer exist
    /// Returns both the valid photos and the set of orphaned IDs that were removed
    func fetchPhotos(byIDs photoIDs: Set<String>) -> (photos: [PHAsset], orphanedIDs: Set<String>) {
        guard !photoIDs.isEmpty else {
            return ([], [])
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let results = PHAsset.fetchAssets(withLocalIdentifiers: Array(photoIDs), options: fetchOptions)
        
        var validPhotos: [PHAsset] = []
        var foundIDs: Set<String> = []
        
        results.enumerateObjects { asset, _, _ in
            validPhotos.append(asset)
            foundIDs.insert(asset.localIdentifier)
        }
        
        // Find orphaned IDs (IDs that were requested but not found)
        let orphanedIDs = photoIDs.subtracting(foundIDs)
        
        return (validPhotos, orphanedIDs)
    }
}
