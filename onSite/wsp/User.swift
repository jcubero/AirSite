//
//  User.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-05-29.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON
import MagicalRecord
import PromiseKit
import CryptoSwift

@objc(User)

class User: SyncableModel {

  @NSManaged var password: String?
  @NSManaged var username: String?
  
  // used to mean active, no access from outside
  @NSManaged fileprivate var administrator: NSNumber?
  
  // relationships
  @NSManaged var projects: NSSet?
  @NSManaged var issues: NSSet?
  @NSManaged var comments: NSSet?
  
  
  // INFO: using administrator to mean active so I don't need to update the database;
  // this will probably remain like this. Never user the administrator field, only the
  // fields below, as this probably will change.
  var active: Bool {
    get {
      if let admin = administrator {
        return admin.boolValue
      } else {
        return false
      }
    } set {
      administrator = NSNumber(value: newValue as Bool)
    }
  }
  
  
  static var activePredicate: NSPredicate = NSPredicate(format: "administrator = YES")
  
  static func createMissingUserWithUsername(_ username: String, inContext context: NSManagedObjectContext) throws -> User {
    
    guard let user = User.mr_createEntity(in: context) else {
      throw Throwable.db
    }
    
    user.username = username
    user.password = ""
    user.id = "1"
    user.active = true
    return user
  }
  
    

  override class func registerSyncableData(_ converter: RemoteDataConverter) {
  
    converter.registerRemoteData("username", remote: "name", type: .String)
    converter.registerRemoteData("password", remote: "password", type: .String)

  }
  
  
}
