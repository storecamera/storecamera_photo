//
//  PluginImage.swift
//  zpdl_studio_media_plugin
//
//  Created by 김경환 on 2020/10/13.
//

import Foundation

struct PluginImage: MediaPluginToMap {
    let id: String
    let width: Int
    let height: Int
    let modifyTimeMs: TimeInterval

    func pluginToMap() -> [String : Any] {
        return [
            "id": id,
            "width": width,
            "height": height,
            "modifyTimeMs": modifyTimeMs
        ]
    }
}
