//
//  ZpdlStudioMediaPluginConfig.swift
//  zpdl_studio_media_plugin
//
//  Created by 김경환 on 2020/10/12.
//

import Foundation

class StoreCameraMediaPluginConfig {
    static let CHANNEL_NAME = "io.storecamera.store_camera_plugin_media"
   
    class func methodToIOS(method: String) -> MediaPlatformMethod? {
        let split = method.split(separator: "/")
        if split.count >= 2 {
            return MediaPlatformMethod(rawValue: String(split[1]))
        }
        return nil
    }
}

enum MediaPlatformMethod: String {
    case GET_IMAGE_FOLDER = "GET_IMAGE_FOLDER"
    case GET_IMAGE_FOLDER_COUNT = "GET_IMAGE_FOLDER_COUNT"
    case GET_IMAGE_FILES = "GET_IMAGE_FILES"
    case GET_IMAGE_FILE = "GET_IMAGE_FILE"
    case GET_IMAGE_THUMBNAIL = "GET_IMAGE_THUMBNAIL"
    case READ_IMAGE_DATA = "READ_IMAGE_DATA"
    case CHECK_UPDATE = "CHECK_UPDATE"
    case GET_IMAGE_INFO = "GET_IMAGE_INFO"
    case ADD_IMAGE = "ADD_IMAGE"
    case DELETE_IMAGE = "DELETE_IMAGE"
    case IMAGE_BUFFER_CONVERTER_WITH_MAX_SIZE = "IMAGE_BUFFER_CONVERTER_WITH_MAX_SIZE"
    case SHARE_IMAGE = "SHARE_IMAGE"
    case HAS_PERMISSION_CAMERA = "HAS_PERMISSION_CAMERA"
    case REQUEST_PERMISSION_CAMERA = "REQUEST_PERMISSION_CAMERA"
}
