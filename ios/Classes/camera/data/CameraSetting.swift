//
//  CameraSetting.swift
//  store_camera_plugin_camera
//
//  Created by 김경환 on 2020/10/28.
//

import AVFoundation

struct CameraSetting: CameraPluginToMap {
    
    let currentPosition: AVCaptureDevice.Position

    let isTorchAvailable: Bool
    let isFlashAvailable: Bool
    let minZoom: Float
    let maxZoom: Float

    let minExposure: Float
    let maxExposure: Float
    let currentExposure: Float

    func pluginToMap() -> [String : Any] {
        let isTorchAvailable: Bool
        let isFlashAvailable: Bool
        if currentPosition == AVCaptureDevice.Position.back {
            isTorchAvailable = self.isTorchAvailable
            isFlashAvailable = self.isFlashAvailable
        } else {
            isTorchAvailable = false
            isFlashAvailable = false
        }
        
        return [
            "currentPosition": positionToString(self.currentPosition) ?? "",
            "isTorchAvailable": isTorchAvailable,
            "isFlashAvailable": isFlashAvailable,
            "minZoom": minZoom,
            "maxZoom": maxZoom,
            "isExposureAvailable": true,
            "minExposure": minExposure,
            "maxExposure": maxExposure,
            "currentExposure": currentExposure,
        ]
    }
    
    public init(_ device: AVCaptureDevice) {
        self.currentPosition = device.position
        self.isTorchAvailable = device.isTorchAvailable
        self.isFlashAvailable = device.isFlashAvailable
        self.minZoom = Float(device.minAvailableVideoZoomFactor)
        self.maxZoom = Float(device.maxAvailableVideoZoomFactor)
        self.minExposure = device.minExposureTargetBias
        self.maxExposure = device.maxExposureTargetBias
        self.currentExposure = device.exposureTargetBias
    }
}

func positionToString(_ position: AVCaptureDevice.Position) -> String? {
    switch position {
    case .unspecified:
        return nil
    case .back:
        return "BACK"
    case .front:
        return "FRONT"
    @unknown default:
        return nil
    }
}

enum CameraRatio: String {
    case RATIO_1_1 = "1:1"
    case RATIO_4_5 = "4:5"
    case RATIO_3_4 = "3:4"
    case RATIO_9_16 = "9:16"
}

enum CameraResolution: String {
    case FULL = "FULL"
    case STANDARD = "STANDARD"
    case LOW = "LOW"
}

enum CameraFlash: String {
    case OFF = "OFF"
    case ON = "ON"
    case AUTO = "AUTO"
    
    func deviceMode() -> AVCaptureDevice.FlashMode {
        switch self {
        case .OFF:
            return AVCaptureDevice.FlashMode.off
        case .ON:
            return AVCaptureDevice.FlashMode.on
        case .AUTO:
            return AVCaptureDevice.FlashMode.auto
        }
    }
}

enum CameraTorch: String {
    case OFF = "OFF"
    case ON = "ON"
    
    func deviceMode() -> AVCaptureDevice.TorchMode {
        switch self {
        case .OFF:
            return AVCaptureDevice.TorchMode.off
        case .ON:
            return AVCaptureDevice.TorchMode.on
        }
    }
}

enum CameraMotion: String {
    case OFF = "OFF"
    case ON = "ON"
}
