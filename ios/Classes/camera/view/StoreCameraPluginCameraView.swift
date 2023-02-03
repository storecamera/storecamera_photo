//
//  StoreCameraPluginCameraView.swift
//  store_camera_plugin_camera
//
//  Created by 김경환 on 2020/10/21.
//

import UIKit
import AVFoundation
import Photos
import CoreMotion

class StoreCameraPluginCameraView: UIView {
    
    var onCameraStatus: ((CameraStatus) -> Void)? = nil
    var onCameraMotion: ((Double) -> Void)? = nil
    @IBOutlet weak var preview: StoreCameraPluginCameraPreview!
    
    private var launched = false
    
    private let session = AVCaptureSession()
    private var status = StoreCameraPluginCameraViewStatus.INIT
    private var flash = CameraFlash.AUTO
    private var torch = CameraTorch.OFF
//    private var selectedSemanticSegmentationMatteTypes = [AVSemanticSegmentationMatte.MatteType]()
//    private var livePhotoMode: LivePhotoMode = .off
//    private var depthDataDeliveryMode: DepthDataDeliveryMode = .off
    
    
    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "StoreCameraPluginCameraView session queue")
    
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    private let photoOutput = AVCapturePhotoOutput()
    private var inProgressPhotoCaptureDelegates = [Int64: StoreCameraPluginCaptureProcessor]()
    private var inProgressPhotoCaptureByRatioDelegates = [Int64: StoreCameraPluginCaptureByRatioProcessor]()
   
    private let videoDeviceDiscoverySession = StoreCameraPluginCameraDeviceDiscoverySession()

    public var initDevicePosition: AVCaptureDevice.Position = .unspecified
    
    private let motionManager = CMMotionManager()
    private var motion: CameraMotion = CameraMotion.OFF

    deinit {
        Log.i("KKH StoreCameraPluginCameraView deinit")
//        _setMotion(CameraMotion.OFF)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func onResume() {
        Log.i("KKH : StoreCameraPluginCameraView onResume")
        if(!launched) {
            launched = true
            preview.session = session
            configureSession()
        } else {
            updateStatus(status: StoreCameraPluginCameraViewStatus.SESSION_START) {
                if $0 {
                    self._startRunning()
                    if self.torch == .ON {
                        _ = self._setTorch(self.videoDeviceInput.device, AVCaptureDevice.TorchMode.on)
                    }
                }
            }
            if self.motion == .ON {
                _setMotion(CameraMotion.ON)
            }
        }
    }

    func onPause() {
        updateStatus(status: StoreCameraPluginCameraViewStatus.SESSION_STOP) {
            if $0 {
                self._stopRunning()
                if self.torch == .ON {
                    _ = self._setTorch(self.videoDeviceInput.device, AVCaptureDevice.TorchMode.off)
                }
            }
        }
        if self.motion == .ON {
            _setMotion(CameraMotion.OFF)
        }
    }

    func changeCamera(_ position: AVCaptureDevice.Position, result: @escaping (CameraSetting?) -> Void) {
        currentStatusWidthSessionQueue() { status in
            if(status == StoreCameraPluginCameraViewStatus.SESSION_START) {
                let currentVideoDevice = self.videoDeviceInput.device
                
                if currentVideoDevice.position != position, let videoDevice = self.videoDeviceDiscoverySession.findDevice(position) {
                    do {
                        let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                        
                        self.session.beginConfiguration()
                        
                        // Remove the existing device input first, because AVCaptureSession doesn't support
                        // simultaneous use of the rear and front cameras.
                        self.session.removeInput(self.videoDeviceInput)
                        
                        if self.session.canAddInput(videoDeviceInput) {
                            NotificationCenter.default.removeObserver(self, name: .AVCaptureDeviceSubjectAreaDidChange, object: currentVideoDevice)
                            NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange), name: .AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput.device)
                            
                            self.session.addInput(videoDeviceInput)
                            self.videoDeviceInput = videoDeviceInput
                        } else {
                            self.session.addInput(self.videoDeviceInput)
                        }
                       
                        self.photoOutput.isHighResolutionCaptureEnabled = true
                        if #available(iOS 13.0, *) {
                            self.photoOutput.maxPhotoQualityPrioritization = .quality
                        } else {
                            // Fallback on earlier versions
                        }
                        
                        self.session.commitConfiguration()
                        
                        result(CameraSetting.init(videoDevice))
                        return
                    } catch {
                        print("Error occurred while creating video device input: \(error)")
                    }
                }
            }
            
            result(nil)
        }
    }
    
    func capture(_ ratio: CameraRatio, _ resolution: CameraResolution, onSuccess: @escaping (Data?) -> Void, onError: @escaping (String) -> Void) {
        /*
         Retrieve the video preview layer's video orientation on the main queue before
         entering the session queue. Do this to ensure that UI elements are accessed on
         the main thread and session configuration is done on the session queue.
         */
        let videoPreviewLayerOrientation = preview.videoPreviewLayer.connection?.videoOrientation
        updateStatus(status: .CAPTURE) {
            if !$0 {
                DispatchQueue.main.async {
                    onSuccess(nil)
                }
                return
            }
            
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }

            var photoSettings = AVCapturePhotoSettings()

            // Capture HEIF photos when supported. Enable auto-flash and high-resolution photos.
            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }

            if self.videoDeviceInput.device.position == .back, self.videoDeviceInput.device.isFlashAvailable {
                if self.videoDeviceInput.device.torchMode == .on {
                    photoSettings.flashMode = .off
                } else {
                    photoSettings.flashMode = self.flash.deviceMode()
                }
            }

            photoSettings.isHighResolutionPhotoEnabled = true
            if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
            }

            let photoCaptureProcessor = StoreCameraPluginCaptureProcessor(
                ratio: ratio,
                resolution: resolution,
                orientation: UIDevice.current.orientation,
                with: photoSettings, willCapturePhotoAnimation: {
                // Flash the screen to signal that AVCam took a photo.
                DispatchQueue.main.async {
                    self.preview.videoPreviewLayer.opacity = 0
                    UIView.animate(withDuration: 0.25) {
                        self.preview.videoPreviewLayer.opacity = 1
                    }
                }
            }, completionHandler: { photoCaptureProcessor in
                // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                self.sessionQueue.async {
                    self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                }
                self.updateStatus(status: .SESSION_START) { (success) in

                }
                DispatchQueue.main.async {
                    onSuccess(photoCaptureProcessor.getPhotoData())
                }                
            }
            )

            self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
        }
    }
    
    func captureByRatio(ratio: Float, onSuccess: @escaping (Data?) -> Void, onError: @escaping (String) -> Void) {
        let videoPreviewLayerOrientation = preview.videoPreviewLayer.connection?.videoOrientation
        updateStatus(status: .CAPTURE) {
            if !$0 {
                DispatchQueue.main.async {
                    onSuccess(nil)
                }
                return
            }
            
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }

            var photoSettings = AVCapturePhotoSettings()

            // Capture HEIF photos when supported. Enable auto-flash and high-resolution photos.
            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }

            if self.videoDeviceInput.device.position == .back, self.videoDeviceInput.device.isFlashAvailable {
                if self.videoDeviceInput.device.torchMode == .on {
                    photoSettings.flashMode = .off
                } else {
                    photoSettings.flashMode = self.flash.deviceMode()
                }
            }

            photoSettings.isHighResolutionPhotoEnabled = true
            if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
            }
            
            let photoCaptureProcessor = StoreCameraPluginCaptureByRatioProcessor(
                ratio: ratio,
                orientation: UIDevice.current.orientation,
                with: photoSettings, willCapturePhotoAnimation: {
                // Flash the screen to signal that AVCam took a photo.
                DispatchQueue.main.async {
                    self.preview.videoPreviewLayer.opacity = 0
                    UIView.animate(withDuration: 0.25) {
                        self.preview.videoPreviewLayer.opacity = 1
                    }
                }
            }, completionHandler: { photoCaptureProcessor in
                // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                self.sessionQueue.async {
                    self.inProgressPhotoCaptureByRatioDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                }
                self.updateStatus(status: .SESSION_START) { (success) in

                }
                DispatchQueue.main.async {
                    onSuccess(photoCaptureProcessor.getPhotoData())
                }
            }
            )

            self.inProgressPhotoCaptureByRatioDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
        }
    }
    
    func setTorch(_ cameraTorch: CameraTorch, onSuccess: @escaping (Bool) -> Void) {
        currentStatusWidthSessionQueue() { status in
            if status != StoreCameraPluginCameraViewStatus.SESSION_START {
                DispatchQueue.main.async { onSuccess(false) }
                return
            }
            let updated = self._setTorch(self.videoDeviceInput.device, cameraTorch.deviceMode())
            DispatchQueue.main.async {
                self.torch = cameraTorch
                onSuccess(updated)
            }
        }
    }

    func _setTorch(_ device: AVCaptureDevice, _ mode: AVCaptureDevice.TorchMode) -> Bool {
        if device.isTorchAvailable {
            do {
                try device.lockForConfiguration()
                if device.torchMode != mode {
                    device.torchMode = mode
                }
                
                device.unlockForConfiguration()
                return true
            } catch {
            }
        }
        return false
    }
    
    func setFlash(_ flash: CameraFlash, onSuccess: @escaping (Bool) -> Void) {
        currentStatusWidthSessionQueue() { status in
            if status != StoreCameraPluginCameraViewStatus.SESSION_START {
                DispatchQueue.main.async { onSuccess(false) }
                return
            }
            self.flash = flash
            DispatchQueue.main.async { onSuccess(true) }
        }
    }
    
    func setZoom(_ zoom: CGFloat) {
        currentStatusWidthSessionQueue() { status in
            if status == StoreCameraPluginCameraViewStatus.SESSION_START {
                let device = self.videoDeviceInput.device
                var newZoom: CGFloat = zoom
                if newZoom <= device.minAvailableVideoZoomFactor {
                    newZoom = device.minAvailableVideoZoomFactor
                }
                if newZoom >= device.maxAvailableVideoZoomFactor {
                    newZoom = device.maxAvailableVideoZoomFactor
                }
                
                if newZoom != device.videoZoomFactor {
                    do {
                        try device.lockForConfiguration()
                        device.videoZoomFactor = zoom
                        device.unlockForConfiguration()
                    } catch {
                    }
                }
            }
        }
    }

    func setExposure(_ exposure: Float) {
        currentStatusWidthSessionQueue() { status in
            if status == StoreCameraPluginCameraViewStatus.SESSION_START {
                let device = self.videoDeviceInput.device
                do {
                    try device.lockForConfiguration()
                    device.setExposureTargetBias(exposure, completionHandler: nil)
                    device.unlockForConfiguration()
                } catch {
                    print("Exposure could not be used")
                }
            }
        }
    }

    func setMotion(_ motion: CameraMotion) {
        self.motion = motion
        _setMotion(self.motion)
    }

    private func _setMotion(_ motion: CameraMotion) {
        if motionManager.isDeviceMotionAvailable {
            switch motion {
            case .OFF:
                if motionManager.isDeviceMotionActive {
                    motionManager.stopDeviceMotionUpdates()
                }
            case .ON:
                if !motionManager.isDeviceMotionActive {
                    motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] in
                        if let error = $1 {
                            Log.e("StoreCameraPluginCameraView motionManager error \(error)")
                            return
                        }

                        if let x = $0?.gravity.x, let y = $0?.gravity.y, let onCameraMotion = self?.onCameraMotion {
                            let radians = atan2(x, y) - .pi
                            onCameraMotion(radians)
                        }
                    }
                }
            }
        }
    }
    
    func onTap(_ dx: CGFloat, _ dy: CGFloat) {
        let devicePoint = preview.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: CGPoint.init(x: dx, y: dy))
        focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
    }

    private func focus(with focusMode: AVCaptureDevice.FocusMode,
                       exposureMode: AVCaptureDevice.ExposureMode,
                       at devicePoint: CGPoint,
                       monitorSubjectAreaChange: Bool) {
        currentStatusWidthSessionQueue() { status in
            if status == StoreCameraPluginCameraViewStatus.SESSION_START {
                let device = self.videoDeviceInput.device
                do {
                    try device.lockForConfiguration()
                    
                    /*
                     Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                     Call set(Focus/Exposure)Mode() to apply the new point of interest.
                     */
                    if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                        device.focusPointOfInterest = devicePoint
                        device.focusMode = focusMode
                    }
                    
                    if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                        device.exposurePointOfInterest = devicePoint
                        device.exposureMode = exposureMode
                    }
                    
                    device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                    device.unlockForConfiguration()
                } catch {
                    print("Could not lock device for configuration: \(error)")
                }
            }
        }
    }

    
    private func updateStatus(status: StoreCameraPluginCameraViewStatus, _ didUpdateWithSessionQueue: @escaping (Bool) -> Void) {
        sessionQueue.async {
            switch status {
            case .INIT:
                didUpdateWithSessionQueue(true)
            case .SESSION_CONFIGURE:
                if self.status == .INIT {
                    self.status = .SESSION_CONFIGURE
                    didUpdateWithSessionQueue(true)
                } else {
                    didUpdateWithSessionQueue(false)
                }
            case .SESSION_START:
                if self.status == .SESSION_CONFIGURE || self.status == .SESSION_STOP || self.status == .CAPTURE {
                    self.status = .SESSION_START
                    didUpdateWithSessionQueue(true)
                } else {
                    didUpdateWithSessionQueue(false)
                }
            case .SESSION_STOP:
                if self.status == .SESSION_START || self.status == .CAPTURE {
                    self.status = .SESSION_STOP
                    didUpdateWithSessionQueue(true)
                } else {
                    didUpdateWithSessionQueue(false)
                }
            case .CAPTURE:
                if self.status == .SESSION_START {
                    self.status = .CAPTURE
                    didUpdateWithSessionQueue(true)
                } else {
                    didUpdateWithSessionQueue(false)
                }
            case .NO_HAS_PERMISSION:
                self.status = .NO_HAS_PERMISSION
                didUpdateWithSessionQueue(true)
            case .ERROR:
                self.status = .ERROR
                didUpdateWithSessionQueue(false)
            }
        }
    }

    private func currentStatusWidthSessionQueue(withSessionQueue: @escaping (StoreCameraPluginCameraViewStatus) -> Void) {
        sessionQueue.async {
            withSessionQueue(self.status)
        }
    }

    private func updateStatusError(_ error: String) {
        updateStatus(status: StoreCameraPluginCameraViewStatus.ERROR) {
            if $0 {
                DispatchQueue.main.async {
                    self.onCameraStatus?(CameraStatusError())
                }
            }
        }
    }
    
    private func configureSession() {
        updateStatus(status: StoreCameraPluginCameraViewStatus.SESSION_CONFIGURE) {
            if !$0 { return }

            if let configure = self._configureSession() {
                self.updateStatus(status: StoreCameraPluginCameraViewStatus.SESSION_START) {
                    if !$0 { return }
                    self._startRunning()
                    DispatchQueue.main.async {
                        var availablePosition: [String] = []
                        for position in configure.0 {
                            if let stringPosition = positionToString(position) {
                                availablePosition.append(stringPosition)
                            }
                        }
                        
                        self.onCameraStatus?(CameraStatusBinding(
                            availablePosition: availablePosition,
                            availableMotion: self.motionManager.isDeviceMotionAvailable,
                            setting: configure.1
                        ))
                    }
                }
            } else {
                self.updateStatusError("configureSession Fail")
            }
        }
    }

    private func _configureSession() -> ([AVCaptureDevice.Position], CameraSetting)? {
        var availablePosition: [AVCaptureDevice.Position] = []
        
        session.beginConfiguration()

        /*
         Do not create an AVCaptureMovieFileOutput when setting up the session because
         Live Photo is not supported when AVCaptureMovieFileOutput is added to the session.
         */
        session.sessionPreset = .photo
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            let backDevice = videoDeviceDiscoverySession.findDevice(AVCaptureDevice.Position.back)
            let frontDevice = videoDeviceDiscoverySession.findDevice(AVCaptureDevice.Position.front)

            // Choose the back dual camera, if available, otherwise default to a wide angle camera.
            switch initDevicePosition {
            case .unspecified:
                defaultVideoDevice = backDevice ?? frontDevice
            case .back:
                defaultVideoDevice = backDevice ?? frontDevice
            case .front:
                defaultVideoDevice = frontDevice ?? backDevice
            @unknown default:
                defaultVideoDevice = backDevice ?? frontDevice
            }
            
            guard let videoDevice = defaultVideoDevice else {
                Log.e("StoreCameraPluginCameraView : Default video device is unavailable.")
                session.commitConfiguration()
                return nil
            }
            if let device = backDevice {
                availablePosition.append(device.position)
            }
            if let device = frontDevice {
                availablePosition.append(device.position)
            }

            Log.i("KKH videoDevice type : \(videoDevice.deviceType)")
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
//            for format in videoDevice.formats {
//                Log.i("KKH \(format.formatDescription)")
//            }
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    /*
                     Dispatch video streaming to the main queue because AVCaptureVideoPreviewLayer is the backing layer for PreviewView.
                     You can manipulate UIView only on the main thread.
                     Note: As an exception to the above rule, it's not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                     
                     Use the window scene's orientation as the initial video orientation. Subsequent orientation changes are
                     handled by CameraViewController.viewWillTransition(to:with:).
                     */
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    let statusBarOrientation = UIApplication.shared.statusBarOrientation
                    if statusBarOrientation != UIInterfaceOrientation.unknown {
                        initialVideoOrientation = AVCaptureVideoOrientation(rawValue: statusBarOrientation.rawValue)!
                    }
                    self.preview.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                Log.e("StoreCameraPluginCameraView : Couldn't add video device input to the session.")
                session.commitConfiguration()
                return nil
            }
        } catch {
            Log.e("StoreCameraPluginCameraView : Couldn't create video device input: \(error)")
            session.commitConfiguration()
            return nil
        }

        // Add the photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            if #available(iOS 13.0, *) {
                photoOutput.maxPhotoQualityPrioritization = .quality
            } else {
                // Fallback on earlier versions
            }
        } else {
            Log.e("StoreCameraPluginCameraView : Could not add photo output to the session")
            session.commitConfiguration()
            return nil
        }

        session.commitConfiguration()
