//
//  CGImageHelper.swift
//  store_camera_plugin_camera
//
//  Created by 김경환 on 2020/10/29.
//

class CameraUIImageHelper {
    
    class func fixOrientationUIImage(_ image: UIImage?) -> UIImage? {
        guard let uiImage = image else {
            return image
        }
        UIGraphicsBeginImageContext(uiImage.size)
        uiImage.draw(at: .zero)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()
        return newImage ?? image
    }
 
    class func orientation(image: CGImage?, orientation: UIDeviceOrientation, scale: CGFloat = 1.0) -> UIImage? {
        guard let cgImage = image else {
            return nil
        }

        switch orientation {
        case .portrait:
            return UIImage.init(cgImage: cgImage, scale: scale, orientation: .right)
        case .portraitUpsideDown:
            return UIImage.init(cgImage: cgImage, scale: scale, orientation: .left)
        case .landscapeLeft:
            return UIImage.init(cgImage: cgImage, scale: scale, orientation: .up)
        case .landscapeRight:
            return UIImage.init(cgImage: cgImage, scale: scale, orientation: .down)
        case .faceUp:
            return UIImage.init(cgImage: cgImage, scale: scale, orientation: .down)
        case .faceDown:
            return UIImage.init(cgImage: cgImage, scale: scale, orientation: .down)
        case .unknown:
            return UIImage.init(cgImage: cgImage, scale: scale, orientation: .right)
        @unknown default:
            return UIImage.init(cgImage: cgImage, scale: scale, orientation: .right)
        }
    }
    
    class func orientationAndScale(image: CGImage?, orientation: UIDeviceOrientation, scale: CGFloat) -> UIImage? {
        guard let cgImage = image else {
            return nil
        }

        switch orientation {
        case .portrait:
                        Log.d("portrait")
            return fixOrientationUIImage(UIImage.init(cgImage: cgImage, scale: scale, orientation: .right))
        case .portraitUpsideDown:
                        Log.d("portraitUpsideDown")
            return fixOrientationUIImage(UIImage.init(cgImage: cgImage, scale: scale, orientation: .left))
        case .landscapeLeft:
                        Log.d("landscapeLeft")
            return fixOrientationUIImage(UIImage.init(cgImage: cgImage, scale: scale, orientation: .up))
        case .landscapeRight:
                        Log.d("landscapeRight")
            return fixOrientationUIImage(UIImage.init(cgImage: cgImage, scale: scale, orientation: .down))
        case .faceUp:
                        Log.d("faceUp")
            return fixOrientationUIImage(UIImage.init(cgImage: cgImage, scale: scale, orientation: .down))
        case .faceDown:
                        Log.d("faceDown")
            return fixOrientationUIImage(UIImage.init(cgImage: cgImage, scale: scale, orientation: .down))
        case .unknown:
                        Log.d("unknown")
            return fixOrientationUIImage(UIImage.init(cgImage: cgImage, scale: scale, orientation: .right))
        @unknown default:
                        Log.d("portrait")
            return fixOrientationUIImage(UIImage.init(cgImage: cgImage, scale: scale, orientation: .right))
        }
    }
    
}
