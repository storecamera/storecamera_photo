//
//  StoreCameraPluginCameraCaptureDelegate.swift
//  store_camera_plugin_camera
//
//  Created by 김경환 on 2020/10/26.
//

import AVFoundation
import Photos

class StoreCameraPluginCaptureProcessor: NSObject {
    private let ratio: CameraRatio
    private let resolution: CameraResolution
    private let orientation: UIDeviceOrientation
    
    private(set) var requestedPhotoSettings: AVCapturePhotoSettings
    
    private let willCapturePhotoAnimation: () -> Void
       
    lazy var context = CIContext()
    
    private let completionHandler: (StoreCameraPluginCaptureProcessor) -> Void
        
    private var photoData: Data?
    private var photoError: String?

    init(
        ratio: CameraRatio,
        resolution: CameraResolution,
        orientation: UIDeviceOrientation,
        with requestedPhotoSettings: AVCapturePhotoSettings,
        willCapturePhotoAnimation: @escaping () -> Void,
        completionHandler: @escaping (StoreCameraPluginCaptureProcessor) -> Void) {
        self.ratio = ratio
        self.resolution = resolution
        self.orientation = orientation
        self.requestedPhotoSettings = requestedPhotoSettings
        self.willCapturePhotoAnimation = willCapturePhotoAnimation
        self.completionHandler = completionHandler
    }
    
    private func didFinish() {
        completionHandler(self)
    }
    
    func getPhotoData() -> Data? {
        return photoData
    }
    
    func getPhotoError() -> String? {
        return photoError
    }
}

extension StoreCameraPluginCaptureProcessor: AVCapturePhotoCaptureDelegate {
    /*
     This extension adopts all of the AVCapturePhotoCaptureDelegate protocol methods.
     */
    
