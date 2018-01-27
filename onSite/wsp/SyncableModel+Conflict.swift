//
//  SyncableModel+Conflict.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-07-19.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation


extension SyncableModel {
  
  
  func updateLocalKeys() {
    
    self.createNewLocalKey()
    
    for dataType in type(of: self).getSyncableData() {
      let type: CoreDataTypes = CoreDataTypes(rawValue: dataType["type"]!)!
      let key = dataType["local"]!
      
      switch type {
        
      case .Entity, .Image, .PDF:
        
        if self.value(forKey: key) == nil {
          continue
        }
        
        guard let model = self.value(forKey: key) as? SyncableModel else {
          Config.error()
          return
          
        }
        if type == .Entity {
          model.updateLocalKeys()
        } else {
          model.createNewLocalKey()
        }
        
      case .Entities:
        
        let set = self.mutableSetValue(forKey: key)
        
        for item in set {
          
          guard let model = item as? SyncableModel else {
            Config.error()
            return
            
          }
          model.updateLocalKeys()
        }
        
      default:
        continue
        
      }
    }
    
  }
  
  @objc func createNewLocalKey() -> String {
  
    let newKey = ProcessInfo.processInfo.globallyUniqueString as String
    
    self.setValue(newKey, forKey: "localUnique")
    
    return newKey
    
  }
  
}


extension File {
  
  
  override func createNewLocalKey() -> String {
    
    let oldPath = self.path
    
    let newKey = super.createNewLocalKey()
    let newPath = self.path
    
    let fm = Foundation.FileManager.default
    
    do {
      try fm.moveItem(at: oldPath as URL, to: newPath as URL)
    } catch {
      Config.error("Error moving file \(oldPath.path) to \(newPath.path)! This looks like trouble.")
      
    }
   
    
    return newKey
    
  }
  
}
