//
//  SyncableModel+Integrity.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-10-07.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
import SwiftyJSON

extension SyncableModel {

  class func verifyIntegrity(_ json: JSON) throws -> JSON? {

    guard var cleanJSON = self.cleanJSON(json) else {
      return nil
    }

    for dataType in self.getSyncableData() {
      let type: CoreDataTypes = CoreDataTypes(rawValue: dataType["type"]!)!
      let key = dataType["remote"]!
      
      switch type {
        
      case .Entity:
        
        if cleanJSON[key].exists() {
          let entityName = dataType["entity"]!
          
          guard let entity = NSClassFromString(entityName) as? SyncableModel.Type else {
            Config.error()
            throw Throwable.import
          }

          if let cleaned = try entity.verifyIntegrity(cleanJSON) {
            cleanJSON[key] = cleaned
          } else {
            cleanJSON.dictionaryObject?.removeValue(forKey: key)
            
          }
        }
        
      case .Entities:
        
        let entityName = dataType["entity"]!
        guard let entity = NSClassFromString(entityName) as? SyncableModel.Type else {
          Config.error("Could not create entity \(entityName)")
          throw Throwable.import
        }
      
        var ret: [JSON] = []
        for c in cleanJSON[key].arrayValue {
          if let sub = try entity.verifyIntegrity(c) {
            ret.append(sub)
          }
        }
        
        cleanJSON[key] = JSON(ret)

      default:
        continue
      }
    }
    
    return cleanJSON

  }




}
