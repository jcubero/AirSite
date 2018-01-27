//
//  SyncableModel+FromJSON.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-06-29.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord
import PromiseKit
import SwiftyJSON

extension SyncableModel {


  func toLocal(_ remoteData: JSON, context : NSManagedObjectContext, files: [FileStruct], project: Project, preservingFileKeys: Bool) throws {


    var localUnique = remoteData[SyncableModel.idField].stringValue
    if localUnique == "" {
      Config.warn("Filling in missing unique value in entity: \(type(of: self))")
      localUnique = ProcessInfo.processInfo.globallyUniqueString as String
    }
    
    
    self.setPrimitiveValue(localUnique, forKey: "localUnique")

    if remoteData[SyncableModel.lastModifiedField].doubleValue > 0 {
      self.lastModified = Date(timeIntervalSince1970: remoteData[SyncableModel.lastModifiedField].doubleValue)
    } else {
      self.lastModified = Date()
    }

    if remoteData[SyncableModel.createdDateField].doubleValue > 0 {
      self.createdDate = Date(timeIntervalSince1970: remoteData[SyncableModel.createdDateField].doubleValue)
    } else {
      self.createdDate = Date()
    }


    for dataType in type(of: self).getSyncableData() {
      let type: CoreDataTypes = CoreDataTypes(rawValue: dataType["type"]!)!
      let key = dataType["local"]!
      let remoteKey = dataType["remote"]!
      
      switch type {
        
      case .String:
        if let data = remoteData[remoteKey].string {
          self.setValue(data, forKey: key)
        }
        
      case .Float:
        if let data = remoteData[remoteKey].float {
          self.setValue(NSNumber(value: data as Float), forKey: key)
        }
        
      case .Integer:
        if let data = remoteData[remoteKey].int {
          self.setValue(NSNumber(value: data as Int), forKey: key)
        }
        
      case .Boolean:
        if let data = remoteData[remoteKey].bool {
          self.setValue(NSNumber(value: data as Bool), forKey: key)
        }
        
      case .Date:
        if let data = remoteData[remoteKey].double {
          self.setValue(Date(timeIntervalSince1970: data), forKey: key)
        }
        
      case .Value:
        if let string = remoteData[remoteKey].string {
          let data = Data(base64Encoded: string, options: .ignoreUnknownCharacters)
          self.setValue(data, forKey: key)
        }
        
      case .Dictionary:
        if let string = remoteData[remoteKey].string {
          guard let data = Data(base64Encoded: string, options: .ignoreUnknownCharacters) else {
            Config.error("No data, or some other issue?")
            continue
          }
          let v = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSDictionary
          self.setValue(v, forKey: key)
        }
        
      case .User:
        if let username = remoteData[remoteKey].string {
          if let user = User.mr_findFirst(byAttribute: "username", withValue: username, in: context) {
            self.setValue(user, forKey: key)
          } else {
            // create the missing user
            let user = try User.createMissingUserWithUsername(username, inContext: context)
            self.setValue(user, forKey: key)
          }
        }
        
      case .Image, .PDF:
        if let data = remoteData[remoteKey].string {
          
          if let image = files.filter({ $0.name == data }).first {
            
            let file = File.mr_createEntity(in: context)!
            
            if preservingFileKeys {
              file.setPrimitiveValue(data as NSString, forKey: "localUnique")
            }
            file.project = project
            
            // check to see if it's in the data or it needs to be copied?
            if image.path != nil && image.data.count == 0 {
              file.addFileFromPath(image.path!, type: image.type)
              
            } else {
              
              if type == .Image {
                file.imageData = image.data
              } else if type == .PDF {
                file.pdfData = image.data
              }
              
            }
            
            
            self.setValue(file, forKey: key)
            
          } else {
            continue
//            Config.error("Couldn't find the file we where looking for: \(data)")
//            throw Throwable.Import
          }
          
        }
        
      case .Entity:
        
        if remoteData[remoteKey].exists() {
          let entityName = dataType["entity"]!
          if let entity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? SyncableModel {
            try entity.toLocal(remoteData[remoteKey], context: context, files: files, project: project, preservingFileKeys: preservingFileKeys)
            self.setValue(entity, forKey: key)
          } else {
            Config.error("Couldn't coerce core data model for \(entityName)")
            throw Throwable.import
          }
          
        }
        
      case .Entities:
        
        let set = self.mutableSetValue(forKey: key)
        
        for (_, subJson):(String, JSON) in remoteData[remoteKey] {
          let entityName = dataType["entity"]!
          
          if let entity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? SyncableModel {
            try entity.toLocal(subJson, context: context, files: files, project: project, preservingFileKeys: preservingFileKeys)
            set.add(entity)
          } else {
            Config.error("Couldn't coerce core data model for \(entityName)")
            throw Throwable.import
          }
        }
        
      case .Relationship:
        continue
        
      }
    }
  }
  
