//
//  PluginBitmap.swift
//  zpdl_studio_media_plugin
//
//  Created by 김경환 on 2020/10/13.
//

import Foundation

class PluginBitmap: MediaPluginToMap {
    let width: Int
    let height: Int
    let buffer: CFData
    
    init(_ width: Int, _ height: Int, _ buffer: CFData) {
        self.width = width
        self.height = height
        self.buffer = buffer
    }
    
    convenience init?(_ image: UIImage?) {
        if let cgImage = PluginBitmap.cgImageWithRGBA(image?.cgImage), let data = cgImage.dataProvider?.data {
            self.init(cgImage.width, cgImage.height, data)
        } else {
            return nil
        }
    }
    
    func pluginToMap() -> [String : Any] {
        return [
            "width": width,
            "height": height,
            "buffer": buffer
        ]
    }
    
    class func getPixelFormat(_ bitmapInfo: CGBitmapInfo) -> PixelFormat? {
        let alphaInfo: CGImageAlphaInfo? = CGImageAlphaInfo(rawValue: bitmapInfo.rawValue & type(of: bitmapInfo).alphaInfoMask.rawValue)
        let alphaFirst: Bool = alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst
        let alphaLast: Bool = alphaInfo == .premultipliedLast || alphaInfo == .last || alphaInfo == .noneSkipLast
        let endianLittle: Bool = bitmapInfo.contains(.byteOrder32Little)

        // This is slippery… while byte order host returns little endian, default bytes are stored in big endian
        // format. Here we just assume if no byte order is given, then simple RGB is used, aka big endian, though…

        if alphaFirst && endianLittle {
            return .BGRA
        } else if alphaFirst {
            return .ARGB
        } else if alphaLast && endianLittle {
            return .ABGR
        } else if alphaLast {
            return .RGBA
        } else {
            return nil
        }
    }
    
    class func cgImageWithRGBA(_ image: CGImage?) -> CGImage? {
        guard let cgImage = image else {
            return image
        }
        
        if let pixelFormat = getPixelFormat(cgImage.bitmapInfo) {
            if(pixelFormat == PixelFormat.RGBA) {
                return cgImage
            }
        }
        
        guard let context = cgContext(cgImage.width, cgImage.height) else {
            return cgImage
        }
        
        context.draw(cgImage, in: CGRect.init(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        if let makeImage = context.makeImage() {
            return makeImage
        }
        return image
    }
}

enum PixelFormat {
    case ABGR
    case ARGB
    case BGRA
    case RGBA
}

func getPixelFormat(_ bitmapInfo: CGBitmapInfo) -> PixelFormat? {
    let alphaInfo: CGImageAlphaInfo? = CGImageAlphaInfo(rawValue: bitmapInfo.rawValue & type(of: bitmapInfo).alphaInfoMask.rawValue)
    let alphaFirst: Bool = alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst
    let alphaLast: Bool = alphaInfo == .premultipliedLast || alphaInfo == .last || alphaInfo == .noneSkipLast
    let endianLittle: Bool = bitmapInfo.contains(.byteOrder32Little)

    // This is slippery… while byte order host returns little endian, default bytes are stored in big endian
    // format. Here we just assume if no byte order is given, then simple RGB is used, aka big endian, though…

    if alphaFirst && endianLittle {
        return .BGRA
    } else if alphaFirst {
        return .ARGB
    } else if alphaLast && endianLittle {
        return .ABGR
    } else if alphaLast {
        return .RGBA
    } else {
        return nil
    }
}

func cgContext(_ width: Int, _ height: Int) -> CGContext? {
    return CGContext.init(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: (8 * 4 * width + 7)/8,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
}
