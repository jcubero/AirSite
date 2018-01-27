//
//  SyncableModel+ToJSON.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-06-29.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
import SwiftyJSON
import MagicalRecord


extension SyncableModel {
  
  
  func toRemote() -> JSON {
    
    var returnToServer: JSON = [:]
    
    returnToServer[SyncableModel.idField].stringValue = self.localId
    
    if let createdDate = self.createdDate {
      returnToServer[SyncableModel.createdDateField].double = createdDate.timeIntervalSince1970
    }
    
    if let lastModified = self.lastModified {
      returnToServer[SyncableModel.lastModifiedField].double = lastModified.timeIntervalSince1970
    }
    
    
    for dataType in type(of: self).getSyncableData() {
      let type: CoreDataTypes = CoreDataTypes(rawValue: dataType["type"]!)!
      let key = dataType["local"]!
      let remoteKey = dataType["remote"]!
      
      switch type {
        
      case .String:
        if let data = self.value(forKey: key) as? String {
          returnToServer[remoteKey].string = data
        }
        
      case .Image, .PDF:
        if let file = self.value(forKey: key) as? File {
          let data = file.localId
          returnToServer[remoteKey].string = data
        }
        
      case .Float:
        if let data = self.value(forKey: key) as? NSNumber {
          returnToServer[remoteKey].float = data.floatValue
        }
        
      case .Integer:
        if let data = self.value(forKey: key) as? NSNumber {
          returnToServer[remoteKey].int = data.intValue
        }
        
      case .Boolean:
        if let data = self.value(forKey: key) as? NSNumber {
          returnToServer[remoteKey].bool = data.boolValue
        }
        
      case .Date:
        if let data = self.value(forKey: key) as? Date {
          returnToServer[remoteKey].doubleValue = data.timeIntervalSince1970
        }
        
      case .Value:
        if let value = self.value(forKey: key) as? NSValue {
          let data = NSKeyedArchiver.archivedData(withRootObject: value)
          returnToServer[remoteKey].stringValue = data.base64EncodedString(options: .lineLength64Characters)
        }
        
      case .Dictionary:
        if let value = self.value(forKey: key) as? NSDictionary {
          let data = NSKeyedArchiver.archivedData(withRootObject: value)
          returnToServer[remoteKey].stringValue = data.base64EncodedString(options: .lineLength64Characters)
        }
        
      case .User:
        if let value = self.value(forKey: key) as? User {
          returnToServer[remoteKey].stringValue = value.username!
        }
        
      case .Entity:
        if let data = self.value(forKey: key) as? SyncableModel {
          returnToServer[remoteKey] = data.toRemote()
        }
        
      case .Entities:
        if let data = self.value(forKey: key) as? NSSet {
          var array: [JSON] = []
          let models = data.allObjects as! [SyncableModel]
          for mod in models {
            array.append(mod.toRemote())
          }
          returnToServer[remoteKey].arrayObject = array.map { $0.object }
        }
        
      case .Relationship:
        if let data = self.value(forKey: key) as? SyncableModel {
          returnToServer[remoteKey].stringValue = data.localId
        }
        
      }
    }
    
    return returnToServer
    
  }
  
  
  
}
