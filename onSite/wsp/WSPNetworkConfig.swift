//
//  WSPNetworkConfig.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-08-29.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import PromiseKit


class WSPNetworkConfig: NetworkConfig {
  
  static var API: String  {
    return WSPAPIRoute
  }
  
  static let APIKEY = "71F92A89-0B46-4005-856A-1365CC1D42F3"
  
  static let saveCookies: ((HTTPURLResponse, Alamofire.SessionManager) -> ())? = nil
  
  static let Routes: NetworkAPIRoutes = WSPAPIRoutes(config: WSPNetworkConfig.self)
  static let Fields: NetworkAPIFields = WSPFields()
  
    static func authenticate(_ input:String, db: String) -> Bool{
        return input == db
    }
    
  
    static func downloadFileToLocation(_ fileData: ServerData, destination: URL, currentProgress: Float, diff: Float) throws -> Promise<URL>{
        guard let localId = fileData[Fields.File.localId] else {
            Config.error()
            throw Throwable.network
        }
        
        let url = "\(self.API)tables/File"
        let params = [
            "K": APIKEY,
            "WhereClause":"\(Fields.File.localId)='\(localId)'",
        ]
        
        
        let request = WSPAPIRequest(method: HTTPMethod.get, url: URL(string:url)!, params: params as [String : AnyObject], resp: WSPAPIResponses.files)
        request.preProgress = currentProgress
        request.postProgress = currentProgress + diff
        
        return Manager.sharedInstance.network.request(request: request).then { (json) -> URL in
            
            // we only take the first file with the id
            guard let fileObj = json[0].dictionaryObject else {
                Config.error()
                throw Throwable.network
            }
            
            guard let encodedData = fileObj[Fields.File.data] as? String else {
                Config.error()
                throw Throwable.network
            }
            
            guard let data = NSData(base64Encoded: encodedData, options:   NSData.Base64DecodingOptions(rawValue: 0)) else {
                Config.error()
                throw Throwable.network
            }
            
            try data.write(to: destination, options: NSData.WritingOptions.atomicWrite)
            
            return destination
            
        }
    }
    
    static func getServerProjectList(_ cb: @escaping ([ProjectListItem]) -> (), currentProjects: [Project], error: @escaping (Error) -> ()) {
        
        let network = Manager.sharedInstance.network
        
        network.request(request: Config.Routes.listProjects())
            .then(on: DispatchQueue.main) { json throws -> () in
                
                var data: [ProjectListItem] = []
                
                for project in json.arrayValue {
                    
                    let localId = project[Config.Fields.Project.localId].stringValue
                    let title = project[Config.Fields.Project.title].stringValue
                    
                    let alreadyExists = currentProjects.filter { $0.localId == localId }.count > 0
                    let currentUsername = Manager.sharedInstance.getCurrentUser().username!
                    
                    if data.filter({ $0.localID == localId }).count == 0 {
                        
                        let encodedData = project[Config.Fields.Project.projectUsers].stringValue
                        guard let projectUsers = Data(base64Encoded: encodedData, options:   Data.Base64DecodingOptions(rawValue: 0)) else {
                            Config.error()
                            continue
                        }
                        
                        guard let validUsers = try JSON(data: projectUsers).arrayObject as? [String] else {
                            Config.error()
                            continue
                        }
                        
                        if validUsers.contains(currentUsername) {
                            data.append(ProjectListItem(title: title, localID: localId, exists: alreadyExists))
                        }
                    }
                }
                
                data.sort(by: { $0.title < $1.title })
                
                cb(data)
                
                
            }.catch { err in
                
                error(err)
                Config.network("Error: \(err)")
                

        }
    }
    
    static var encoding: ParameterEncoding = JSONEncoding() as ParameterEncoding
    
    static func createUserOnWSPServer(_ username: String, password: String) -> Promise<JSON> {
        
//        let request = WSPAPIRequest(method: HTTPMethod.get, url: "", params: nil as [String : AnyObject], resp: WSPAPIResponses.files)
        
        return Promise<APIRequest> { fulfill, reject throws in
            guard let wspRoutes = WSPNetworkConfig.Routes as? WSPAPIRoutes else {
                Config.error()
                throw Throwable.network
            }
            let req = try wspRoutes.createUser(username, password: password)
            fulfill(req)
            
            }.then(execute: Manager.sharedInstance.network.request)
        
        
        //.then(Manager.sharedInstance.network.request)

            // .then(execute: Manager.sharedInstance.network.request(request: ))
    
    }

}

