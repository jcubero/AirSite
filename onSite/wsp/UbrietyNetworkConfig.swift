//
//  NetworkConfig.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-08-29.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import PromiseKit

/*
class UbrietyNetworkConfig: NetworkConfig {
  
//  private static let API = "https://beta.ubriety.com/wsp-2016/a/"
  static let API = "https://killingcode.com/stage/wsp/a/"
  
//  static let API = "http://wsp.docker/a/"
  static let APIKEY = "buriMVqLh3UaL34t1JZE"
  
  static let saveCookies: ((NSHTTPURLResponse, Alamofire.Manager) -> ())? = { res, manager in
    let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(res.allHeaderFields as! [String: String], forURL: (res.URL!))
    manager.session.configuration.HTTPCookieStorage?.setCookies(cookies, forURL: res.URL!, mainDocumentURL: nil)
    
  }
  
  static let Routes: NetworkAPIRoutes = UbrietyAPIRoutes(config: UbrietyNetworkConfig.self)
  static let Fields: NetworkAPIFields = UbrietyFields()
  
  
  static func authenticate(input:String, db: String) -> Bool {
    return input.sha256() == db
  }
  
  static var encoding: ParameterEncoding = .URL
  
  static func downloadFileToLocation(fileData: ServerData, destination: NSURL, currentProgress: Float, diff: Float) throws -> Promise<NSURL> {
    
    guard let url = fileData["url"] as? String else {
      Config.error()
      throw Throwable.Network
    }
    
    return Manager.sharedInstance.network.downloadFileToDestination(url, destination: destination)
    
  }
  
  
  static func getServerProjectList(cb: ([ProjectListItem]) -> (), currentProjects: [Project], error: (ErrorType) -> ()) {
    
    let network = Manager.sharedInstance.network
    
    SyncUsers.authenticateUser(Manager.sharedInstance.getCurrentUser()).then { () -> Promise<JSON> in
      return network.request(Config.Routes.listProjects())
    
      }.then { json -> () in
        
        dispatch_async(dispatch_get_main_queue()) {
          
          var data: [ProjectListItem] = []
          let projectList = currentProjects
          for (localId,subJson):(String, JSON) in json {
            let alreadyExists = projectList.filter { $0.localId == localId }.count > 0
            data.append(ProjectListItem(title: subJson.stringValue, localID: localId, exists: alreadyExists))
            
          }
          
          data.sortInPlace({ $0.title < $1.title })
          
          cb(data)
          
        }
      }.error { err in
        Config.error("Error: \(err)")
        error(err)
    }
  }
  
  static func createDefaultUsers() {
    Config.error()
    
  }
  
}


struct UbrietyAPIRoutes: NetworkAPIRoutes {
  
  var config: NetworkConfig.Type
  
  var API: String { return config.API }
  var APIKEY: String { return config.APIKEY }
  var Fields: NetworkAPIFields { return config.Fields }
  
  
  func users() -> APIRequest {
    return APIRequest(method: .POST, url: "\(API)users-Zw1tW6f0Ua",  params: ["key": APIKEY], resp: UbrietyAPIResponses.drupal)
  }
  
  
  func usersLogin(user: User) -> APIRequest? {
    let params = [
      Fields.User.username: user.username!,
      Fields.User.password: user.password!,
      ]
    
    return APIRequest(method: .POST, url: "\(API)users-Zw1tW6f0Ua/login", params: params, resp: UbrietyAPIResponses.drupal)
  }
  
  func listProjects() -> APIRequest {
    let url = "\(API)projectx"
    return APIRequest(method: .get, url: url, params: nil, resp: UbrietyAPIResponses.drupal)
  }
  
  
  func listFiles(project: Project) -> APIRequest {
    
    let projectId = project.localId
    let url = "\(API)filesx/\(projectId)/list"
    
    return APIRequest(method: .POST, url: url, params: nil, resp: UbrietyAPIResponses.drupal)
  }
  
  
  func  uploadFile(project: Project, file: File) throws -> APIRequest {
    let url = "\(API)filesx"
    
    let params = [
      Fields.File.localId : file.localId,
      Fields.File.fileType : file.fileType,
      Fields.File.project : project.localId,
      Fields.File.data : file.baseEncodedData,
      ]
    
    return APIRequest(method: .POST, url: url, params: params, resp: UbrietyAPIResponses.drupal)
  }
  
  func getProjects(project: Project) -> APIRequest {
    
    let url = "\(API)projectx/\(project.localId)/list"
    
    return APIRequest(method: .POST, url: url, params: nil, resp: UbrietyAPIResponses.drupal)
    
    
  }
  
  func updateProjectUers(project: Project, names: [String]) -> APIRequest? {
    
    let url =  "\(API)projectx/\(project.localId)/users"
    let params = [
      "users" : names
    ]
    return APIRequest(method: .POST, url: url, params: params, resp: UbrietyAPIResponses.drupal)
    
    
  }
  
  func uploadProject(project: Project, json: String) throws -> APIRequest  {
    
    let params = [
      Fields.Project.localId: project.localId,
      Fields.Project.data: json,
      Fields.Project.title: project.title
    ]
    let url =  "\(API)projectx"
    
    return APIRequest(method: .POST, url: url, params: params, resp: UbrietyAPIResponses.drupal)
    
  }
  
  func deleteProjects(project: Project, ids: [String]) throws -> APIRequest {
    
    let url = "\(API)projectx/delete"
    let params = [Fields.Project.id : ids]
    
    return APIRequest(method: .POST, url: url, params: params, resp: UbrietyAPIResponses.drupal)
    
    
  }
}

struct UbrietyAPIResponses {
  
  static func drupal(json: JSON) throws -> JSON {
    
    if json["status"].stringValue == "success" {
      return json["data"]
    }
    throw Throwable.Network
  }
  
}

struct UbrietyFields: NetworkAPIFields {
  
  internal struct UFields : UserFields {
    let localId = "localId"
    let password = "field_password"
    let username = "name"
    let admin = "field_admin"
  }
  
  let User: UserFields = UFields()
  
  internal struct FFields: FileFields {
    let localId = "field_id"
    let fileType = "field_type"
    let project = "field_project"
    let data = "field_data"
    let createdDate = "created_date"
  }
  
  let File: FileFields = FFields()
  
  internal struct PFields: ProjectFields {
    let localId = "field_project"
    let data = "field_project_data"
    let title = "field_project_title"
    let id = "id"
    let createdDate = "created_date"
    let deleted = "field_deleted"
  }
  
  let Project: ProjectFields = PFields()
  
  internal struct SFields: SessionFields {
    let token = "token"
  }
  let Session: SessionFields = SFields()
  
}


*/
