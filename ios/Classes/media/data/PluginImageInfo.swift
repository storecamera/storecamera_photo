//
//  PluginImageInfo.swift
//  zpdl_studio_media_plugin
//
//  Created by 김경환 on 2020/10/15.
//

struct PluginImageInfo: MediaPluginToMap {
    let id: String
    let fullPath: String
    let mimeType: String
    let orientation: Int

    func pluginToMap() -> [String : Any] {
        return [
            "fullPath": fullPath,
            "displayName": id,
            "mimeType": mimeType,
            "orientation": orientation,
        ]
    }
}