class WSPAPIRequest: APIRequest {
  
    override init(method: HTTPMethod, url: URL, params: [String : AnyObject]?, resp: @escaping (JSON) throws -> JSON) {
        super.init(method: method, url: url, params: params, resp: resp)
        
        if method == HTTPMethod.get{
            encoding = URLEncoding() as ParameterEncoding    } else {
            encoding = JSONEncoding() as ParameterEncoding    }
    }
}

struct WSPAPIRoutes: NetworkAPIRoutes {
  
  
  var config: NetworkConfig.Type
  
  var API: String { return config.API }
  var APIKEY: String { return config.APIKEY }
  var Fields: NetworkAPIFields { return config.Fields }
  
  var username: String { return Manager.sharedInstance.getCurrentUser().username! }
  var password: String { return Manager.sharedInstance.getCurrentUser().password! }
  
  var login: [String: String] {
    return [
      "UserName": username,
      "Password": password,
    ]
  }
  
  
  func users() -> APIRequest {
    var d = ""

    if let domain = Manager.sharedInstance.user.domain {
      d = domain.id
    } else {
      Config.error()
    }

    return WSPAPIRequest(method: .get, url: URL(string: "\(API)tables/User")! , params: [
      "K": APIKEY as AnyObject,
      "WhereClause":"\(Fields.User.groupId)='\(d)'" as AnyObject,
      ], resp: WSPAPIResponses.users)
  }


  func domains() -> APIRequest {
    return WSPAPIRequest(method: .get, url: URL(string:"\(API)tables/Group")!, params: ["K": APIKEY as AnyObject], resp: WSPAPIResponses.domains)
  }

  func usersLogin(_ user: User) -> APIRequest? {
    return nil
  }
  
  func listFiles(_ project: Project) -> APIRequest {
    
    let url = "\(API)tables/File"
    let params = [
      "K": APIKEY,
      "WhereClause":"\(Fields.File.project)='\(project.localId)'",
      "Exclusions":"[\"\(WSPItemsAndType.File.name).[\(Fields.File.data)]\"]",
    ]
    
    return WSPAPIRequest(method: HTTPMethod.get, url: URL(string:url)!, params: params as [String : AnyObject], resp: WSPAPIResponses.files)
    
  }
    func listFiles(project: Project) -> APIRequest {
        
        let url = "\(API)tables/File"
        let params = [
            "K": APIKEY,
            "WhereClause":"\(Fields.File.project)='\(project.localId)'",
            "Exclusions":"[\"\(WSPItemsAndType.File.name).[\(Fields.File.data)]\"]",
        ]
        
        return WSPAPIRequest(method: HTTPMethod.get, url: URL(string: url)!, params: params as [String : AnyObject], resp: WSPAPIResponses.files)
        
    }

  
  
  func  uploadFile(_ project: Project, file: File) throws -> APIRequest {
    
    let data = [
      Fields.File.localId : file.localId,
      Fields.File.project: project.localId,
      Fields.File.fileType: file.fileType,
      Fields.File.data: file.baseEncodedData,
      Fields.File.createdDate: Date()
    ] as [String : Any]
    
    return try self.formatMerge(WSPItemsAndType.File, input: data as ServerData)
    
  }
  
  func getProjects(_ project: Project) -> APIRequest {
    
    let url = "\(API)tables/Project"
    
    let params = [
      "K": APIKEY,
      "WhereClause":"\(Fields.Project.localId)='\(project.localId)'"
    ]
    
    return WSPAPIRequest(method: .get, url: URL(string:url)!, params: params as [String : AnyObject], resp: WSPAPIResponses.projectsWithData)
    
    
  }
  
