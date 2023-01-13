//
//  ZpdlStudioImageQuery.swift
//  zpdl_studio_media_plugin
//
//  Created by 김경환 on 2020/10/12.
//

import MobileCoreServices
import Photos

class StoreCameraMediaPluinImageQuery: NSObject, PHPhotoLibraryChangeObserver {
    
    static let shared = StoreCameraMediaPluinImageQuery()

    private var modifyTimeMs: TimeInterval = 0.0
    private let imageManager = PHCachingImageManager()

    override private init() {
        super.init()
        updateModifyTimeMs()
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func updateModifyTimeMs() {
        modifyTimeMs = Date().timeIntervalSince1970
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        updateModifyTimeMs()
    }
    
    func photoLibraryAuthorizationStatus(_ request: Bool, _ completion: @escaping (Bool) -> Void) {
        let status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .notDetermined, .denied:
            if request {
                PHPhotoLibrary.requestAuthorization { (status: PHAuthorizationStatus) in
                    if status == PHAuthorizationStatus.authorized {
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            } else {
                completion(false)
            }
        case .authorized:
            completion(true)
        default:
            completion(false)
        }
    }

    private func sortOrderQuery(_ sortOrder: PluginSortOrder?) -> [NSSortDescriptor]? {
        let pluginSortOrder = sortOrder ?? PluginSortOrder.DATE_DESC

        switch pluginSortOrder {
        case .DATE_DESC:
            return [NSSortDescriptor(key: "creationDate", ascending: false)]
        case .DATE_ARC:
            return [NSSortDescriptor(key: "creationDate", ascending: true)]
        }
    }

    private func fetchPHAssetCollection(_ localIdentifier: String) -> PHAssetCollection? {
        let phAssetCollections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [localIdentifier], options: nil)
        return phAssetCollections.firstObject
    }
    
    func fetchPHAsset(_ localIdentifier: String) -> PHAsset? {
        let fetchOPtions = PHFetchOptions()
        fetchOPtions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        return PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: fetchOPtions).firstObject
    }

    func fetchPHAssets(_ localIdentifiers: [String]) -> [PHAsset] {
        var results = [PHAsset]()
        let fetchOPtions = PHFetchOptions()
        fetchOPtions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        PHAsset.fetchAssets(withLocalIdentifiers: localIdentifiers, options: fetchOPtions).enumerateObjects { (phAsset, _, _) in
            results.append(phAsset)
        }
        
        return results
    }
    
    func requestContentEditingInputs(_ localIdentifiers: [String], _ completion: @escaping ([PHContentEditingInput]) -> Void) {
        let phAssets = fetchPHAssets(localIdentifiers)
        if phAssets.isEmpty {
            completion([])
            return
        }
        
        var results = [PHContentEditingInput]()
        var resultsCount = 0
        for phAsset in phAssets {
            phAsset.requestContentEditingInput(with: PHContentEditingInputRequestOptions()) { (editingInput, _) in
                resultsCount += 1
                if let input = editingInput {
                    results.append(input)
                }
                if phAssets.count <= resultsCount {
                    DispatchQueue.main.async {
                        completion(results)
                    }
                }
            }
        }
    }
    
    func getImageFolderCount(_ id: String?) -> Int {
        if let localIdentifier = id, !localIdentifier.isEmpty {
            if let phAssetCollection = fetchPHAssetCollection(localIdentifier) {
                let fetchOPtions = PHFetchOptions()
                fetchOPtions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
                return PHAsset.fetchAssets(in: phAssetCollection, options: fetchOPtions).count
            } else {
                return 0
            }
        } else {
            return PHAsset.fetchAssets(with: nil).count
        }
    }

    func getImageFolder(_ sortOrder: PluginSortOrder?, _ completion: @escaping ([PluginFolder]?, _ authorized: Bool) -> Void) {
        photoLibraryAuthorizationStatus(true) { authorization in
            if(authorization) {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.fetchImageFolder(sortOrder) { folders in
                        DispatchQueue.main.async {
                            completion(folders, true)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil, false)
                }
            }
        }
    }

    func fetchImageFolder(_ sortOrder: PluginSortOrder?, _ completion: @escaping ([PluginFolder]) -> Void) {
        let fetchOPtions = PHFetchOptions()
//        if let sortDescriptors = self.sortOrderQuery(sortOrder) {
//            fetchOPtions.sortDescriptors = sortDescriptors
//        }
        
        var folders = [PluginFolder]()
        let userCollections: PHFetchResult<PHCollection> = PHAssetCollection.fetchTopLevelUserCollections(with: fetchOPtions)
        userCollections.enumerateObjects { (phCollection: PHCollection, count, _) in
            if let phAssetCollection = phCollection as? PHAssetCollection {
                folders.append(PluginFolder(
                    id: phAssetCollection.localIdentifier,
                    displayName: phAssetCollection.localizedTitle ?? "",
                    count: phAssetCollection.estimatedAssetCount
                ))
            }
        }
        
        completion(folders)
    }
    
