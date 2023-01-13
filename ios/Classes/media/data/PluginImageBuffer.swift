//
//  PluginImageBuffer.swift
//  store_camera_plugin_media
//
//  Created by 김경환 on 2020/12/19.
//

class PluginImageBuffer: MediaPluginToMap {

    let width: Int?
    let height: Int?
    let format: PluginImageFormat
    let buffer: Data
    
    init?(_ format: PluginImageFormat, _ image: UIImage?) {
        guard let uiImage = image else {
            return nil
        }
        self.width = Int(uiImage.size.width)
        self.height = Int(uiImage.size.height)
        self.format = format

        switch format {
        case .BITMAP:
            guard let data = uiImage.cgImage?.dataProvider?.data as Data? else {
                return nil
            }
            self.buffer = data
        case .JPG:
            guard let data = uiImage.jpegData(compressionQuality: 1.0) else {
                return nil
            }
            self.buffer = data
        case .PNG:
            guard let data = uiImage.pngData() else {
                return nil
            }
            self.buffer = data
        }
    }
    
    init?(_ dictionary: [String:Any]?) {
        guard let format = PluginImageFormat.init(rawValue: StoreCameraMediaDictionaryHelper.get(dictionary, "format") ?? ""),
              let data: Data = StoreCameraMediaDictionaryHelper.get(dictionary, "buffer") else {
            return nil
        }
        self.format = format
        self.buffer = data
        self.width = StoreCameraMediaDictionaryHelper.get(dictionary, "width")
        self.height = StoreCameraMediaDictionaryHelper.get(dictionary, "height")
    }
    
    func pluginToMap() -> [String : Any] {
        var map: [String:Any] = [
            "format": format.rawValue,
            "buffer": buffer
        ]
        if let w = width {
            map["width"] = w
        }
        if let h = height {
            map["height"] = h
        }
        
        return map
    }
    
    func uiImage() -> UIImage? {
        switch(format) {
        case .BITMAP:
            if let w = width, let h = height {
                return MediaUIImageHelper.createUIImage(buffer, w, h)
            }
            return nil
        case .JPG, .PNG:
            return UIImage(data: buffer)
        }
    }
}
