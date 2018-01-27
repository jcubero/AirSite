//
//  Projects.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-06-08.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord
import PromiseKit
import SwiftyJSON

@objc(Project)

class Project: SyncableModel {
  
  // propterties
  @NSManaged var title: String
  @NSManaged var client: String
  @NSManaged var subtitle: String
  @NSManaged var date: String?
  
  // building
  @NSManaged var buildingName: String
  @NSManaged var buildingAddress: String
  
  @NSManaged var documentType: String
  @NSManaged var projectNumber: String
  
  // pill options
  @NSManaged var openComments: NSNumber // bool
  @NSManaged var openCamera: NSNumber // bool
  @NSManaged var pillSize: NSNumber // float
  
  // photo export options
  @NSManaged var photoQuality: NSNumber // 0, 1, 2
  @NSManaged var photoEmbedPills: NSNumber // bool
  @NSManaged var photoAutoSave: NSNumber // bool
  
  @NSManaged var photosPerPageLandscape: NSNumber // int
  @NSManaged var photosPerPagePortrait: NSNumber // int
  @NSManaged var photosPageOrientation: String
  
  @NSManaged var planPageSize: NSNumber // int
  @NSManaged var planPageOrientation: String
  
  
  
  // user info for reports
  @NSManaged var userNameForReport: String
  @NSManaged var userCompanyForReport: String
  
  @NSManaged var userCompanyAddress1: String
  @NSManaged var userCompanyAddress2: String
  
  @NSManaged var userCompanyPhone: String
  @NSManaged var userCompanyFax: String
  
  @NSManaged var userCompanyEmail: String
  
  
  // relationships
  
  @NSManaged var areas : NSSet?
  @NSManaged var forms : NSSet?
  @NSManaged var projectUsers : NSSet?
  @NSManaged var levels : NSSet?
  @NSManaged var lockedIssues : NSOrderedSet?
  @NSManaged var copiedIssues : NSSet?
  @NSManaged var imageFile: File?
  @NSManaged var buildingImageFile: File?
  @NSManaged var deletedEntities : NSSet?
  
  // images
  var image: UIImage? { get {
    return self.imageFile?.image
    } set {
      let imageFile = self.makeFile("imageFile", project: self)
      imageFile.image = newValue
    }
  }
  
  var imageData: Data? { get {
    return self.imageFile?.imageData
    } set {
      if newValue == nil {
        self.imageFile = nil
        return
      }
      let imageFile = self.makeFile("imageFile", project: self)
      imageFile.imageData = newValue
    }}
  
    var imagePath: URL? { get { return self.imageFile?.path } }
  
  var buildingImage: UIImage? { get {
    return self.buildingImageFile?.image
    } set {
      let imageFile = self.makeFile("buildingImageFile", project: self)
      imageFile.image = newValue
    }}
  
  var buildingImageData: Data? { get {
    return self.buildingImageFile?.imageData
    } set {
      if newValue == nil {
        self.buildingImageFile = nil
        return
      }
      let imageFile = self.makeFile("buildingImageFile", project: self)
      imageFile.imageData = newValue
    }}
  
  
  
  var colorLevel : Level? {
    get {
      let predicate = NSPredicate(format: "project = %@ and isColorLevel = YES", self)
      return Level.mr_findFirst(with: predicate)
    }
  }
  
  var shapeLevel : Level? {
    get {
      let predicate = NSPredicate(format: "project = %@ and isShapeLevel = YES", self)
      return Level.mr_findFirst(with: predicate)
    }
  }
  
  var jpegPhotoQuality: CGFloat {
    get {
      switch self.photoQuality {
      case 0:
        return 0.1
      case 1:
        return 0.3
      default:
        return 0.5
      }
    }
  }

  var nonEmptyProjectTitle: String {
    if self.title == "" {
      let dateFormatter = DateFormatter()
      dateFormatter.dateStyle = .medium
      let untitled = NSLocalizedString("Untited Project", comment: "")
      return "\(untitled) - \(dateFormatter.string(from: self.createdDate! as Date))"
    } else {
      return self.title
    }

  }

  var deletedEntitiesJSON: JSON {
    get {
      
      let deleted = self.deletedEntities!.allObjects as! [Deleted]
      
      var deletedEntities: [[String: AnyObject]] = []
      
      for d in deleted {
        
        deletedEntities.append([
          "id" : d.id as AnyObject,
          "time": d.time.timeIntervalSince1970 as AnyObject
          ])
        
      }
      
      return JSON(deletedEntities)
    }
  }
  
