//
//  UserManager.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-09-30.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import Foundation
import PromiseKit
import Alamofire
import MagicalRecord
import KeychainAccess
import SwiftyJSON

class UserManager {
  
  var haveUpdatedUsers:Bool = false

  var userIsLoggedIn:Bool = false
  
  var userFieldUsername: String?
  
  var downloadedDomains: [Domain]?
  var haveDomain: Bool { return domain != nil }
  var domain: Domain? {
    get {
      if let id = self.keychain["domain_id"], let name = self.keychain["domain_name"] {
        return Domain(id: id, name: name)
      } else { return nil }
    } set {

      if let d = newValue {
        self.keychain["domain_id"] = d.id
        self.keychain["domain_name"] = d.name

      } else {
        do {
          try self.keychain.remove("domain_id")
          try self.keychain.remove("domain_name")
        } catch  {
          Config.error("error removing password")
        }

      }

      do {
        try self.keychain.remove("username")
        try self.keychain.remove("password")
        
        // on top of eveything, remove all users
        let users = User.mr_findAll() as! [User]
        for user in users {
          user.mr_deleteEntity()
        }
        
        Manager.sharedInstance.saveCurrentState(nil)
        
        
        haveUpdatedUsers = false
        userIsLoggedIn = false
      } catch {
        Config.error()
      }
    }
  }


  
  func getUserInContext(_ context: NSManagedObjectContext) -> User? {
    if let user = self.userFieldUsername {
      return User.mr_findFirst(byAttribute: "username", withValue: user, in: context)
    } else {
      return nil
    }
    
    
  }
  
  var user: User? {
        get {
            if let currentUser = User.mr_findFirst() {
        return currentUser
      } else {
                // return nil // Todo: Temporary until new backend
                let user = User.mr_createEntity()
                user?.username = "jcubero"
                user?.password = ""
                user?.active = true
                return user
      }
     }
  }
  
  fileprivate let keychain = Keychain(service: Config.keychainService)
  
  var someUsersExist: Bool {
    get {
      return User.mr_countOfEntities(with: User.activePredicate) == 0 ? false : true
    }
  }
  
  
  
  func login(_ username: String, password: String) -> (Bool) {
    
    if self.attemptLogin(username, password: password) {
      self.keychain["username"] = username
      self.keychain["password"] = password
      
      return true
    } else {
      return false
      
    }
  }
  
  func loginWithKeychain() -> (Bool) {
 
    if let username = self.keychain["username"], let password = self.keychain["password"] {
      let success = self.login(username, password: password)
      
      if success {
        return true
      } else {
        
        Config.info("Removing invalid login for user: \"\(username)\" from keychain")
        do {
          try self.keychain.remove("username")
          try self.keychain.remove("password")
        } catch {
          Config.error("Error removing invalid login details for user \"\(username)\"")
        }
        return false
      }
      
    } else {
      return false
      
    }
  }
  
  func logout() -> () {
    
    // removes all projects from device
    Manager.sharedInstance.sendActionEvent("Logout", label: "")
    
    Manager.sharedInstance.deleteAllProjects()
    
    do {
      try self.keychain.remove("username")
      try self.keychain.remove("password")
    } catch {
      Config.error("Could not remove username and password from the keychain")
    }
  }
  
  func updateUsers() -> Promise<Void> {
    return Promise<Void> { fulfill, _ in
      let dispatchTime: DispatchTime = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
      DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
        fulfill(())
      }
      }
  }


    func updateDomains() -> Promise<[Domain]> {
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
                    
                }.catch { error in
                    Config.network("A network error occured while getting a list of domains.")
                    reject(error)
            }
        }
        
    }
    
    func getAllDomains() -> Promise<[ServerData]> {
        
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
  
  func attemptLogin(_ username: String, password: String) -> Bool {
   
    // check if user exists
//    if let user = User.mr_findFirst(byAttribute: "username", withValue: username)  {
//      
//      if !user.active { return false }
//      
//      if Config.NetworkConfig.authenticate(password, db: user.password!) {
//        Manager.sharedInstance.sendAnalyticsUID(username)
//        Manager.sharedInstance.sendActionEvent("Login", label: "")
//        
//        self.userFieldUsername = username
//        self.haveUpdatedUsers = true
//        return true
//      }
//    }
//    return false
    
    return true
  }
  
  
  
  
  
  
}
