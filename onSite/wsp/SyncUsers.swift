//
//  SyncUsers.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-06-29.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
import PromiseKit
import Alamofire
import MagicalRecord


class SyncUsers {
  
  
  static func updateUsers() -> Promise<Void> {
    return Promise<Void> { fulfill, reject in
      

      self.getAllUsers()
        .then { serverData -> () in
          
          var allUsers = User.mr_findAll() as! [User]
          var existingUsers: [User] = []
          var created: Int = 0
          
          for userData in serverData {
            if let name = userData[Config.Fields.User.username] as? String {
              guard let password = userData[Config.Fields.User.password] as? String else {
                continue;
              }

              if let user = allUsers.filter({ $0.username == name }).first {
                allUsers.remove(at: allUsers.index(of: user)!)
                
                existingUsers.append(user)
                user.password = password
                user.active = true
                
              } else if let user = existingUsers.filter({ $0.username == name }).first {
                user.password = password
              
              } else {
                let user = User.mr_createEntity()!
                user.username = name
                user.password = password
                user.active = true
                created += 1
              }
            }
          }
          
          // deactivate users no longer used by the system
          for user in allUsers {
            user.active = false
          }
          
          
          Config.info("USER SYNC - Updated: \(existingUsers.count), Added: \(created), Deactivated: \(allUsers.count)")
          
          Manager.sharedInstance.saveCurrentState(nil)
          

          
            fulfill(())
          
        }
        .catch { error in
            Config.network("A network error occured while getting a list of users.")
            reject(error)
      }
    }
  
  }


  static func updateDomains() -> Promise<[Domain]> {
    return Promise<[Domain]> { fulfill, reject in
      

      self.getAllDomains()
        .then { serverData -> () in

          var domains: [Domain] = []

          for value in serverData {
            guard let id = value[Config.Fields.Domain.localId] as? String else {
              Config.error()
              return
            }

            guard let name = value[Config.Fields.Domain.name] as? String else {
              Config.error()
              return
            }

            domains.append(Domain(id: id, name: name))

          }

          fulfill(domains)
          
        }
        .catch { error in
          Config.network("A network error occured while getting a list of domains.")

          reject(error)
      }
    }
  
  }


  
    
    static func getAllUsers() -> Promise<[ServerData]> {
        
        let req = Config.Routes.users()
        let network = Manager.sharedInstance.network
        
        return network.request(request: req)
            .then { json -> Promise<[ServerData]> in
                return Promise<[ServerData]> { fulfill, reject in
                    
                    if let array = json.arrayObject as? [ServerData] {
                        fulfill(array)
                    } else {
                        Config.error("Couldn't decode json object")
                        reject(Throwable.network)
                    }
                }
        }
        
    }

  static func getAllDomains() -> Promise<[ServerData]> {
    
    let req = Config.Routes.domains()
    let network = Manager.sharedInstance.network
    
    return network.request(request: req)
      .then { json -> Promise<[ServerData]> in
        return Promise<[ServerData]> { fulfill, reject in
          
          if let array = json.arrayObject as? [ServerData] {
            fulfill(array)
          } else {
            Config.error("Couldn't decode json object")
            reject(Throwable.network)
          }
        }
    }
      
  }


  
  static func authenticateUser(_ user: User) -> Promise<Void> {
    
    let network = Manager.sharedInstance.network
    guard let req = Config.Routes.usersLogin(user) else {
      return Promise<Void> { f, r in
        f(())
      }
    }
    
    network.resetNetworkHeaders()
    
    return network.request(request: req)
      .then { json throws -> () in
        let token = json[Config.Fields.Session.token].stringValue
        if token == "" {
          throw Throwable.authorization
        }
        network.authorizationToken = token
        
    }

  }
  
}