  fileprivate var _hasUserToAppend: Bool?
  var hasUserToAppend: Bool {
    
    if let val = _hasUserToAppend {
      return val
    } else {
      
      var val = true
      let pred = NSPredicate(format: "project = %@ and active = YES", self)
      let users = ProjectUser.mr_findAll(with: pred) as! [ProjectUser]
      if users.count < 2 {
        val = false
      }
      _hasUserToAppend = val
      return val
    }
    
  }

  func resetUserLogic() {
    _hasUserToAppend = nil
  }


  var filter: Filter!

  static var areaPhotoQuality: CGFloat = 0.5
  
  override class func registerSyncableData(_ converter: RemoteDataConverter) {
    
    converter.registerRemoteData("title", remote: "title", type: .String)
    converter.registerRemoteData("client", remote: "client", type: .String)
    converter.registerRemoteData("subtitle", remote: "subtitle", type: .String)
    converter.registerRemoteData("date", remote: "date", type: .String)
    
    converter.registerRemoteData("buildingName", remote: "building_name", type: .String)
    converter.registerRemoteData("buildingAddress", remote: "building_address", type: .String)
    
    converter.registerRemoteData("documentType", remote: "document_type", type: .String)
    converter.registerRemoteData("projectNumber", remote: "project_number", type: .String)
    
    
    converter.registerRemoteData("openComments", remote: "open_comments", type: .Boolean)
    converter.registerRemoteData("openCamera", remote: "open_camera", type: .Boolean)
    converter.registerRemoteData("pillSize", remote: "pill_size", type: .Float)
    
    converter.registerRemoteData("photoQuality", remote: "photo_quality", type: .Integer)
    converter.registerRemoteData("photoEmbedPills", remote: "photo_embed_pills", type: .Boolean)
    converter.registerRemoteData("photoAutoSave", remote: "photo_auto_save", type: .Boolean)
    
    converter.registerRemoteData("photosPageOrientation", remote: "photo_page_orientation", type: .String)
    converter.registerRemoteData("photosPerPageLandscape", remote: "photos_per_page_landscape", type: .Integer)
    converter.registerRemoteData("photosPerPagePortrait", remote: "photos_per_page_portrait", type: .Integer)
    
    converter.registerRemoteData("planPageSize", remote: "plan_page_size", type: .Integer)
    converter.registerRemoteData("planPageOrientation", remote: "plan_page_orientation", type: .String)
    
    converter.registerRemoteData("userNameForReport", remote: "user_name_report", type: .String)
    converter.registerRemoteData("userCompanyForReport", remote: "user_company_report", type: .String)
    
    converter.registerRemoteData("userCompanyAddress1", remote: "user_company_address1", type: .String)
    converter.registerRemoteData("userCompanyAddress2", remote: "user_company_address2", type: .String)
    converter.registerRemoteData("userCompanyPhone", remote: "user_company_phone", type: .String)
    converter.registerRemoteData("userCompanyFax", remote: "user_company_fax", type: .String)
    converter.registerRemoteData("userCompanyEmail", remote: "user_company_email", type: .String)
    
    converter.registerRemoteData("imageFile", remote: "image", type: .Image)
    converter.registerRemoteData("buildingImageFile", remote: "building_image", type: .Image)
    
    converter.registerRemoteData("forms", remote: "forms", type: .Entities, entity: "Form", unit: .Separate)
    converter.registerRemoteData("areas", remote: "areas", type: .Entities, entity: "Area", unit: .Separate)
    converter.registerRemoteData("levels", remote: "levels", type: .Entities, entity: "Level", unit: .Separate)
    converter.registerRemoteData("projectUsers", remote: "project_users", type: .Entities, entity: "ProjectUser", unit: .Separate)
    
    
  }
  
  var createdData: JSON?
  
  static func createFromJSONInContext(_ context: NSManagedObjectContext, json: JSON, files: [FileStruct], preservingFileKeys: Bool ) throws -> Project {
    
    let project = Project.create(context)
    
    try project.toLocal(json, context: context, files: files, project: project, preservingFileKeys: preservingFileKeys)
    try project.toRelationships(json, context: context)
    project.searchThroughIssuesToAddMissingUsers(context)
    project.searchThroughCommentsToAddMissingUsers(context)
    project.addCurrentUserToProjectUsers(context)
    
    for item in json[SyncableModel.deletionKey].arrayValue {
      let id = item["id"].stringValue
      let time = item["time"].doubleValue
      project.deleteProjectEntityId(id, time: Date(timeIntervalSince1970: time), inContext: context)
    }
    
    return project

  }
  
