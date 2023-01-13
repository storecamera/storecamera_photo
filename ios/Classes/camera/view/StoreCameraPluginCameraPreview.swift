//
//  StoreCameraPluginCameraPreview.swift
//  store_camera_plugin_camera
//
//  Created by 김경환 on 2020/10/22.
//

import UIKit
import AVFoundation

class StoreCameraPluginCameraPreview: UIView {

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        return layer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

}