  func listProjects() -> APIRequest {
    let url = "\(API)tables/Project"
    var d = ""

    if let domain = Manager.sharedInstance.user.domain {
      d = domain.id
    } else {
      Config.error()
    }

    let params = [
      "K": APIKEY,
      "Exclusions":"[\"\(WSPItemsAndType.Project.name).[\(Fields.Project.data)]\"]",
      "WhereClause":"\(Fields.Project.deleted)=0 AND \(Fields.Project.groupId)='\(d)'",
    ]
    
    return WSPAPIRequest(method: .get, url: URL(string:url)!, params: params as [String : AnyObject], resp: WSPAPIResponses.projects)
  }
  
  
  func uploadProject(_ project: Project, json: String, userManifest: String) throws -> APIRequest  {
    
    guard let encodedProjectJSON = json.data(using: String.Encoding.utf8) else {
      Config.error()
      throw Throwable.network
    }
    guard let encodedUserJSON = userManifest.data(using: String.Encoding.utf8) else {
      Config.error()
      throw Throwable.network
    }

    let base64EncodedProject = encodedProjectJSON.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    let base64EncodedUsers = encodedUserJSON.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))


    guard let domain = Manager.sharedInstance.user.domain else {
      Config.error()
      throw Throwable.network
    }

    let groupId = domain.id
    
    let data = [
      Fields.Project.localId: project.localId,
      Fields.Project.data: base64EncodedProject,
      Fields.Project.projectUsers: base64EncodedUsers,
      Fields.Project.title: project.title,
      Fields.Project.createdDate: Date(),
      Fields.Project.groupId: groupId,
      Fields.Project.deleted: false,
    ] as [String : AnyObject]
    
    return try self.formatMerge(WSPItemsAndType.Project, input: data as ServerData)
    
  }
  
  
  func deleteProjects(_ project: Project, ids: [String]) throws -> APIRequest {
    
    var datum: [ServerData] = []
    
    for id in ids {
      guard let idVal = Int64(id) else {
        Config.error()
        throw Throwable.network
      }
      
      datum.append([
        Fields.Project.id: NSNumber(value: idVal as Int64),
        Fields.Project.localId: project.localId as AnyObject,
        Fields.Project.deleted : true as AnyObject,
        ])
    }
    
    return try self.formatMergeMultiple(WSPItemsAndType.Project, input: datum)
    
  }
  
  
  func formatMerge(_ item: DBInfo, input: ServerData) throws -> APIRequest {
    return try self.formatMergeMultiple(item, input: [input])
  }
  
  func createUser(_ username: String, password: String) throws -> APIRequest {
    
    let data: ServerData = [
      Fields.User.localId : username as AnyObject,
      Fields.User.password : password as AnyObject,
      Fields.User.username : username as AnyObject,
      Fields.User.admin : false as AnyObject,
    ]
    
    return try self.formatMerge(WSPItemsAndType.User, input: data)
  }
  
  
  func formatMergeMultiple(_ item: DBInfo, input: [ServerData]) throws -> APIRequest {

    let url = "\(API)merge?K=\(APIKEY)&UserName=\(username)&Password=\(password)"
    
    var info: [String] = []
    
    for i in item.items {
      info.append(contentsOf: [item.name, i.name, i.type])
    }
    
    var datum: [[AnyObject]] = []
    
    for f in input {
      var data: [AnyObject] = []
      
      for i in item.items {
        
        if let v = f[i.name] {
          let value = try self.processItemType(i, v: v)
          data.append(value)
        } else {
          data.append(NSNull())
        }
      }

      datum.append(data)
      
    }
    
    let params: [String: Any] = [
      "$schema":[
        "$types" :[
          "fastJSON.DatasetSchema, fastJSON, Version=1.0.0.0, Culture=neutral, PublicKeyToken=9c3962d2797aceb9" : "1"
        ],
        "Info": info,
        "Name": item.name,
        "$type" : "1",
      ],
      item.name: datum
    ]
    
    return WSPAPIRequest(method: .post, url: URL(string:url)!, params: params as [String : AnyObject], resp: WSPAPIResponses.returnNothing)

  }
  
  func processItemType(_ i: ItemInfo, v: AnyObject) throws -> AnyObject {
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss'Z'"
    formatter.timeZone = TimeZone(abbreviation: "UTC")
    
    switch i.type {
    case "System.DateTime":
      guard let value = v as? Date else {
        Config.error()
        throw Throwable.network
      }
      
      return formatter.string(from: value) as AnyObject
      
    case "System.Int64":
      guard let value = v as? NSNumber else {
        Config.error()
        throw Throwable.network
      }
      
      return value
      
    case "System.Boolean":
      guard let value = v as? Bool else {
        Config.error()
        throw Throwable.network
      }
      
      return value as AnyObject
      
    default:
      guard let value = v as? String else {
        Config.error()
        throw Throwable.network
        
      }
      
      return value as AnyObject
      
    }
    
  }
  
}


