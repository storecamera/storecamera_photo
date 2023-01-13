//
//  PluginDataSet.swift
//  zpdl_studio_media_plugin
//
//  Created by 김경환 on 2020/10/12.
//

struct PluginFolder: MediaPluginToMap {
    let id: String
    let displayName: String
    let count: Int

    func pluginToMap() -> [String : Any] {
        return [
            "id": id,
            "displayName": displayName,
            "count": count
        ]
    }
}
