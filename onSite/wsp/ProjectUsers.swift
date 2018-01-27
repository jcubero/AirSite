//
//  ProjectUsers.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-11-24.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord
import PromiseKit
import SwiftyJSON

@objc(ProjectUser)

class ProjectUser: SyncableModel {
  
  // properties
  
  @NSManaged var label: String
  @NSManaged var active: NSNumber // bool
 
  // relationships
  @NSManaged var project: Project?
  @NSManaged var user: User?
  
  override class func registerSyncableData(_ converter: RemoteDataConverter) {
  
    converter.registerRemoteData("label", remote: "title", type: .String)
    converter.registerRemoteData("active", remote: "active", type: .Boolean)
    converter.registerRemoteData("user", remote: "user", type: .User)
    
  }


  override class func cleanJSON(_ json: JSON) -> JSON? {

    if !json["user"].exists() || json["user"].stringValue == "" {
      Config.warn("Found project user item with no user defined")
      return nil
    }

    return json

  }

  
  static func getOrCreateUserForProject(_ project: Project, user: User) -> ProjectUser {
    
    let pred = NSPredicate(format: "project = %@ and user = %@", project, user)
    if let projectUser = ProjectUser.mr_findFirst(with: pred) {
      return projectUser
      
    } else {
     
      let projectUser = ProjectUser.mr_createEntity()!
      projectUser.user = user
      projectUser.project = project
      projectUser.active = false
      projectUser.label = ""
      projectUser.setModified()
      project.resetUserLogic()

      return projectUser
    }
  }
}
