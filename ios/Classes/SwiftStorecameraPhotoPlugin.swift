import Flutter
import UIKit
import AVFoundation

public class SwiftStorecameraPhotoPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: StoreCameraMediaPluginConfig.CHANNEL_NAME, binaryMessenger: registrar.messenger())
        let instance = SwiftStorecameraPhotoPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        registrar.register(StoreCameraPluginCameraPlatformViewFactory(registrar.messenger()), withId: StoreCameraPluginCameraPlatformViewFactory.CHANNEL)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let method = StoreCameraMediaPluginConfig.methodToIOS(method: call.method) else {
            result(FlutterMethodNotImplemented)
            return
        }
        
        switch method {
        case .GET_IMAGE_FOLDER:
            var sortOrder: PluginSortOrder? = nil
            if let arguments = call.arguments as? [String:Any] {
                sortOrder = PluginSortOrder.init(rawValue: getString(arguments, "sortOrder") ?? "")
            }
            getImageFolder(sortOrder, result)
            
        case .GET_IMAGE_FOLDER_COUNT:
            getImageFolderCount(call.arguments as? String, result)
            
        case .GET_IMAGE_FILES:
            var id: String? = nil
            var sortOrder: PluginSortOrder? = nil
            var offset: Int? = nil
            var limit: Int? = nil
            if let arguments = call.arguments as? [String:Any] {
                id = getString(arguments, "id")
                sortOrder = PluginSortOrder.init(rawValue: getString(arguments, "sortOrder") ?? "")
                offset = getInt(arguments, "offset")
                limit = getInt(arguments, "limit")
            }
            getImages(id, sortOrder, offset, limit, result)
            
        case .GET_IMAGE_FILE:
            if let arguments = call.arguments as? [String:Any], let id: String = getString(arguments, "id") {
                StoreCameraMediaPluinImageQuery.shared.getImage(id) {
                    result($0?.pluginToMap())
                }
            } else {
                result(nil)
            }
            
        case .GET_IMAGE_THUMBNAIL:
            var _id: String? = nil
            var width: Int? = nil
            var height: Int? = nil
            if let arguments = call.arguments as? [String:Any] {
                _id = getString(arguments, "id")
                width = getInt(arguments, "width")
                height = getInt(arguments, "height")
            }
            if let id = _id {
                StoreCameraMediaPluinImageQuery.shared.getImageThumbnail(id, width ?? 256, height ?? 256) { (bitmap: PluginBitmap?) in
                    result(bitmap?.pluginToMap())
                }
            } else {
                result(nil)
            }
            
        case .READ_IMAGE_DATA:
            if let id = call.arguments as? String {
                StoreCameraMediaPluinImageQuery.shared.getImageReadBytes(id) { (data: Data?) in
                    result(data)
                }
            } else {
                result(nil)
            }
            
        case .CHECK_UPDATE:
            if let timeMs = call.arguments as? Int {
                result(StoreCameraMediaPluinImageQuery.shared.checkUpdate(timeMs))
            } else {
                result(true)
            }
            
        case .GET_IMAGE_INFO:
            if let id = call.arguments as? String {
                StoreCameraMediaPluinImageQuery.shared.getImageInfo(id) { (info: PluginImageInfo?) in
                    result(info?.pluginToMap())
                }
            } else {
                result(nil)
            }
            
        case .ADD_IMAGE:
            if let arguments = call.arguments as? [String:Any] {
                let folder = StoreCameraMediaDictionaryHelper.get(arguments, "folder") ?? ""
                if let data: Data = StoreCameraMediaDictionaryHelper.get(arguments, "buffer"), let inputFormat = PluginImageFormat(rawValue: StoreCameraMediaDictionaryHelper.get(arguments, "input") ?? ""), let outputFormat = PluginImageFormat(rawValue: StoreCameraMediaDictionaryHelper.get(arguments, "output") ?? "") {
                    if inputFormat == outputFormat {
                        StoreCameraMediaPluinImageQuery.shared.addImage(data, folder) { (success) in
                            DispatchQueue.main.async {
                                result(success)
                            }
                        }
                        return
                    } else {
                        var inputImage: UIImage? = nil
                        
                        switch inputFormat {
                        case .BITMAP:
                            if let width: Int = StoreCameraMediaDictionaryHelper.get(arguments, "width"), let height: Int = StoreCameraMediaDictionaryHelper.get(arguments, "height") {
                                inputImage = MediaUIImageHelper.createUIImage(data, width, height)
                            }
                            
                        case .JPG, .PNG:
                            inputImage = UIImage(data: data)
                        }
                        
                        switch outputFormat {
                            
                        case .BITMAP:
                            break
                            
                        case .JPG:
                            if let jpgData = inputImage?.jpegData(compressionQuality: 1.0) {
                                StoreCameraMediaPluinImageQuery.shared.addImage(jpgData, folder) { (success) in
                                    DispatchQueue.main.async {
                                        result(success)
                                    }
                                }
                                return
                            }
                            
                        case .PNG:
                            if let pngData = inputImage?.pngData() {
                                StoreCameraMediaPluinImageQuery.shared.addImage(pngData, folder) { (success) in
                                    DispatchQueue.main.async {
                                        result(success)
                                    }
                                }
                                return
                            }
                        }
                    }
                }
            }
            result(false)
            
        case .DELETE_IMAGE:
            if let arguments = call.arguments as? [String] {
                StoreCameraMediaPluinImageQuery.shared.deleteImage(arguments) {
                    if $0 {
                        result(arguments)
                    } else {
                        result([String]())
                    }
                }
                return
            }
            result(false)
            
        case .IMAGE_BUFFER_CONVERTER_WITH_MAX_SIZE:
            if let arguments = call.arguments as? [String:Any], let pluginImageBuffer = PluginImageBuffer.init(arguments) {
                DispatchQueue.global(qos: .userInitiated).async {
                    var image: UIImage? = nil
                    let outputFormat = PluginImageFormat.init(rawValue: StoreCameraMediaDictionaryHelper.get(arguments, "format") ?? "") ?? pluginImageBuffer.format
                    if let uiImage = MediaUIImageHelper.fixOrientationUIImage(pluginImageBuffer.uiImage()) {
                        if let maxWidth: Int = StoreCameraMediaDictionaryHelper.get(arguments, "maxWidth"), let maxHeight: Int = StoreCameraMediaDictionaryHelper.get(arguments, "maxHeight") {
                            let rect = MediaUIImageHelper.centerInsideRect(Int(uiImage.size.width), Int(uiImage.size.height), maxWidth, maxHeight)
                            image = MediaUIImageHelper.resize(image: uiImage, width: rect.width, height: rect.height)
                        } else {
                            image = uiImage
                        }
                    }
                    let buffer = PluginImageBuffer.init(outputFormat, image)
                    DispatchQueue.main.async {
                        result(buffer?.pluginToMap())
                    }
                }
            } else {
                result(nil)
            }
            
        case .SHARE_IMAGE:
            if let arguments = call.arguments as? [String], let window = UIApplication.shared.delegate?.window, let controller:FlutterViewController = window?.rootViewController as? FlutterViewController {
                StoreCameraMediaPluinImageQuery.shared.requestContentEditingInputs(arguments) { (contentEditingInputs) in
                    var shareObject = [Any]()
                    for contentEditingInput in contentEditingInputs {
                        if let url = contentEditingInput.fullSizeImageURL {
                            shareObject.append(url)
                        }
                    }
                    DispatchQueue.main.async {
                        if !shareObject.isEmpty {
                            let activityViewController = UIActivityViewController(activityItems : shareObject, applicationActivities: nil)
                            controller.present(activityViewController, animated: true, completion: nil)
                        }
                        result(true)
                    }
                }
            }
            result(false)
            
        case .HAS_PERMISSION_CAMERA:
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .notDetermined:
                result(PermissionResult.DENIED.rawValue)
            case .restricted:
                result(PermissionResult.DENIED_TO_APP_SETTING.rawValue)
            case .denied:
                result(PermissionResult.DENIED_TO_APP_SETTING.rawValue)
            case .authorized:
                result(PermissionResult.GRANTED.rawValue)
            @unknown default:
                result(PermissionResult.DENIED.rawValue)
            }
        case .REQUEST_PERMISSION_CAMERA:
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                    if granted {
                        result(PermissionResult.GRANTED.rawValue)
                    } else {
                        result(PermissionResult.DENIED_TO_APP_SETTING.rawValue)
                    }
                })
            case .restricted:
                result(PermissionResult.DENIED_TO_APP_SETTING.rawValue)
            case .denied:
                result(PermissionResult.DENIED_TO_APP_SETTING.rawValue)
            case .authorized:
                result(PermissionResult.GRANTED.rawValue)
            @unknown default:
                result(PermissionResult.DENIED.rawValue)
            }
        }
        
    }
    
    func getImageFolder(_ sortOrder: PluginSortOrder?, _ result: @escaping FlutterResult) {
        StoreCameraMediaPluinImageQuery.shared.getImageFolder(sortOrder) { (f: [PluginFolder]?, permission: Bool) in
            if let folders = f, permission {
                var list = [[String:Any]]()
                for folder in folders {
                    list.append(folder.pluginToMap())
                }
                result([
                    "timeMs": Int(Date().timeIntervalSince1970 * 1000),
                    "permission": true,
                    "list": list
                ])
            } else {
                result([
                    "timeMs": Int(Date().timeIntervalSince1970 * 1000),
                    "permission": permission
                ])
            }
        }
    }
    
    func getImageFolderCount(_ id: String?, _ result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            let count = StoreCameraMediaPluinImageQuery.shared.getImageFolderCount(id)
            DispatchQueue.main.async {
                result(count)
            }
        }
    }
    
    func getImages(_ id: String?, _ sortOrder: PluginSortOrder?, _ offset: Int?, _ limit: Int?, _ result: @escaping FlutterResult) {
        StoreCameraMediaPluinImageQuery.shared.getImages(id, sortOrder, offset, limit, { (images: [PluginImage], permission: Bool) in
            var list = [[String:Any]]()
            for image in images {
                list.append(image.pluginToMap())
            }
            
            result([
                "permission": permission,
                "list": list
            ])
        })
    }
}

enum PermissionResult: String {
    case GRANTED = "GRANTED"
    case DENIED = "DENIED"
    case DENIED_TO_APP_SETTING = "DENIED_TO_APP_SETTING"
}


func getInt(_ dict: Dictionary<String, Any>?, _ key: String) -> Int? {
    if let value = dict?[key] as? NSNumber {
        return Int(truncating: value)
    } else if let value = dict?[key] as? String {
        return Int(value)
    }
    return nil
}

func getString(_ dict: Dictionary<String, Any>?, _ key: String) -> String? {
    if let value = dict?[key] as? String {
        return value
    } else if let value = dict?[key] as? NSNumber {
        return value.stringValue
    }
    return nil
}

