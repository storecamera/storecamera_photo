//
//  CGImageHelper.swift
//  store_camera_plugin_camera
//
//  Created by 김경환 on 2020/10/30.
//

import Foundation

class CGImageHelper {
    class func cgContext(_ width: Int, _ height: Int) -> CGContext? {
        return CGContext.init(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: (8 * 4 * width + 7)/8,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
    }
    
    class func resizeSmall(image cgImage: CGImage?, width w: Int?, height h: Int?) -> CGImage? {
        guard let image = cgImage, let width = w, let height = h else {
            return cgImage
        }
        
        if image.width <= width && image.height <= height {
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
}
