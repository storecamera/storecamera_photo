//
//  StoreCameraPluginCameraPlatformViewFactory.swift
//  store_camera_plugin_camera
//
//  Created by 김경환 on 2020/10/21.
//

import Foundation

public class StoreCameraPluginCameraPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
    
    static let CHANNEL = "io.storecamera.store_camera_plugin_camera"

    class func methodToIOS(method: String) -> PlatformViewMethod? {
        let split = method["\(CHANNEL)/".endIndex..<method.endIndex]
        return PlatformViewMethod(rawValue: String(split))
    }
    
    class func methodToFlutter(method: FlutterViewMethod) -> String {
        return "\(CHANNEL)/\(method.rawValue)"
    }
    
    private let binaryMessenger: FlutterBinaryMessenger
    
    init(_ binaryMessenger: FlutterBinaryMessenger) {
        self.binaryMessenger = binaryMessenger
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }

    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return StoreCameraPluginCameraPlatformView(binaryMessenger: binaryMessenger, frame: frame, viewId: viewId, args: args)
    }
}

enum PlatformViewMethod: String {
    case ON_PAUSE = "ON_PAUSE"
    case ON_RESUME = "ON_RESUME"
    case CAPTURE = "CAPTURE"
    case CAPTURE_BY_RATIO = "CAPTURE_BY_RATIO"
    case SET_CAMERA_POSITION = "SET_CAMERA_POSITION"
    case SET_TORCH = "SET_TORCH"
    case SET_FLASH = "SET_FLASH"
    case SET_ZOOM = "SET_ZOOM"
    case SET_EXPOSURE = "SET_EXPOSURE"
    case SET_MOTION = "SET_MOTION"
    case ON_TAP = "ON_TAP"
}

enum FlutterViewMethod: String {
    case ON_CAMERA_STATUS = "ON_CAMERA_STATUS"
    case ON_CAMERA_MOTION = "ON_CAMERA_MOTION"
}
