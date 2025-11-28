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
    @Published var albums: [PHAssetCollection] = []
    
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
        var allAlbums: [PHAssetCollection] = []
        
        // Fetch utility albums (Recents, Favorites, Screenshots, etc.)
        let utilityAlbums = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .any,
            options: nil
        )
        utilityAlbums.enumerateObjects { collection, _, _ in
            // Only include albums that have photos
            let assetCount = PHAsset.fetchAssets(in: collection, options: nil).count
            if assetCount > 0 {
                allAlbums.append(collection)
            }
        }
        
        // Fetch user-created albums
        let userAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: nil
        )
        userAlbums.enumerateObjects { collection, _, _ in
            let assetCount = PHAsset.fetchAssets(in: collection, options: nil).count
            if assetCount > 0 {
                allAlbums.append(collection)
            }
        }
        
        self.albums = allAlbums
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
