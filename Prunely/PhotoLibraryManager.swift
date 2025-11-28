//
//  PhotoLibraryManager.swift
//  Prunely
//

import Photos
import PhotosUI
import Combine
import AppKit

@MainActor
class PhotoLibraryManager: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var utilityAlbums: [PHAssetCollection] = []
    @Published var userAlbums: [PHAssetCollection] = []
    
    private let imageManager = PHCachingImageManager()
    
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
        var utilities: [PHAssetCollection] = []
        var user: [PHAssetCollection] = []
        
        // Fetch utility albums (Recents, Favorites, Screenshots, etc.)
        let smartAlbums = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .any,
            options: nil
        )
        smartAlbums.enumerateObjects { collection, _, _ in
            // Only include albums that have photos
            let assetCount = PHAsset.fetchAssets(in: collection, options: nil).count
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
            let assetCount = PHAsset.fetchAssets(in: collection, options: nil).count
            if assetCount > 0 {
                user.append(collection)
            }
        }
        
        self.utilityAlbums = utilities
        self.userAlbums = user
    }
    
    func fetchPhotos(in album: PHAssetCollection) -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let results = PHAsset.fetchAssets(in: album, options: fetchOptions)
        
        var assets: [PHAsset] = []
        results.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
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
    
    func getCoverPhoto(for album: PHAssetCollection) -> PHAsset? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        
        let results = PHAsset.fetchAssets(in: album, options: fetchOptions)
        return results.firstObject
    }
}