    /// - Tag: WillBeginCapture
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    }
    
    /// - Tag: WillCapturePhoto
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        willCapturePhotoAnimation()
    }

    /// - Tag: DidFinishProcessingPhoto
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            photoError = "Error capturing photo: \(error)"
        } else {
            photoData = photo.fileDataRepresentation()
        }
    }

    /// - Tag: DidFinishCapture
    /// 1:1 Full : Original
    /// 1:1 Standard : 2048x2048
    /// 1:1 Low : 1024x1024
    /// 4:5 Full : Original
    /// 4:5 Standard : 2048x2560
    /// 4:5 Low : 1024x1280
    /// 3:4 Full : Original
    /// 3:4 Standard : 1536x2048
    /// 3:4 Low : 768x1024
    /// 9:16 Full : Original
    /// 9:16 Standard : 1440x2560
    /// 9:16 Low : 720x1280
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            photoError = "Error capturing photo: \(error)"
            didFinish()
            return
        }
        
        guard let photoData = photoData else {
            if photoError == nil {
                photoError = "No photo data resource"
            }
            didFinish()
            return
        }
        
        DispatchQueue.global(qos: .default).async {
            switch(self.ratio) {
            case .RATIO_1_1:
                switch(self.resolution) {
                case .FULL:
                    self.photoData = self.convert1_1(photoData, nil)
                case .STANDARD:
                    self.photoData = self.convert1_1(photoData, 2048)
                case .LOW:
                    self.photoData = self.convert1_1(photoData, 1024)
                }
            case .RATIO_4_5:
                switch(self.resolution) {
                case .FULL:
                    self.photoData = self.convertBaseOnWidth(photoData, 5.0/4.0, nil)
                case .STANDARD:
                    self.photoData = self.convertBaseOnWidth(photoData, 5.0/4.0, 2048)
                case .LOW:
                    self.photoData = self.convertBaseOnWidth(photoData, 5.0/4.0, 1024)
                }
            case .RATIO_3_4:
                switch(self.resolution) {
                case .FULL:
                    self.photoData = self.convert3_4(photoData, nil, nil)
                case .STANDARD:
                    self.photoData = self.convert3_4(photoData, 1536, 2048)
                case .LOW:
                    self.photoData = self.convert3_4(photoData, 768, 1024)
                }
            case .RATIO_9_16:
                switch(self.resolution) {
                case .FULL:
                    self.photoData = self.convertBaseOoHeight(photoData, 9.0/16.0, nil)
                case .STANDARD:
                    self.photoData = self.convertBaseOoHeight(photoData, 9.0/16.0, 2560)
                case .LOW:
                    self.photoData = self.convertBaseOoHeight(photoData, 9.0/16.0, 1280)
                }
            }
                    
            self.didFinish()
        }
    }
    
    private func convert1_1(_ photoData: Data, _ size: Int?) -> Data? {
        guard let cgImage = UIImage(data: photoData)?.cgImage else {
          return nil
        }
        let bitmapDx: Int
        let bitmapDy: Int
        if cgImage.width > cgImage.height {
            bitmapDx = cgImage.width - cgImage.height
            bitmapDy = 0
        } else {
            bitmapDx = 0
            bitmapDy = cgImage.height - cgImage.width
        }
        let bitmapWidth = cgImage.width - bitmapDx
        let bitmapHeight = cgImage.height - bitmapDy
        let newSize: Int = size ?? bitmapWidth

        guard let cropImage = cgImage.cropping(to: CGRect(x: bitmapDx / 2, y: bitmapDy / 2, width: bitmapWidth, height: bitmapHeight)) else {
            return nil
        }
        
        return CameraUIImageHelper.orientation(
            image: CGImageHelper.resize(image: cropImage, width: newSize, height: newSize),
            orientation: self.orientation
        )?.jpegData(compressionQuality: 1.0)
    }
    
    private func convert3_4(_ photoData: Data, _ width: Int?, _ height: Int?) -> Data? {
        guard let cgImage = UIImage(data: photoData)?.cgImage else {
          return nil
        }

        let targetWidth: Int
        let targetHeight: Int
        if cgImage.width > cgImage.height {
            targetWidth = height ?? cgImage.width
            targetHeight = width ?? cgImage.height
        } else {
            targetWidth = width ?? cgImage.width
            targetHeight = height ?? cgImage.height
        }

        return CameraUIImageHelper.orientation(
            image: CGImageHelper.resizeSmall(image: cgImage, width: targetWidth, height: targetHeight),
            orientation: self.orientation
        )?.jpegData(compressionQuality: 1.0)
    }
    
    private func convertBaseOoHeight(_ photoData: Data, _ ratio: CGFloat, _ size: Int?) -> Data? {
        guard let cgImage = UIImage(data: photoData)?.cgImage else {
          return nil
        }
        let bitmapDx: Int
        let bitmapDy: Int
        var targetWidth: Int = cgImage.width
        var targetHeight: Int = cgImage.height

        if cgImage.width > cgImage.height {
            let _size = size ?? cgImage.width
            bitmapDx = 0
            bitmapDy = Int(CGFloat(cgImage.height) - CGFloat(cgImage.width) * ratio)
            targetWidth = _size
            targetHeight = Int(CGFloat(_size) * ratio)
        } else  {
            let _size = size ?? cgImage.height
            bitmapDx = Int(CGFloat(cgImage.width) - CGFloat(cgImage.height) * ratio)
            bitmapDy = 0
            targetWidth = Int(CGFloat(_size) * ratio)
            targetHeight = _size
        }
        let bitmapWidth = cgImage.width - bitmapDx
        let bitmapHeight = cgImage.height - bitmapDy

        guard let cropImage = cgImage.cropping(to: CGRect(x: bitmapDx / 2, y: bitmapDy / 2, width: bitmapWidth, height: bitmapHeight)) else {
            return nil
        }
        
        return CameraUIImageHelper.orientation(
            image: CGImageHelper.resize(image: cropImage, width: targetWidth, height: targetHeight),
            orientation: self.orientation
        )?.jpegData(compressionQuality: 1.0)
    }
    
    private func convertBaseOnWidth(_ photoData: Data, _ ratio: CGFloat, _ size: Int?) -> Data? {
        guard let cgImage = UIImage(data: photoData)?.cgImage else {
          return nil
        }
        let bitmapDx: Int
        let bitmapDy: Int
        var targetWidth: Int = cgImage.width
        var targetHeight: Int = cgImage.height

        if cgImage.width > cgImage.height {
            let _size = size ?? cgImage.height
            bitmapDx = Int(CGFloat(cgImage.width) - CGFloat(cgImage.height) * ratio)
            bitmapDy = 0
            targetWidth = Int(CGFloat(_size) * ratio)
            targetHeight = _size
        } else  {
            let _size = size ?? cgImage.width
            bitmapDx = 0
            bitmapDy = Int(CGFloat(cgImage.height) - CGFloat(cgImage.width) * ratio)
            targetWidth = _size
            targetHeight = Int(CGFloat(_size) * ratio)
        }
        let bitmapWidth = cgImage.width - bitmapDx
        let bitmapHeight = cgImage.height - bitmapDy

        guard let cropImage = cgImage.cropping(to: CGRect(x: bitmapDx / 2, y: bitmapDy / 2, width: bitmapWidth, height: bitmapHeight)) else {
            return nil
        }
        
        return CameraUIImageHelper.orientation(
            image: CGImageHelper.resize(image: cropImage, width: targetWidth, height: targetHeight),
            orientation: self.orientation
        )?.jpegData(compressionQuality: 1.0)
    }
}

