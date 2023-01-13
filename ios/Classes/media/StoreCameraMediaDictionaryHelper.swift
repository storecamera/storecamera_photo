//
//  DictionaryHelper.swift
//  store_camera_plugin_media
//
//  Created by 김경환 on 2020/12/19.
//
import Foundation

class StoreCameraMediaDictionaryHelper {
    class func get(_ dict: Dictionary<String, Any>?, _ key: String) -> Int? {
        if let value = dict?[key] as? NSNumber {
            return Int(truncating: value)
        } else if let value = dict?[key] as? String {
            return Int(value)
        }
        return nil
    }
    
    class func get(_ dict: Dictionary<String, Any>?, _ key: String) -> Double? {
        if let value = dict?[key] as? NSNumber {
            return Double(truncating: value)
        } else if let value = dict?[key] as? String {
            return Double(value)
        }
        return nil
    }

    class func get(_ dict: Dictionary<String, Any>?, _ key: String) -> String? {
        if let value = dict?[key] as? String {
            return value
        } else if let value = dict?[key] as? NSNumber {
            return value.stringValue
        }
        return nil
    }
    
    class func get(_ dict: Dictionary<String, Any>?, _ key: String) -> Data? {
        if let value = dict?[key] as? FlutterStandardTypedData {
            return value.data
        }
        return nil
    }
}

