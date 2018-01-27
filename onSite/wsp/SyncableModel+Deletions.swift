//
//  SyncableModel+Deletions.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-07-18.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation


import Foundation
import CoreData
import MagicalRecord
import PromiseKit
import SwiftyJSON



struct DeletionsJSON {
  
  var time: Double
  var id: String
  
  var json: JSON {
    return JSON([
      "id" : id,
      "time" : time
    ])
  }
  
  init(item: JSON) {
    
    self.time =  item["time"].doubleValue
    self.id =  item["id"].stringValue
  }
  
}

extension SyncableModel {
  
  
  static func combineDeletions(_ first: JSON, into: [DeletionsJSON]) -> [DeletionsJSON] {
    
    var res: [DeletionsJSON] = into
    
    if let f = first.array {
      
      for item in f {
        if res.index(where: { $0.id == item["id"].stringValue }) != nil {
          continue
        }
        res.append(DeletionsJSON(item:item))
      }
    }
    
    return res
    
  }
  
  static func deletionsToJSON(_ deletions: [DeletionsJSON]) -> JSON {
    
    let jsons: [JSON] = deletions.map { $0.json }
    return JSON(jsons)
    
    
  }
  
  
  class func mergeDeletions(_ finalJSON: JSON, deletions: [DeletionsJSON]) throws -> JSON {
    
    var ret = finalJSON
    
    for dataType in self.getSyncableData() {
      let type: CoreDataTypes = CoreDataTypes(rawValue: dataType["type"]!)!
      let key = dataType["remote"]!
      let unit: SyncableUnit = SyncableUnit(rawValue: dataType["unit"]!)!
      
      if type == .Entities && unit == .Separate && finalJSON[key].exists() {
        
        var proc: [JSON] = []
        let entityName = dataType["entity"]!
        guard let entity = NSClassFromString(entityName) as? SyncableModel.Type else {
          Config.error("Could not create entity \(entityName)")
          throw Throwable.import
        }
        
        for e in finalJSON[key].arrayValue {
          let id = e[SyncableModel.idField].stringValue
          if let index =  deletions.index(where: { $0.id == id }) {
            let time = deletions[index].time
            if try entity.entityOrChildrenAreNewerThan(e, time: time) {
              Config.info("Found entity \(entityName) for deletion. Not deleting it!")
              proc.append(try entity.mergeDeletions(e, deletions: deletions))
            } else {
              Config.info("Found entity \(entityName) for deletion. Deleting it!")
            }
          } else {
            proc.append( try entity.mergeDeletions(e, deletions: deletions))
          }
        }
        
        ret[key] = JSON(proc)
      }
    }
    
    return ret
    
  }
  
  
  
  class func entityOrChildrenAreNewerThan(_ json: JSON, time: Double) throws -> Bool {
    
    let created = json[SyncableModel.lastModifiedField].doubleValue
    
    if created > time {
      return true
    }
    
    var ret = false
    
    for dataType in self.getSyncableData() {
      let type: CoreDataTypes = CoreDataTypes(rawValue: dataType["type"]!)!
      let key = dataType["remote"]!
      let unit: SyncableUnit = SyncableUnit(rawValue: dataType["unit"]!)!
      
      if type == .Entities && unit == .Separate && json[key].exists() {
        
        let entityName = dataType["entity"]!
        guard let entity = NSClassFromString(entityName) as? SyncableModel.Type else {
          Config.error("Could not create entity \(entityName)")
          throw Throwable.import
        }
        
        for f in json[key].arrayValue {
          ret = try ret || entity.entityOrChildrenAreNewerThan(f, time: time)
        }
      }
    }
    
    return ret
    
  }
  
  
  class func getListOfEntityIds(_ json: JSON) throws -> [String] {
    
    var ids:[String] = [json[SyncableModel.idField].stringValue]
    
    for dataType in self.getSyncableData() {
      let type: CoreDataTypes = CoreDataTypes(rawValue: dataType["type"]!)!
      let key = dataType["remote"]!
      
      switch type {
        
      case .Image, .PDF:
        ids.append(json[key].stringValue)
        
      case .Entity:
        if json[key].exists() {
          let entityName = dataType["entity"]!
          
          guard let entity = NSClassFromString(entityName) as? SyncableModel.Type else {
            Config.error()
            throw Throwable.import
          }
          
          ids += try entity.getListOfEntityIds(json[key])
          
        }
        
      case .Entities:
        let entityName = dataType["entity"]!
        guard let entity = NSClassFromString(entityName) as? SyncableModel.Type else {
          Config.error("Could not create entity \(entityName)")
          throw Throwable.import
        }
      
        for (_, subJson):(String, JSON) in json[key] {
          ids += try entity.getListOfEntityIds(subJson)
        }
        
      default:
        continue
      }
    }
    
    return ids.filter({ $0 != "" })

  }
  
  
  class func getListOfRelationshipIds(_ json: JSON) throws -> [String] {
    
    var ids:[String] = []
    
    for dataType in self.getSyncableData() {
      let type: CoreDataTypes = CoreDataTypes(rawValue: dataType["type"]!)!
      let key = dataType["remote"]!
      
      switch type {
        
      case .Relationship:
        
        ids.append(json[key].stringValue)
        
      case .Entity:
        if json[key].exists() {
          let entityName = dataType["entity"]!
          
          guard let entity = NSClassFromString(entityName) as? SyncableModel.Type else {
            Config.error()
            throw Throwable.import
          }
          
          ids += try entity.getListOfEntityIds(json[key])
          
        }
        
      case .Entities:
        let entityName = dataType["entity"]!
        guard let entity = NSClassFromString(entityName) as? SyncableModel.Type else {
          Config.error("Could not create entity \(entityName)")
          throw Throwable.import
        }
      
        for (_, subJson):(String, JSON) in json[key] {
          ids += try entity.getListOfRelationshipIds(subJson)
        }
        
      default:
        continue
      }
    }
    
    return ids.filter({ $0 != "" })
    
    
  }
  
  
  
}

