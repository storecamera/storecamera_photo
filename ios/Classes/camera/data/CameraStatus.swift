//
//  StoreCameraPluginCameraStatus.swift
//  store_camera_plugin_camera
//
//  Created by 김경환 on 2020/10/22.
//

protocol CameraStatus: CameraPluginToMap {
    var type: CameraStatusType { get }
}

enum CameraStatusType: String {
    case BINDING = "BINDING"
    case ERROR = "ERROR"
}

struct CameraStatusBinding: CameraStatus {
    let type: CameraStatusType = CameraStatusType.BINDING
    let availablePosition: [String]
    let availableMotion: Bool
    let setting: CameraSetting
    
    func pluginToMap() -> [String : Any] {
        return [
            "type": type.rawValue,
            "availablePosition": availablePosition,
            "availableMotion": availableMotion,
            "setting": setting.pluginToMap()
        ]
    }
}

struct CameraStatusError: CameraStatus {
    let type: CameraStatusType = CameraStatusType.ERROR

    func pluginToMap() -> [String : Any] {
        return [
            "type": type.rawValue
        ]
    }
}
