//
//  Log.swift
//  store_camera_plugin_camera
//
//  Created by 김경환 on 2020/10/22.
//

import os.log

class Log {
    class func d(_ message: String, filename: String = #file, line: Int = #line, funcName: String = #function) {
        Swift.print("\(Date()) \(filename.components(separatedBy: "/").last ?? ""):\(funcName) \(line) \(message)")
//        os_log(.debug, "%@", message)
    }
    
    class func i(_ message: String, filename: String = #file, line: Int = #line, funcName: String = #function) {
        Swift.print("\(Date()) \(filename.components(separatedBy: "/").last ?? ""):\(funcName) \(line) \(message)")
//        os_log(.info, "%@", message)
    }
    
    class func e(_ message: String, filename: String = #file, line: Int = #line, funcName: String = #function) {
        Swift.print("\(Date()) \(filename.components(separatedBy: "/").last ?? ""):\(funcName) \(line) \(message)")
//        os_log(.error, "%@", message)
    }
    
    class func dump(_ value: Any, name: String? = nil) {
        Swift.dump(value, name: name)
    }
}

