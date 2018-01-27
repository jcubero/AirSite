//
//  SyncableModel+Sync.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-06-30.
//  Copyright © 2016 Ubriety. All rights reserved.
//
//

import Foundation
import CoreData
import MagicalRecord
import PromiseKit
import SwiftyJSON


extension SyncableModel {


  class func mergeJSON(_ firstJSON: JSON, optSecondJSON: JSON?) throws -> JSON {
    
    var json = JSON([
      SyncableModel.idField: firstJSON[SyncableModel.idField].stringValue,
      SyncableModel.createdDateField : firstJSON[SyncableModel.createdDateField].doubleValue,
      SyncableModel.lastModifiedField : firstJSON[SyncableModel.lastModifiedField].doubleValue,
      ])
    
    
    var refJson: JSON! = firstJSON
    var otherJson: JSON? = optSecondJSON
    
    if let secondJSON = optSecondJSON {
      
      // if we're merging, make sure we're dealing with the same ids
      if firstJSON[SyncableModel.idField].stringValue != secondJSON[SyncableModel.idField].stringValue {
        Config.error("Non-match: \(firstJSON[SyncableModel.idField].stringValue) -> \(secondJSON[SyncableModel.idField].stringValue)")
        throw Throwable.import
      }
      
      let firstLastModified = firstJSON[SyncableModel.lastModifiedField].doubleValue
      let secondLastModified = secondJSON[SyncableModel.lastModifiedField].doubleValue
      
      
      if secondLastModified > firstLastModified {
        refJson = secondJSON
        otherJson = firstJSON
        json[SyncableModel.lastModifiedField] = JSON(secondLastModified)
      }
      
    }
    
    
    for dataType in self.getSyncableData() {
      let type: CoreDataTypes = CoreDataTypes(rawValue: dataType["type"]!)!
      let key = dataType["remote"]!
      
      switch type {
        
      case .String, .Value, .Dictionary, .User, .Image, .PDF, .Relationship:
        if let data = refJson[key].string {
          json[key].stringValue = data
        }
        
      case .Float:
        if let data = refJson[key].float {
          json[key].floatValue = data
        }
        
      case .Integer:
        if let data = refJson[key].int {
          json[key].intValue = data
        }
        
      case .Boolean:
        if let data = refJson[key].bool {
          json[key].boolValue = data
        }
        
      case .Date:
        if let data = refJson[key].double {
          json[key].doubleValue = data
        }
        
        
      case .Entity:
        
        if refJson[key].exists() {
          let entityName = dataType["entity"]!
          
          guard let entity = NSClassFromString(entityName) as? SyncableModel.Type else {
            Config.error()
            throw Throwable.import
          }
          
          json[key] = try entity.mergeJSON(refJson[key], optSecondJSON: nil)
          
        }
        
      case .Entities:
        
        let unit: SyncableUnit = SyncableUnit(rawValue: dataType["unit"]!)!
        let entityName = dataType["entity"]!
        guard let entity = NSClassFromString(entityName) as? SyncableModel.Type else {
          Config.error("Could not create entity \(entityName)")
          throw Throwable.import
        }
      
        var ret: [JSON] = []
       
        let oJ: JSON? = unit == .Separate ? otherJson?[key] : nil
        let coll: [(JSON, JSON?)] = self.collectEntityJSONObjects(refJson[key], otherJson: oJ)
        
        for (c, o) in coll {
          let sub = try entity.mergeJSON(c, optSecondJSON: o)
          ret.append(sub)
          
        }
        
        json[key] = JSON(ret)
        
      }
    }
    
    return json
    
  }
  
  
  class func collectEntityJSONObjects(_ refJson: JSON, otherJson: JSON?) -> [(JSON, JSON?)] {
    
    var coll: [(JSON, JSON?)] = []
    
    
    for (_, subJson):(String, JSON) in refJson {
      var otherSubJson: JSON?
      if let oj = otherJson {
        for (_, osj):(String, JSON) in oj {
          if osj[SyncableModel.idField] == subJson[SyncableModel.idField] {
            otherSubJson = osj
            break;
          }
        }
      }
      coll.append((subJson, otherSubJson))
    }
    
    if let oj = otherJson {
      for (_, subJson):(String, JSON) in oj {
        var noCounterpart = true
        for (_, osj):(String, JSON) in refJson {
          if osj[SyncableModel.idField] == subJson[SyncableModel.idField] {
            noCounterpart = false
            break;
          }
        }
        if noCounterpart {
          coll.append((subJson, nil))
          
        }
      }
    }
    
    return coll
    
  }
  
  class func createFileManifest(_ refJson: JSON) throws -> [String] {
    
    var files:[String] = []
    
    
    for dataType in self.getSyncableData() {
      let type: CoreDataTypes = CoreDataTypes(rawValue: dataType["type"]!)!
      let key = dataType["remote"]!
      
      switch type {
        
      case .Image, .PDF :
        
        if let data = refJson[key].string {
          files.append(data)
        }
        
      case .Entity:
        
        if refJson[key].exists() {
          let entityName = dataType["entity"]!
          
          guard let entity = NSClassFromString(entityName) as? SyncableModel.Type else {
            Config.error()
            throw Throwable.import
          }
          
          files += try entity.createFileManifest(refJson[key])
          
        }
        
      case .Entities:
        
        let entityName = dataType["entity"]!
        guard let entity = NSClassFromString(entityName) as? SyncableModel.Type else {
          Config.error("Could not create entity \(entityName)")
          throw Throwable.import
        }
      
        for (_, subJson):(String, JSON) in refJson[key] {
          files += try entity.createFileManifest(subJson)
        }
        
      default:
        continue
        
      }
    }
    
    return files
    
  }
  
  
  class func createUserManifest(_ refJson: JSON) throws -> Set<String> {
    
    var users: Set<String> = []
    
    
    for dataType in self.getSyncableData() {
      let type: CoreDataTypes = CoreDataTypes(rawValue: dataType["type"]!)!
      let key = dataType["remote"]!
      
      switch type {
      case .User:
        if let username = refJson[key].string {
          users.insert(username)
        }
        
      case .Entity:
        
        if refJson[key].exists() {
          let entityName = dataType["entity"]!
          
          guard let entity = NSClassFromString(entityName) as? SyncableModel.Type else {
            Config.error()
            throw Throwable.import
          }
          
          users.formUnion(try entity.createUserManifest(refJson[key]))
          
        }
        
      case .Entities:
        
        let entityName = dataType["entity"]!
        guard let entity = NSClassFromString(entityName) as? SyncableModel.Type else {
          Config.error("Could not create entity \(entityName)")
          throw Throwable.import
        }
      
        for (_, subJson):(String, JSON) in refJson[key] {
          users.formUnion(try entity.createUserManifest(subJson))
        }
        
      default:
        continue
        
      }
    }
    
    return users
    
  }
  

  
}