struct WSPAPIResponses {
  
  static func users(_ json: JSON) throws -> JSON {
    return try WSPAPIResponses.extractRestQueryJSON(WSPItemsAndType.User, json: json)
  }


  static func domains(_ json: JSON) throws -> JSON {
    return try WSPAPIResponses.extractRestQueryJSON(WSPItemsAndType.Domain, json: json)
  }
  
  static func files(_ json: JSON) throws -> JSON {
    return try WSPAPIResponses.extractRestQueryJSON(WSPItemsAndType.File, json: json)
  }
  
  
  static func projects(_ json: JSON) throws -> JSON {
    return try WSPAPIResponses.extractRestQueryJSON(WSPItemsAndType.Project, json: json)
  }
  
  
  static func projectsWithData(_ json: JSON) throws -> JSON {
    let json = try WSPAPIResponses.extractRestQueryJSON(WSPItemsAndType.Project, json: json)
    
    let fields = WSPFields()
    var ret: [JSON] = []
    
    
    for var j in json.arrayValue {
      
      // remove deleted projects
      if let deleted = j[fields.Project.deleted].bool, deleted {
        continue
      }
      
      // remove empty projects
      guard let encoded = j[fields.Project.data].string else {
        continue
      }
      
      guard let data = NSData(base64Encoded: encoded, options:   NSData.Base64DecodingOptions(rawValue: 0)) else {
        Config.error()
        throw Throwable.network
      }
      
      guard let string = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) else {
        Config.error()
        throw Throwable.network
      }
      
      j[fields.Project.data].string = string as String
      
      ret.append(j)
      
    }
    
    return JSON(ret)
    
    
  }
  
  
  static func returnNothing(_ json: JSON) throws -> JSON {
    return JSON([:])
  }
  
  static func extractRestQueryJSON(_ table: DBInfo, json: JSON) throws -> JSON {
    
    let key = table.name
    
    if json[key].exists() && json["$schema"]["Info"].exists() {
      
      guard let info = json["$schema"]["Info"].arrayObject as? [String] else {
          Config.error()
          throw Throwable.network
      }
      
      guard let data = json[key].array else {
          Config.error()
          throw Throwable.network
      }
      
      var items: [ItemInfo] = []
      
      for i in 0...((info.count/3) - 1) {
        
        let infoNameIndex = (i * 3) + 1
        let infoName = info[infoNameIndex]
        
        let item = try table.getRemoteItem(infoName)
        items.append(item)
        
        }
      
      var r : [JSON] = []
      
      for d in data {
        
        
        guard let entity = d.array else {
          Config.error()
          throw Throwable.network
        }
        
        var entityData: JSON = JSON([:])
        
        for (index, e) in entity.enumerated() {
          let item = items[index]
          entityData[item.name] = e
        }
        r.append(entityData)
        }
      
      
      return JSON(r)
    }
    
    throw Throwable.network
  }
  
}


struct ItemInfo {
  var id: String
  var name: String
  var type: String
}

struct DBInfo {
  var name: String
  var items: [ItemInfo]
  
  func getItemNamed(_ name: String) -> ItemInfo {
   
    for item in items {
      if item.id == name {
        return item
      }
    }
    print("Could not find item \"\(name)\". Critical. Fix your code.")
    abort()
  }
  
  func getRemoteItem(_ name: String) throws -> ItemInfo {
   
    for item in items {
      if item.name == name {
        return item
      }
    }
    throw Throwable.network
  }
  
}

struct WSPItemsAndTypesStruct {
  