  static func create(_ inContext: NSManagedObjectContext?) -> Project {
    
    let context = inContext == nil ? NSManagedObjectContext.mr_default() : inContext!
    let project = Project.mr_createEntity(in: context)!
    
    project.setModified()
    project.addCurrentUserToProjectUsers(inContext)
    project.createBlankFields()
    
    project.createdData = project.toRemote()
    
    return project
    
  }
  
  func createBlankFields() {
    
    self.title = ""
    self.client = ""
    self.subtitle = ""
    
    self.buildingName = ""
    self.buildingAddress = ""
    
    self.documentType = ""
    self.projectNumber = ""
    
    self.userNameForReport = ""
    self.userCompanyForReport = ""
    
    self.userCompanyAddress1 = ""
    self.userCompanyAddress2 = ""
    self.userCompanyPhone = ""
    self.userCompanyFax = ""
    self.userCompanyEmail = ""
    
  }
  
  var isEmpty: Bool {
    get {
      
      guard let initialData = self.createdData else {
        return false
      }
      
      let data = self.toRemote()
      let dataTypes = Project.getSyncableData()
      let stringKeys: [String] = dataTypes.filter({ $0["type"] == CoreDataTypes.String.rawValue }).map({ $0["remote"]! })
      let compKeys: [String] = dataTypes.filter({ $0["type"] == CoreDataTypes.Integer.rawValue  || $0["type"] == CoreDataTypes.Boolean.rawValue}).map({ $0["remote"]! })
      
      for key in stringKeys {
        if data[key].stringValue == "" {
          continue
        }
        if data[key] != initialData[key] {
          return false
        }
      }
      
      for key in compKeys {
        if data[key] !=  initialData[key] {
          return false
        }
      }
      
      if data["areas"].arrayValue.count > 0 {
        return false
      }
      
      if data["levels"].arrayValue.count > 0 {
        return false
      }
      
      if data["forms"].arrayValue.count > 0 {
        return false
      }

      if self.image != nil || self.buildingImage != nil {
        return false
      }
      
      return true
    }
    
  }
  
  
//  static func parseRemoteProjects(_ data: [ServerData]) -> [[String:AnyObject]] {
//    
//    var ret : [[String:AnyObject]] = []
//    
//    for proj in data {
//      var p: [String:AnyObject] = ["title":"" as AnyObject, "local": false as AnyObject, "id": "" as AnyObject]
//      p["title"] = proj["title"]!
//      p["id"] = proj["nid"]!
//      p["local"] = Project.projectIsLocal(proj["nid"] as? String) as AnyObject
//      ret.append(p)
//    }
//    return ret
//    
//  }
  
  static func projectIsLocal(_ id: String?) -> Bool {
    if let myId = id {
      let projects = Project.mr_find(byAttribute: "id", withValue: myId) as! [Project]
      if projects.count > 0 {
        return true
      }
    }
    return false
  }
  
  func addLockedIssue(_ issue: Issue) {
    
    let modifiable = self.mutableOrderedSetValue(forKey: "lockedIssues")
    
    if modifiable.contains(issue) {
      modifiable.remove(issue)
    }
    
    if modifiable.count > 2 {
      modifiable.removeObject(at: 2)
    }
    modifiable.insert(issue, at: 0)
    
  }
  
  func addCopiedIssue(_ issue: Issue) {
    
    
    let modifiable = self.mutableOrderedSetValue(forKey: "copiedIssues")
    
    if modifiable.contains(issue) {
      return
    }
    
    if modifiable.count > 2 {
      modifiable.removeObject(at: 2)
    }
    modifiable.insert(issue, at: 0)
    
  }
  
  func deleteProjectEntity(_ entity: SyncableModel) {
    
    let id = entity.localId
    entity.removeWithFiles()
    
    self.deleteProjectEntityId(id, time: Date())
    
  }
  
