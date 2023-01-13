//
//  StroeCameraPluginCameraDeviceDiscoverySession.swift
//  store_camera_plugin_camera
//
//  Created by 김경환 on 2020/10/27.
//

import AVFoundation

class StoreCameraPluginCameraDeviceDiscoverySession {
    
    private let videoDeviceDiscoverySession: AVCaptureDevice.DiscoverySession

    init() {
        if #available(iOS 13.0, *) {
            videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera, .builtInDualWideCamera, .builtInUltraWideCamera, .builtInTripleCamera, ], mediaType: .video, position: .unspecified)
        } else if #available(iOS 11.1, *) {
            videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: .video, position: .unspecified)
        } else {
            videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera,], mediaType: .video, position: .unspecified)
        }
    }
        
    func uniqueDevicePositionsCount() -> Int {
        var uniqueDevicePositions = [AVCaptureDevice.Position]()
        
        for device in videoDeviceDiscoverySession.devices where !uniqueDevicePositions.contains(device.position) {
            Log.i("KKH device \(device.deviceType) \(device.localizedName)")
            Log.dump(device)
            uniqueDevicePositions.append(device.position)
        }
        
        return uniqueDevicePositions.count
    }
    
    func findDevice(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        var preferredDeviceTypes: [AVCaptureDevice.DeviceType] = []
//        if #available(iOS 13.0, *) {
//            preferredDeviceTypes = [.builtInTripleCamera, .builtInUltraWideCamera, .builtInDualWideCamera, .builtInTrueDepthCamera, .builtInDualCamera,  .builtInWideAngleCamera]
//        } else if #available(iOS 11.1, *) {
//            preferredDeviceTypes = [.builtInTrueDepthCamera, .builtInDualCamera,  .builtInWideAngleCamera]
//        } else {
//            preferredDeviceTypes = [.builtInDualCamera,  .builtInWideAngleCamera]
//        }
        preferredDeviceTypes = [.builtInDualCamera,  .builtInWideAngleCamera]
        for type in preferredDeviceTypes {
            let foundDevice = findDevice(position, type)
            if let device = foundDevice {
                return device
            }
        }

        if let device = videoDeviceDiscoverySession.devices.first(where: { $0.position == position }) {
            return device
        }

        return nil
    }
    
    func findDevice(_ position: AVCaptureDevice.Position, _ type: AVCaptureDevice.DeviceType) -> AVCaptureDevice? {
        for device in videoDeviceDiscoverySession.devices where device.position == position {
            if(device.position == position && device.deviceType == type) {
                return device
            }
        }
        return nil
    }
}
