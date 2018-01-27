//
//  Syncable.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-08-17.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord
import PromiseKit
import SwiftyJSON

enum CoreDataTypes: String {
  case String = "String"
  case Integer = "Integer"
  case Boolean = "Boolean"
  case Float = "Float"
  case Image = "Image"
  case PDF = "PDF"
  case Value = "Value"
  case Dictionary = "Dictionary"
  case Date = "Date"
  case User = "User"
  case Entity = "Entity"
  case Entities = "Entities"
  case Relationship = "Relationship"
}

enum SyncableUnit: String {
  case Unit = "Unit"
  case Separate = "Separate"
}

class RemoteDataConverter: Sequence {
  
  var remoteDataTypes: [[String:String]] = []
  
  func registerRemoteData(_ local: String, remote: String, type: CoreDataTypes, entity: String = "", unit: SyncableUnit = .Unit) {
    
    if type == .Entity  || type == .Entities || type == .Relationship {
      if entity == "" {
        Config.error("Entity cannot be nil in syncable data!")
        abort()
      }
    }
    
    if unit == .Separate && type != .Entities {
      Config.error("Separated types can only be entities.")
      abort()
    }
   
    self.remoteDataTypes.append(["local":local, "remote":remote, "type" : type.rawValue, "entity": entity, "unit": unit.rawValue])
    
  }
  
  func makeIterator() -> AnyIterator<[String:String]> {
    
    var nextIndex = self.remoteDataTypes.count - 1
    
    return AnyIterator {
      if (nextIndex < 0) {
        return nil
      }
      nextIndex -= 1
      return self.remoteDataTypes[nextIndex + 1]
    }

  }
  
  
}

@objc(SyncableModel)

class SyncableModel: NSManagedObject {
  
  // properties
  @NSManaged var id: String?
  @NSManaged var lastModified: Date?
  @NSManaged var createdDate: Date?
 
  override func awakeFromInsert() {
    super.awakeFromInsert()
    
    if !Manager.sharedInstance.disableLocalUpdateChanges {
      let string = ProcessInfo.processInfo.globallyUniqueString as String
      
      self.setPrimitiveValue(string as NSString, forKey: "localUnique")
    }
    
    self.setPrimitiveValue(Date(), forKey: "createdDate")
  
  }
  
  var localId: String { get { return self.value(forKey: "localUnique") as! String }}
  
  func makeFile(_ key: String, project: Project, inContext: NSManagedObjectContext? = nil) -> File {
    
    let context = inContext == nil ? NSManagedObjectContext.mr_default() : inContext!
    
    var val = self.value(forKey: key) as? File
    if val == nil {
      let file = File.mr_createEntity(in: context)!
      file.project = project
      self.setValue(file, forKey: key)
      val = file
    }
    
    return val!
    
  }
  
  var createdDateFormatted: String {
    get {
      guard let date = self.createdDate else {
        Config.error()
        return ""
      }
      return SyncableModel.formatDate(date)

    }
  }
  
  
  func setModified() {
    
    self.lastModified = Date()
    
  }
  
  func resetLocalId() {
    
    let string = ProcessInfo.processInfo.globallyUniqueString as String
    self.setPrimitiveValue(string as NSString, forKey: "localUnique")
    
  }
  
  
  static var lastModifiedField: String  = "last_modified"
  static var createdDateField: String  = "created_date"
  static var idField: String  = "id"
  static var deletionKey: String = "deletedEntities"

  static func formatDate(_ date: Date) -> String {

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter.string(from: date)

  }

  func removeWithFiles() {

    self.mr_deleteEntity()


  }
  
  
  class func registerSyncableData(_ converter: RemoteDataConverter) {
    
    Config.error("You should really override this method")
    
  }

  class func cleanJSON(_ json: JSON) -> JSON? {

    return json
  }
 
  class func getSyncableData() -> RemoteDataConverter {
    
    let converter = RemoteDataConverter()
    self.registerSyncableData(converter)
   
    return converter
    
  }
  
  
}