  func deleteProjectEntityId(_ id: String, time: Date, inContext: NSManagedObjectContext? = nil) {
    
    let context = inContext == nil ? NSManagedObjectContext.mr_default() : inContext!
    
    let delete = Deleted.mr_createEntity(in: context)!
    delete.id = id
    delete.time = time
    delete.project = self
    
  }
  
  
  
  func searchThroughIssuesToAddMissingUsers(_ inContext: NSManagedObjectContext?) {
    
    let context = inContext == nil ? NSManagedObjectContext.mr_default() : inContext!
    let project = self.mr_(in: context)!
    
    let issuePred = NSPredicate(format: "area.project = %@", project)
    let issues = Issue.mr_findAll(with: issuePred, in: context) as! [Issue]
    
    var users: [User] = []
    
    for issue in issues {
      
      var user = issue.user
      if user == nil {
        Config.warn("Found comment with no user!")
        user = Manager.sharedInstance.user.getUserInContext(context)!
        issue.user = user
        
      }
      if !users.contains(user!) {
        users.append(user!)
      }
    }
    
    for user in users {
      self.addUserToProjectUsersIfNotExists(user, inContext: context)
    }
    
    removePossibleDuplicateProjectUsers(context)
    
  }
  
  
  func searchThroughCommentsToAddMissingUsers(_ inContext: NSManagedObjectContext?) {
    
    let context = inContext == nil ? NSManagedObjectContext.mr_default() : inContext!
    let project = self.mr_(in: context)!
    
    let issuePred = NSPredicate(format: "issue.area.project = %@", project)
    let comments = Comment.mr_findAll(with: issuePred, in: context) as! [Comment]
    
    var users: [User] = []
    
    for comment in comments {
      var user = comment.user
      if user == nil {
        Config.warn("Found comment with no user!")
        user = Manager.sharedInstance.user.getUserInContext(context)!
        comment.user = user
        
      }
      if !users.contains(user!) {
        users.append(user!)
      }
      
    }
    
    for user in users {
      self.addUserToProjectUsersIfNotExists(user, inContext: context)
    }
    
    removePossibleDuplicateProjectUsers(context)
    
  }
  
  
  fileprivate func removePossibleDuplicateProjectUsers(_ inContext: NSManagedObjectContext?) {
    
    let context = inContext == nil ? NSManagedObjectContext.mr_default() : inContext!
    let project = self.mr_(in: context)!
    let projectUsers = ProjectUser.mr_find(byAttribute: "project", withValue: project, in: context) as! [ProjectUser]
    
    var users: [User] = []
    for pUser in projectUsers {
      
      guard let user = pUser.user else {
        pUser.mr_deleteEntity(in: context)
        continue
      }
      
      if users.contains(user) {
        pUser.mr_deleteEntity(in: context)
        continue
      } else {
        users.append(user)
      }
    }
  }
  
  
  override func removeWithFiles() {
    
    self.imageFile?.deleteFileData()
    self.buildingImageFile?.deleteFileData()
    
    guard let c = self.areas else {
      return
    }
    
    for area in c.allObjects as! [Area] {
      area.removeWithFiles()
    }
    
    
    guard let f = self.forms else {
      return
    }
    
    for form in f.allObjects as! [Form] {
      form.removeWithFiles()
    }
    
    super.removeWithFiles()
    
    
  }
  
  
  func addCurrentUserToProjectUsers(_ inContext: NSManagedObjectContext? = nil) {
    
    let context = inContext == nil ? NSManagedObjectContext.mr_default() : inContext!
    let currentUser = Manager.sharedInstance.getCurrentUser().mr_(in: context)!
    
    self.addUserToProjectUsersIfNotExists(currentUser, inContext: context)
    
  }
  
  
  func addUserToProjectUsersIfNotExists(_ user: User, inContext: NSManagedObjectContext?) {
    
    let context = inContext == nil ? NSManagedObjectContext.mr_default() : inContext!
    let project = self.mr_(in: context)!
    
    let searchPredicate = NSPredicate(format: "user = %@ and project = %@", user, project)
    
    if ProjectUser.mr_countOfEntities(with: searchPredicate, in: context) > 0 {
      return
    }
    
    let projectUsers = ProjectUser.mr_createEntity(in: context)!
    
    projectUsers.setModified()
    projectUsers.project = project
    projectUsers.user = user
    projectUsers.active = true
    
    if let f = user.username?.characters.first {
      projectUsers.label = "\(f)"
    } else {
      projectUsers.label = "a"
    }
    
    
  }
  
  
}
