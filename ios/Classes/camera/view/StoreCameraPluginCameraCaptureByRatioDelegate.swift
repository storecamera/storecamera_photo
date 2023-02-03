//
//  StoreCameraPluginCameraCaptureByRatioDelegate.swift
//  storecamera_photo
//
//  Created by Berry Park on 2023/02/02.
//


import AVFoundation
import Photos

class StoreCameraPluginCaptureByRatioProcessor: NSObject {
    private let ratio: Float
    private let orientation: UIDeviceOrientation
    
    private(set) var requestedPhotoSettings: AVCapturePhotoSettings
    
    private let willCapturePhotoAnimation: () -> Void
       
    lazy var context = CIContext()
    
    private let completionHandler: (StoreCameraPluginCaptureByRatioProcessor) -> Void
        
    private var photoData: Data?
    private var photoError: String?

    init(
        ratio: Float,
        orientation: UIDeviceOrientation,
        with requestedPhotoSettings: AVCapturePhotoSettings,
        willCapturePhotoAnimation: @escaping () -> Void,
        completionHandler: @escaping (StoreCameraPluginCaptureByRatioProcessor) -> Void) {
        self.ratio = ratio
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

extension StoreCameraPluginCaptureByRatioProcessor: AVCapturePhotoCaptureDelegate {
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
        
        DispatchQueue.global().async {
            self.photoData = self.ratioBasedConversion(photoData: photoData, ratio: self.ratio)
            self.didFinish()
        }
    }
    
    private func ratioBasedConversion(photoData: Data, ratio: Float) -> Data? {
        Log.i("##### ratioBasedConversion")
        let clipRatio = 1.0 / ratio
        guard let sourceImage = UIImage(data: photoData)?.cgImage else {return nil}
        let clipFrame = sizeToFitSourceByRatio(ratio: Float(clipRatio), originalWidth: sourceImage.width, originalHeight: sourceImage.height)
        let firstPixelInSource = (x: (sourceImage.width - clipFrame.width) / 2, y: (sourceImage.height - clipFrame.height) / 2)
        guard let clippedImage = sourceImage.cropping(to: CGRect(x:firstPixelInSource.x, y:firstPixelInSource.y,
                                                                 width:clipFrame.width, height:clipFrame.height)) else {return nil}
        
        Log.i("###### Source image size: \(sourceImage.width), \(sourceImage.height)")
        Log.i("###### Clip Frame: \(clipFrame)")
        Log.i("###### First pixel in source \(firstPixelInSource)")
        
        return CameraUIImageHelper.orientation(
            image: CGImageHelper.resize(image: clippedImage, width: clipFrame.width, height: clipFrame.height),
            orientation: self.orientation)?.jpegData(compressionQuality: 1.0)
    }
    
    private func sizeToFitSourceByRatio(ratio: Float, originalWidth: Int, originalHeight: Int) -> (width: Int, height: Int) {
        let sourceSize  = (width: Float(originalWidth), height: Float(originalHeight))
        let sourceSlope = sourceSize.height / sourceSize.width
        let clipSize = ratio > sourceSlope ? (width: sourceSize.width, height: sourceSize.width / ratio)
                                           : (width: sourceSize.height * ratio, height: sourceSize.height)
        return (Int(clipSize.width + 0.5), Int(clipSize.height + 0.5))
    }
}