//        do {
//            try videoDeviceInput.device.lockForConfiguration()
////            videoDeviceInput.device.isExposureModeSupported(AVCaptureDevice.ExposureMode)
//            Log.i("KKH minExposureTargetBias \(videoDeviceInput.device.minExposureTargetBias) \(videoDeviceInput.device.maxExposureTargetBias)")
//            videoDeviceInput.device.setExposureTargetBias(2.0, completionHandler: nil)
//            videoDeviceInput.device.unlockForConfiguration()
//        } catch {
//            print("Exposure could not be used")
//        }
        
        return (availablePosition, CameraSetting.init(videoDeviceInput.device))
    }
    
    private func _startRunning() {
        self.addObservers()
        self.session.startRunning()
    }
    
    private func _stopRunning() {
        self.session.stopRunning()
        self.removeObservers()
    }
    
    private var keyValueObservations = [NSKeyValueObservation]()
    private func addObservers() {
        let keyValueObservation = session.observe(\.isRunning, options: .new) { _, change in
//            guard let isSessionRunning = change.newValue else { return }
//            DispatchQueue.main.async {
//                Log.i("StoreCameraPluginCameraView session.observe isRunning")
//                // Only enable the ability to change camera if the device has more than one camera.
//
//            }
        }
        keyValueObservations.append(keyValueObservation)
                
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(subjectAreaDidChange),
                                               name: .AVCaptureDeviceSubjectAreaDidChange,
                                               object: videoDeviceInput.device)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionRuntimeError),
                                               name: .AVCaptureSessionRuntimeError,
                                               object: session)

    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        
        for keyValueObservation in keyValueObservations {
            keyValueObservation.invalidate()
        }
        keyValueObservations.removeAll()
    }

    @objc
    func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }
    
    @objc
    func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        
        print("Capture session runtime error: \(error)")
        // If media services were reset, and the last start succeeded, restart the session.
        if error.code == .mediaServicesWereReset {
            resumeInterruptedSession()
        } else {
            updateStatusError("Capture session runtime error: \(error)")
        }
    }
    
    func resumeInterruptedSession() {
        currentStatusWidthSessionQueue { (status) in
            if self.status == .SESSION_START {
                self.session.startRunning()
                if !self.session.isRunning {
                    self.updateStatusError("resumeInterruptedSession Fail")
                }
            }
        }
    }
}

enum StoreCameraPluginCameraViewStatus {
    case INIT
    case SESSION_CONFIGURE
    case SESSION_START
    case SESSION_STOP
    case CAPTURE
    case NO_HAS_PERMISSION
    case ERROR
}
