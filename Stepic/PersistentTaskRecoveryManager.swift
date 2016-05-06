//
//  PersistentTaskRecoveryManager.swift
//  Stepic
//
//  Created by Alexander Karpov on 06.05.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Foundation

/*
 Strategy class for recovering the correct task from store
 */
class PersistentTaskRecoveryManager {
    private init() {}
    static let sharedManager = PersistentTaskRecoveryManager()
    
    var plistPath : String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = "\(documentsPath)/Tasks.plist"
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            try! NSFileManager.defaultManager().copyItemAtPath("\(NSBundle.mainBundle().bundlePath)/Tasks.plist", toPath: path)
        }
        return path
    }
    
    private func loadTaskObjectWithName(name: String) -> [String: AnyObject] {
        let plistData = NSDictionary(contentsOfFile: plistPath)!
        return plistData[name] as! [String: AnyObject]
    }
    
    func loadTaskWithName(name: String) -> Executable? {
        let object = loadTaskObjectWithName(name)
        let typeStringOrNil = object["type"] as? String
        if let type = ExecutableTaskType(rawValue: typeStringOrNil ?? "") {
            
            switch type {
            case .DeleteDevice: 
                return  DeleteDeviceExecutableTask(dictionary: object)
            }
            
        } else {
            return nil
        }
    }
    
    func writeTaskWithName(name: String, object: DictionarySerializable) {
        let plistData = NSDictionary(contentsOfFile: plistPath)!
        plistData.setValue(object.serializeToDictionary(), forKey: name)
        plistData.writeToFile(plistPath, atomically: true)
    }
}