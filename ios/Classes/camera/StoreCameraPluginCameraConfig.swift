//
//  StoreCameraPluginCameraConfig.swift
//  store_camera_plugin_camera
//
//  Created by 김경환 on 2022/05/20.
//

import Foundation

class StoreCameraPluginCameraConfig {
    static let CHANNEL_NAME = "io.storecamera.store_camera_plugin_camera"
    
    class func methodToIOS(method: String) -> CameraPlatformMethod? {
        let split = method["\(CHANNEL_NAME)/".endIndex..<method.endIndex]
//        if split.count >= 2 {
//            return PlatformViewMethod(rawValue: String(split[1]))
//        }
        return CameraPlatformMethod(rawValue: String(split))
    }
}

enum CameraPlatformMethod: String {
    case HAS_PERMISSION = "HAS_PERMISSION"
    case REQUEST_PERMISSION = "REQUEST_PERMISSION"
}
