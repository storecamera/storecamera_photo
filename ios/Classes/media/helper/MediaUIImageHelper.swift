//
//  UIImageHelper.swift
//  store_camera_plugin_media
//
//  Created by 김경환 on 2020/12/19.
//

class MediaUIImageHelper {
    class func createUIImage(_ data: Data, _ width: Int, _ height: Int) -> UIImage? {
        if let cgImage = createCGImage(width, height, data) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    class func createCGImage(_ width: Int, _ height: Int, _ data: Data) -> CGImage? {
        if let providerRef = CGDataProvider.init(data: data as NSData) {
            return CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: 4 * width,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue),
                provider: providerRef,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
            )
        }
        return nil
    }
    
    class func centerInsideRect(_ srcWidth: Int, _ srcHeight: Int, _ tarWidth: Int, _ tarHeight: Int) -> (dx: Int, dy: Int, width: Int, height: Int) {
        if srcWidth == tarWidth, srcHeight == tarHeight {
            return (0, 0, srcWidth, srcHeight)
        }

        let sourceWidth = Double(srcWidth)
        let sourceHeight = Double(srcHeight)
        let targetWidth = Double(tarWidth)
        let targetHeight = Double(tarHeight)
        let sourceRatio: Double = sourceWidth / sourceHeight
        let targetRatio: Double = targetWidth / targetHeight
        if(sourceRatio < targetRatio) {
            let width = sourceWidth * targetHeight / sourceHeight
            return (
                dx: Int((targetWidth - width) / 2),
                dy: 0,
                width: Int(width),
                height: Int(targetHeight)
            )
        } else {
            let height = sourceHeight * targetWidth / sourceWidth
            return (
                dx: 0,
                dy: Int((targetHeight - height) / 2),
                width: Int(targetWidth),
                height: Int(height)
            )
        }
    }
    
    class func resize(image uiImage: UIImage?, width w: Int?, height h: Int?) -> UIImage? {
        guard let cgImage = uiImage?.cgImage else {
            return uiImage
        }
        
        if let result = resize(image: cgImage, width: w, height: h) {
            return UIImage(cgImage: result)
        }
        
        return nil
    }
    
    class func resize(image cgImage: CGImage?, width w: Int?, height h: Int?) -> CGImage? {
        guard let image = cgImage, let width = w, let height = h else {
            return cgImage
        }
        
        if image.width == width && image.height == height {
            return image
        }
        
        guard let context = cgContext(width, height) else {
            return image
        }
        context.interpolationQuality = .high
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)

        context.draw(image, in: CGRect(origin:.zero, size:CGSize(width: width, height: height)))
        return context.makeImage()
    }
    
    class func fixOrientationUIImage(_ image: UIImage?) -> UIImage? {
        if let uiImage = image, uiImage.imageOrientation != UIImage.Orientation.up {
            UIGraphicsBeginImageContext(uiImage.size)
            uiImage.draw(at: .zero)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()

            UIGraphicsEndImageContext()
            return newImage ?? image
        }
        return image
    }
}