  let File = DBInfo(name: "[dbo].[File]", items: [
    ItemInfo(id: "id", name: "id", type: "System.Int64"),
    ItemInfo(id: "localId", name: "u_id", type: "System.String"),
    ItemInfo(id: "fileType", name: "type", type: "System.String"),
    ItemInfo(id: "project", name: "project_u_id", type: "System.String"),
    ItemInfo(id: "data", name: "data", type: "System.Byte[]"),
    ItemInfo(id: "createdDate", name: "created_date", type: "System.DateTime"),
    ])
  
  let Project = DBInfo(name: "[dbo].[Project]", items: [
    ItemInfo(id: "id", name: "id", type: "System.Int64"),
    ItemInfo(id: "localId", name: "u_id", type: "System.String"),
    ItemInfo(id: "title", name: "title", type: "System.String"),
    ItemInfo(id: "data", name: "data", type: "System.Byte[]"),
    ItemInfo(id: "deleted", name: "deleted", type: "System.Boolean"),
    ItemInfo(id: "createdDate", name: "created_date", type: "System.DateTime"),
    ItemInfo(id: "projectUsers", name: "project_users", type: "System.Byte[]"),
    ItemInfo(id: "groupId", name: "group_u_id", type: "System.String"),
    ])
  
  let User = DBInfo(name: "[dbo].[User]", items: [
    ItemInfo(id: "localId", name: "u_id", type: "System.String"),
    ItemInfo(id: "username", name: "username", type: "System.String"),
    ItemInfo(id: "password", name: "password", type: "System.String"),
    ItemInfo(id: "admin", name: "admin", type: "System.Boolean"),
    ItemInfo(id: "groupId", name: "group_u_id", type: "System.String"),
    ])
  
  let ProjectUser = DBInfo(name: "[dbo].[ProjectUser]", items: [
    ItemInfo(id: "project", name: "project_u_id", type: "System.String"),
    ItemInfo(id: "user", name: "user_u_id", type: "System.String"),
    ItemInfo(id: "label", name: "label", type: "System.String"),
    ])


  let Domain = DBInfo(name: "[dbo].[Group]", items: [
    ItemInfo(id: "localId", name: "u_id", type: "System.String"),
    ItemInfo(id: "name", name: "name", type: "System.String"),
    ])
  
}

let WSPItemsAndType = WSPItemsAndTypesStruct()
  

struct WSPFields: NetworkAPIFields {


  internal struct GFields : DomainFields {
    let localId = WSPItemsAndType.Domain.getItemNamed("localId").name
    let name = WSPItemsAndType.Domain.getItemNamed("name").name
  }
  
  let Domain: DomainFields = GFields()
  
  internal struct UFields : UserFields {
    let localId = WSPItemsAndType.User.getItemNamed("localId").name
    let password = WSPItemsAndType.User.getItemNamed("password").name
    let username = WSPItemsAndType.User.getItemNamed("username").name
    let admin = WSPItemsAndType.User.getItemNamed("admin").name
    let groupId = WSPItemsAndType.User.getItemNamed("groupId").name
  }
  
  let User: UserFields = UFields()
  
  internal struct FFields: FileFields {
    let localId = WSPItemsAndType.File.getItemNamed("localId").name
    let fileType = WSPItemsAndType.File.getItemNamed("fileType").name
    let project = WSPItemsAndType.File.getItemNamed("project").name
    let data = WSPItemsAndType.File.getItemNamed("data").name
    let createdDate = WSPItemsAndType.File.getItemNamed("createdDate").name
  }
  
  let File: FileFields = FFields()
  
  internal struct PFields: ProjectFields {
    let localId = WSPItemsAndType.Project.getItemNamed("localId").name
    let data = WSPItemsAndType.Project.getItemNamed("data").name
    let title = WSPItemsAndType.Project.getItemNamed("title").name
    let id = WSPItemsAndType.Project.getItemNamed("id").name
    let createdDate = WSPItemsAndType.Project.getItemNamed("createdDate").name
    let deleted = WSPItemsAndType.Project.getItemNamed("deleted").name
    let projectUsers = WSPItemsAndType.Project.getItemNamed("projectUsers").name
    let groupId = WSPItemsAndType.Project.getItemNamed("groupId").name
  }
  
  let Project: ProjectFields = PFields()
  
  internal struct SFields: SessionFields {
    let token = "token"
  }
  let Session: SessionFields = SFields()
}