  func toRelationships(_ remoteData: JSON, context : NSManagedObjectContext) throws {
    
    
    for dataType in type(of: self).getSyncableData() {
      let type: CoreDataTypes = CoreDataTypes(rawValue: dataType["type"]!)!
      let key = dataType["local"]!
      let remoteKey = dataType["remote"]!
      
      switch type {
        
      case .Entity:
        
        if remoteData[remoteKey].exists() {
          let id = remoteData[remoteKey][SyncableModel.idField].stringValue
          
          if let model = self.value(forKey: key) as? SyncableModel {
            
            if model.localId != id {
              Config.error("Something wrong here!")
              throw Throwable.import
              
            }
            
            try model.toRelationships(remoteData[remoteKey], context: context)
          } else {
            Config.error("Model undefined!")
            throw Throwable.import
          }
          
          
        }
        
      case .Entities:
        
        guard let set = self.value(forKey: key) as? NSSet else {
          Config.error("No models defined!")
          throw Throwable.import
        }
        guard let models = set.allObjects as? [SyncableModel] else {
          Config.error("No models defined!")
          throw Throwable.import
        }
        
        for (_, subJson):(String, JSON) in remoteData[remoteKey] {
          let id = subJson[SyncableModel.idField].stringValue
          
          guard let model = models.filter({ $0.localId == id }).first else {
            Config.warn("Couldn't find model; looking to link \(dataType["entity"]!) into \(key) ")
            continue
          }
          try model.toRelationships(subJson, context: context)
          
        }
        
      case .Relationship:
        
        if let id = remoteData[remoteKey].string {
          
          let frq = NSFetchRequest<NSFetchRequestResult>(entityName: dataType["entity"]!)
          frq.predicate = NSPredicate(format: "localUnique = %@", id)
          
          let resp = try context.fetch(frq) as! [SyncableModel]
          if let model = resp.first {
            self.setValue(model, forKey: key)
          } else {
            Config.error("\(dataType)")
            Config.error("\(remoteData[remoteKey])")
            Config.error("No model found!")
            throw Throwable.import
          }
        }
        
      default:
        continue
      }
    }
  }
 
  func translateKeys(_ input: JSON, keys: inout [String:String], context: NSManagedObjectContext) throws  -> JSON {
    var input = input
    
    let modelKey = input[SyncableModel.idField].stringValue
    
    input[SyncableModel.idField].string = self.correspondingKeyForKey(modelKey, keys: &keys)
    
    for dataType in type(of: self).getSyncableData() {
      let type: CoreDataTypes = CoreDataTypes(rawValue: dataType["type"]!)!
      let inputKey = dataType["remote"]!
      
      switch type {
        
      case .Entity:
        
        if input[inputKey].exists() {
          let subJson = input[inputKey]
          let frq = NSFetchRequest<NSFetchRequestResult>(entityName: dataType["entity"]!)
          guard let dynamicModel = NSManagedObject.mr_executeFetchRequestAndReturnFirstObject(frq, in: context) as? SyncableModel else {
            Config.error("Couldn't find at least one model to satisfy clone condition")
            // this can probably be ignored
            continue
          }
          input[inputKey] = try dynamicModel.translateKeys(subJson, keys: &keys, context: context)
          
        }
        
      case .Entities:
        
        if input[inputKey].exists() {
          var assembly: [JSON] = []
          let sJson = input[inputKey]
          let frq = NSFetchRequest<NSFetchRequestResult>(entityName: dataType["entity"]!)
          guard let dynamicModel = NSManagedObject.mr_executeFetchRequestAndReturnFirstObject(frq, in: context) as? SyncableModel else {
            Config.error("Couldn't find at least one model to satisfy clone condition")
            // this can probably be ignored
            continue
          }
          for (_, subJson):(String, JSON) in sJson {
            
            let res = try dynamicModel.translateKeys(subJson, keys: &keys, context: context)
            assembly.append(res)
            
          }
          input[inputKey].arrayObject = assembly.map { $0.object }
        }
        
      case .Relationship:
        
        if let id = input[inputKey].string {
          input[inputKey].string = correspondingKeyForKey(id, keys: &keys)
        }
        
      default:
        continue
      }
    }
    
    return input
  }
  
  
  func correspondingKeyForKey(_ key: String, keys: inout [String: String]) -> String {
    
    var correspondingKey: String!
    
    if let k = keys[key] {
      correspondingKey = k
    } else {
      correspondingKey = ProcessInfo.processInfo.globallyUniqueString as String
      keys[key] = correspondingKey
    }
    
    return correspondingKey
    
  }


}
