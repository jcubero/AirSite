//
//  JSONImport.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-02-29.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
import SwiftyJSON
import MagicalRecord

class JSONImport {
  
  var files: [FileStruct]
  
  var dataFiles: [FileStruct] {
    get {
      return files.filter { $0.type == .Image || $0.type == .PDF }
    }
  }
  
  
  var projectAlreadyExists: Bool {
    get {
      if let jsonFile = self.files.filter({ $0.type == .JSON }).first {
        do {
            let json = try JSON(data: jsonFile.data)
            let id = json[Project.idField].stringValue
            let count = Project.mr_countOfEntities(with: NSPredicate(format: "localUnique = %@", id))
            if count > 0 {
                return true
            } else {
                return false
            }
        } catch {
            print(error)
        }
        
      } else {
        return false
      }
        return false
    }
  }
  
  init(files: [FileStruct]) {
    
    self.files = files
    
  }


  func beginImport(_ preservingFileKeys: Bool) {
    
    let manager = Manager.sharedInstance
    let err = NSLocalizedString("There was an error loading the selected infield archive", comment: "Error loading archive file.")
      
    manager.startActivity(withMessage: "Importing Project")
    
    if let jsonFile = self.files.filter({ $0.type == .JSON }).first {
      
        do {
            let json = try JSON(data: jsonFile.data)
            MagicalRecord.save({ context -> Void in
                do {
                    _ = try Project.createFromJSONInContext(context, json: json, files: self.dataFiles, preservingFileKeys: preservingFileKeys)
                } catch {
                    context.reset()
                    manager.showError(err)
                    
                }
            }, completion: { _,_ in
                Config.info("Finished Import")
                manager.stopActivity()
            })
        } catch {
            print(error)
        }
    } else {
        Config.error("Invalid infield file loaded")
        manager.showError(err)
      
    }
  }


  
}
