//
//  StoreCameraPluginCameraPlatformView.swift
//  store_camera_plugin_camera
//
//  Created by 김경환 on 2020/10/21.
//

import AVFoundation

public class StoreCameraPluginCameraPlatformView: NSObject, FlutterPlatformView {

    private let frame: CGRect
    private let viewId: Int64
    private let cameraView: StoreCameraPluginCameraView
    private let methodChannel: FlutterMethodChannel
    
    init(binaryMessenger: FlutterBinaryMessenger, frame: CGRect, viewId: Int64, args: Any?) {
        Log.i("KKH StoreCameraPluginCameraPlatformView init")
        self.frame = frame
        self.viewId = viewId
        self.cameraView = UINib(nibName: "StoreCameraPluginCameraView", bundle: Bundle(for: StoreCameraPluginCameraPlatformView.self)).instantiate(withOwner: nil, options: nil).first as! StoreCameraPluginCameraView
        self.methodChannel = FlutterMethodChannel(name: "\(StoreCameraPluginCameraPlatformViewFactory.CHANNEL)_\(viewId)", binaryMessenger: binaryMessenger)
        super.init()
        
        methodChannel.setMethodCallHandler({ [unowned self] in
            self.onMethodCall($0, $1) })

        if let arguments = args as? [String:Any] {
            initArgs(self.cameraView, arguments)
        }
        
        self.cameraView.onCameraStatus = ({ [unowned self] in
            let status: CameraStatus = $0
            self.methodChannel.invokeMethod(StoreCameraPluginCameraPlatformViewFactory.methodToFlutter(method: FlutterViewMethod.ON_CAMERA_STATUS), arguments: status.pluginToMap())
        })
        self.cameraView.onCameraMotion = ({ [unowned self] in
            self.methodChannel.invokeMethod(StoreCameraPluginCameraPlatformViewFactory.methodToFlutter(method: FlutterViewMethod.ON_CAMERA_MOTION), arguments: $0)
        })
    }
    
    deinit {
        Log.i("KKH StoreCameraPluginCameraPlatformView deinit")
        self.cameraView.onCameraStatus = nil
        self.cameraView.onCameraStatus = nil
    }

    public func view() -> UIView {
        return cameraView
    }
    
    private func initArgs(_ cameraView: StoreCameraPluginCameraView, _ args: [String:Any]) {
        if let position = valueToDevicePosition(args["position"] as? String) {
            cameraView.initDevicePosition = position
        }
    }
    
    private func onMethodCall(_ call: FlutterMethodCall ,_ result: @escaping FlutterResult) {
        guard let method = StoreCameraPluginCameraPlatformViewFactory.methodToIOS(method: call.method) else {
            result(FlutterMethodNotImplemented)
            return
        }
        switch method {
        case .ON_PAUSE:
            cameraView.onPause()
            result(nil)
        case .ON_RESUME:
            cameraView.onResume()
            result(nil)
        case .CAPTURE:
            if let arguments = call.arguments as? [String:Any] {
                if let ratio = CameraRatio(rawValue: (arguments["ratio"] as? String) ?? ""), let resolution = CameraResolution(rawValue: (arguments["resolution"] as? String) ?? "")  {
                    cameraView.capture(ratio, resolution, onSuccess: { data in
                        result(data)
                    }, onError: { error in
                        result(error)
                    })
                    return
                }
            }            
            result(nil)
        case .CAPTURE_BY_RATIO:
            var ratio: Float? = nil
            if let it = call.arguments as? Double {
                ratio = Float(it)
            } else if let it = call.arguments as? Float {
                ratio = it
            }
            if let _ratio = ratio{
                cameraView.captureByRatio(ratio: _ratio, onSuccess: {data in result(data)}, onError: {error in result(error)})
                return
            }
            result(nil)
        case .SET_CAMERA_POSITION:
            if let position = valueToDevicePosition(call.arguments as? String) {
                cameraView.changeCamera(position) { setting in
                    result(setting?.pluginToMap())
                }
            } else {
                result(nil)
            }
        case .SET_TORCH:
            if let it = CameraTorch(rawValue: (call.arguments as? String) ?? "") {
                cameraView.setTorch(it) {
                    result($0)
                }
            } else {
                result(false)
            }
        case .SET_FLASH:
            if let it = CameraFlash(rawValue: (call.arguments as? String) ?? "") {
                cameraView.setFlash(it) {
                    result($0)
                }
            } else {
                result(false)
            }
        case .SET_ZOOM:
            var zoom: CGFloat? = nil
            if let it = call.arguments as? Double {
                zoom = CGFloat(it)
            } else if let it = call.arguments as? Float {
                zoom = CGFloat(it)
            }
            
            if let _zoom = zoom {
                cameraView.setZoom(_zoom)
            }
            result(nil)
        case .SET_EXPOSURE:
            var exposure: Float? = nil
            if let it = call.arguments as? Double {
                exposure = Float(it)
            } else if let it = call.arguments as? Float {
                exposure = it
            }
            if let _exposure = exposure {
                cameraView.setExposure(_exposure)
            }
            result(nil)
        case .SET_MOTION:
            if let it = CameraMotion(rawValue: (call.arguments as? String) ?? "") {
                cameraView.setMotion(it)
            }
            result(nil)
        case .ON_TAP:
            if let arguments = call.arguments as? [String:Any], let dx = arguments["dx"] as? NSNumber, let dy = arguments["dy"] as? NSNumber {
                cameraView.onTap(CGFloat.init(truncating: dx), CGFloat.init(truncating: dy))
            }
            result(nil)
        }
        
    }
    
    private func valueToDevicePosition(_ value: String?) -> AVCaptureDevice.Position? {
        switch value {
        case "BACK":
            return AVCaptureDevice.Position.back
        case "FRONT":
            return AVCaptureDevice.Position.front
        default:
            return nil
        }
    }
}


