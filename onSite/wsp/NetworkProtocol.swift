//
//  NetworkProtocol.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-08-29.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import PromiseKit


protocol NetworkConfig {
  static var API: String { get }
  static var APIKEY: String { get }
  static var saveCookies: ((HTTPURLResponse, Alamofire.SessionManager) -> ())? { get }
  static var Routes: NetworkAPIRoutes { get }
  static var Fields: NetworkAPIFields { get }
  
  static func authenticate(_ input:String, db: String) -> Bool
  
  static var encoding: ParameterEncoding { get }
  
  static func downloadFileToLocation(_ fileData: ServerData, destination: URL, currentProgress: Float, diff: Float) throws -> Promise<URL>
  static func getServerProjectList(_ cb: @escaping ([ProjectListItem]) -> (), currentProjects: [Project], error: @escaping (Error) -> ())
}

protocol NetworkAPIRoutes {
  
  func users() -> APIRequest
  func domains() -> APIRequest

  func usersLogin(_ user: User) -> APIRequest?
  
  func listProjects() -> APIRequest
  
  func listFiles(_ project: Project) -> APIRequest
  
  func uploadFile(_ project: Project, file: File) throws -> APIRequest
  
  func getProjects(_ project: Project) -> APIRequest

  func uploadProject(_ project: Project, json: String, userManifest: String) throws -> APIRequest
  func deleteProjects(_ project: Project, ids: [String]) throws -> APIRequest

}

protocol NetworkAPIFields {
  var User: UserFields { get }
  var File: FileFields { get }
  var Project: ProjectFields { get }
  var Session: SessionFields { get }
  var Domain: DomainFields { get }
}

protocol UserFields {
  var localId: String { get }
  var password: String { get }
  var username: String { get }
  var admin: String { get }
  var groupId: String { get }
}


protocol DomainFields {
  var localId: String { get }
  var name: String { get }
}


protocol FileFields {
  var localId: String { get }
  var fileType: String { get }
  var project: String { get }
  var data: String { get }
  var createdDate: String { get }
}

protocol ProjectFields {
  var localId: String { get }
  var data: String { get }
  var title: String { get }
  var id: String { get }
  var createdDate: String { get }
  var deleted: String { get }
  var projectUsers: String { get }
  var groupId: String { get }
}

protocol SessionFields {
  var token: String { get }
}


struct ProjectListItem {
 
  let title: String
  let localID: String
  let exists: Bool
  
}