    func getImages(_ id: String?, _ sortOrder: PluginSortOrder?, _ offset: Int?, _ limit: Int?, _ completion: @escaping ([PluginImage], Bool) -> Void) {
        photoLibraryAuthorizationStatus(false) { authorization in
            if(authorization) {
                DispatchQueue.global(qos: .userInitiated).async {
                    var phAssetCollection: PHAssetCollection? = nil
                    if let localIdentifier = id, !localIdentifier.isEmpty {
                        if let collection = self.fetchPHAssetCollection(localIdentifier) {
                            phAssetCollection = collection
                        } else {
                            DispatchQueue.main.async {
                                completion([], true)
                            }
                            return
                        }
                    }
                    
                    var results = [PluginImage]()
                    let fectchLimit: Int?
                    if let _limit = limit {
                        fectchLimit = (offset ?? 0) + _limit
                    } else {
                        fectchLimit = nil
                    }
                    let fetchImagesResults = self.fetchImages(phAssetCollection, sortOrder, fectchLimit)
                    if let _offset = offset {
                        for i in _offset..<fetchImagesResults.count {
                            let phAsset = fetchImagesResults.object(at: i)
                            results.append(PluginImage(
                                            id: phAsset.localIdentifier,
                                            width: phAsset.pixelWidth,
                                            height: phAsset.pixelHeight,
                                            modifyTimeMs: (phAsset.modificationDate?.timeIntervalSince1970 ?? 0) * 1000))
                        }
                    } else {
                        fetchImagesResults.enumerateObjects { (phAsset, int, _) in
                            results.append(PluginImage(
                                            id: phAsset.localIdentifier,
                                            width: phAsset.pixelWidth,
                                            height: phAsset.pixelHeight,
                                            modifyTimeMs: (phAsset.modificationDate?.timeIntervalSince1970 ?? 0) * 1000))
                        }
                    }
                    
                    DispatchQueue.main.async {
                        completion(results, true)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion([], false)
                }
            }
        }
    }
    
    func getImage(_ localIdentifier: String, _ completion: @escaping (PluginImage?) -> Void) {
        photoLibraryAuthorizationStatus(false) { authorization in
            if(authorization) {
                DispatchQueue.main.async {
                    var pluginImage: PluginImage? = nil
                    if let phAsset = self.fetchPHAsset(localIdentifier) {
                        pluginImage = PluginImage(
                            id: phAsset.localIdentifier,
                            width: phAsset.pixelWidth,
                            height: phAsset.pixelHeight,
                            modifyTimeMs: (phAsset.modificationDate?.timeIntervalSince1970 ?? 0) * 1000)
                    }
                    
                    completion(pluginImage)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    func fetchImages(_ collection: PHAssetCollection?, _ sortOrder: PluginSortOrder?, _ limit: Int?) -> PHFetchResult<PHAsset> {
        let fetchOPtions = PHFetchOptions()
        if let sortDescriptors = self.sortOrderQuery(sortOrder) {
            fetchOPtions.sortDescriptors = sortDescriptors
        }
        
        if let fetchLimit = limit {
            fetchOPtions.fetchLimit = fetchLimit
        }

        fetchOPtions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        
        if let phAssetCollection = collection {
            return PHAsset.fetchAssets(in: phAssetCollection, options: fetchOPtions)
        } else {
            return PHAsset.fetchAssets(with: fetchOPtions)
        }
    }
    
    func getImageThumbnail(_ id: String, _ width: Int, _ height: Int, _ completion: @escaping (PluginBitmap?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let phAsset = self.fetchPHAsset(id) {
                let option = PHImageRequestOptions()
                option.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
                self.imageManager.requestImage(
                    for: phAsset,
                    targetSize: CGSize(width: width, height: height),
                    contentMode: .aspectFit,
                    options: option,
                    resultHandler: { (image: UIImage?, info) in
                        let pluginBitmap = PluginBitmap.init(image)
                        DispatchQueue.main.async {
                            completion(pluginBitmap)
                        }
                    })
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    func getImageReadBytes(_ id: String, _ completion: @escaping (Data?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let phAsset = self.fetchPHAsset(id) {
                let option = PHContentEditingInputRequestOptions()
                option.isNetworkAccessAllowed = true

                phAsset.requestContentEditingInput(with: option, completionHandler: { (contentEditingInput, dictInfo) in
                    PHImageManager.default().requestImageData(for: phAsset, options: nil) { (data: Data?, _, _, _) in
                        if let uniformTypeIdentifier = contentEditingInput?.uniformTypeIdentifier, uniformTypeIdentifier == kUTTypeJPEG as String || uniformTypeIdentifier == kUTTypePNG as String {
                            DispatchQueue.main.async {
                                completion(data)
                            }
                        } else if let imageData = data {
                            let uiImage = UIImage(data: imageData)
                            let jpgData = uiImage?.jpegData(compressionQuality: 1.0)
                            DispatchQueue.main.async {
                                completion(jpgData)
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(data)
                            }
                        }
                    }
                })
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    func checkUpdate(_ timeMs: Int) -> Bool {
        return timeMs < Int(modifyTimeMs * 1000)
    }
    
    func getImageInfo(_ id: String, _ completion: @escaping (PluginImageInfo?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let phAsset = self.fetchPHAsset(id) {
                phAsset.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, dictInfo) in
                    DispatchQueue.main.async {
                        completion(PluginImageInfo(
                                    id: phAsset.localIdentifier,
                                    fullPath: contentEditingInput?.fullSizeImageURL?.absoluteString ?? "",
                                    mimeType: contentEditingInput?.uniformTypeIdentifier ?? "",
                                    orientation: Int(contentEditingInput?.fullSizeImageOrientation ?? 0)))
                    }
                })
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    func addImage(_ data: Data, _ folder: String, _ completion: @escaping (Bool) -> Void) {
        photoLibraryAuthorizationStatus(true) { authorization in
            if(authorization) {
                self.findOrCreatePHAssetCollectionWithTitle(folder) { (collection: PHAssetCollection?) in
                    self.addImage(data, collection, completion)
                }
            } else {
                completion(false)
            }
        }
    }
    
    private func addImage(_ data: Data, _ phAssetCollection: PHAssetCollection?, _ completion: @escaping (Bool) -> Void) {
        var placeholderLocalIdentifier: String? = nil
        
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: data, options: nil)
            if let collection = phAssetCollection, let placeholder = creationRequest.placeholderForCreatedAsset {
                placeholderLocalIdentifier = placeholder.localIdentifier
                let enumeration: NSArray = [placeholder]
                PHAssetCollectionChangeRequest(for: collection)?.addAssets(enumeration)
            }
        }, completionHandler: { (succeeded, _) -> Void in
            if succeeded, let localIdentifuer = placeholderLocalIdentifier {
//                let fetchOPtions = PHFetchOptions()
//                fetchOPtions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
//                fetchOPtions.fetchLimit = 1
//                PHAsset.fetchAssets(with: fetchOPtions).enumerateObjects { (pHAsset, _, _) in
//                    print("KKH addImage 3 \(pHAsset.localIdentifier)")
//                }
                
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
    func deleteImage(_ ids: [String], _ completion: @escaping (Bool) -> Void) {
        var assets = [PHAsset]()
        PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil).enumerateObjects { (phAsset, int, _) in
            assets.append(phAsset)
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }, completionHandler: { (success, error) in
            completion(success)
        })
    }
    
    private var recentPHAssetCollection: PHAssetCollection? = nil
    private func findOrCreatePHAssetCollectionWithTitle(_ title: String, _ completion: @escaping (PHAssetCollection?) -> Void) {
        if title.isEmpty {
            completion(nil)
            return
        }
        
        if let pHAssetCollection = recentPHAssetCollection {
            if(pHAssetCollection.localizedTitle == title) {
                print("KKH findOrCreatePHAssetCollectionWithTitle 1")
                completion(pHAssetCollection)
                return
            }
        }
        recentPHAssetCollection = findPHAssetCollectionWithTitle(title)
        if let pHAssetCollection = recentPHAssetCollection {
            print("KKH findOrCreatePHAssetCollectionWithTitle 2")
            completion(pHAssetCollection)
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
        }, completionHandler: { (succeeded, error) -> Void in
            if succeeded {
                print("KKH findOrCreatePHAssetCollectionWithTitle 3")
                self.recentPHAssetCollection = self.findPHAssetCollectionWithTitle(title)
                completion(self.recentPHAssetCollection)
            } else {
                completion(nil)
            }
        })
    }
    
    private func findPHAssetCollectionWithTitle(_ title: String) -> PHAssetCollection? {
        var result: PHAssetCollection? = nil
        let userCollections: PHFetchResult<PHCollection> = PHAssetCollection.fetchTopLevelUserCollections(with: nil)
        userCollections.enumerateObjects { (phCollection: PHCollection, count, _) in
            if let phAssetCollection = phCollection as? PHAssetCollection {
                if(phAssetCollection.localizedTitle == title) {
                    result = phAssetCollection
                }
            }
        }
        return result
    }
}
