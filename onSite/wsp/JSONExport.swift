//
//  JSONExport.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-02-25.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreData

class JSONExport {
  
  var project: Project!
  
  init(project: Project) {
    
    self.project = project
    
    
  }
  
  func exportProject() throws -> Data {
    
    return try self.exportJSON().rawData()
    
  }
  
  func exportJSON() -> JSON {
    
    var returnToServer =  self.project.toRemote()
    
    returnToServer["version"].int = Config.buildNumner
    returnToServer[SyncableModel.deletionKey] = self.project.deletedEntitiesJSON
    
    return returnToServer
    
  }
  
  func exportForCloning(withTitle title: String) throws -> JSON {
  
    var projectJson = self.project.toRemote()
    projectJson.dictionaryObject?.removeValue(forKey: "areas")
    projectJson.dictionaryObject?.removeValue(forKey: "forms")
    var keys: [String:String] = [:]
    projectJson = try self.project.translateKeys(projectJson, keys: &keys, context: NSManagedObjectContext.mr_default())
    projectJson["title"].string = title
    projectJson[SyncableModel.createdDateField].double = Date().timeIntervalSince1970

    return projectJson
      
  }
  
  
}
