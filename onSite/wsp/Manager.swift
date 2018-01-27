//
//  DataStore.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-05-29.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import Foundation
import SwiftyJSON
import MagicalRecord
import PromiseKit
//import Firebase

class Manager : NSObject, ActivityDelegate {
  
  static let sharedInstance = Manager()
 
  var exportSettings = ExportSettings()
  var disableLocalUpdateChanges = false
  
  var database: DatabaseManager!
  var user : UserManager!
  
  var activityView: ActivityView?
  var networkActivityView: NetworkActivityView?
  
  let network = Network()
  var sync: SyncProject?
  var preventFileDetetion: Bool = false
  
  let features = Features()

  var caches: Caches!
  
  func initAfterLaunch() {
    
    self.database = DatabaseManager()
    
    // sometimes the network headers are not refreshed between sessions
    self.user = UserManager()
    
    self.initAnalytics()
    
    let release = DEV ? "DEBUG" : "RELEASE"
    Config.startup("APP LAUNCH -- \(release) - Build \(Config.buildNumner)")

    // self.network.resetNetworkHeaders()
    // self.network.startReachabilityNofications()

    (UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self])).tintColor = UIColor.white

  }
  
  // MARK: Analytics
  func initAnalytics() {
    
    if !Config.enableAnalytics { return }
    

//    FIRApp.configure()

  }
  
  func sendAnalyticsUID(_ id: String) {
    if !Config.enableAnalytics { return }

//    FIRAnalytics.setUserPropertyString(id, forName: "logged_user")

  }
  
  func sendAnalyticsError(_ desc: String, err: NSError) {
    
    if !Config.enableAnalytics { return }

//    FIRAnalytics.logEventWithName("Error", parameters: [
//      "desc": desc
//      ])

  }


  func sendAnalyticsWarning(_ err: String) {
    if !Config.enableAnalytics { return }
  }

  
  func sendScreenView(_ screen: String) {
    
    if !Config.enableAnalytics { return }
//    FIRAnalytics.logEventWithName(screen, parameters: nil)

  }
  
  func sendActionEvent(_ action: String, label: String) {
    if !Config.enableAnalytics { return }

    self.sendAnalyticsEvent("Actions", action: action, label: label, value: nil)
  }
  
  func sendAnalyticsEvent(_ category: String, action: String, label: String, value: NSNumber?) {
    
    if !Config.enableAnalytics { return }
//    FIRAnalytics.logEventWithName("Action", parameters: [
//      "action" : action as NSObject,
//      "label" : label as NSObject,
//      ])

  }

  func setCustomCrashData(_ resident: Int64, mem_used: Int64, mem_free: Int64, total: Int64) {

    if !Config.enableAnalytics { return }


  }
  
  
  // MARK: database
  
  func migrateDatabase(_ fromViewController: UIViewController, cb: @escaping () -> ()) {
    self.database.migrate(fromViewController) {
      cb()
    }
  }
  
  func initDatabse() {
    
    self.database.initDatabase()

  }
  
  // MARK: users
  
  func getCurrentUser() -> User {
    if let u = self.user.user {
      return u
    } else {
      Config.error("No user logged in, this shouldn't happen!!")
      // crash
      abort()
    }
  }
  
  
  // MARK: core data

  
  func saveCurrentState(_ callback: (() -> ())?) {
    
    NSManagedObjectContext
      .mr_default()
      .mr_saveToPersistentStore(completion: { (success, error) -> Void in
        if let err = error {
          Config.error("Couldn't save the current context: \(err)")
          return
        }
        if let c = callback {
          c()
        }
      })
  }

  func initCachesForProject(_ project: Project) {

    caches = Caches()

  }
  
  
  // MARK: activity
  
  func startActivity(withMessage userMessage: String?) {
    
    var message = NSLocalizedString("Please wait.", comment: "")
    if let uM = userMessage {
      message = uM
    }
    
    ActivityView.loadActivity(message) { view in
      self.activityView = view
    }
    
  }
  
  func updateStatus(_ string: String) {
    DispatchQueue.main.async {
      self.activityView?.status = string
    }
    
  }
  
  func showError(_ string: String) {
    
    DispatchQueue.main.async {
      if let a = self.activityView {
        a.error = string
      } else {
        ActivityView.loadActivity(string) { view in
          self.activityView = view
          self.activityView?.error = string
        }
      }
    }
  }
  
  func stopActivity(_ cb: (() -> ())? = nil) {
    
    DispatchQueue.main.async {
      
      guard let aView = self.activityView else {
        cb?()
        return
      }
      if !aView.inErrorMode {
        self.dismissActivity(cb)
      } else {
        cb?()
      }
    }
  }
  
  func dismissActivity(_ cb: (() -> ())? = nil) {
    
    if let aView = self.activityView {
      self.activityView = nil
      aView.dismiss({
        cb?()
      })
    } else if let aView = self.networkActivityView {
      self.networkActivityView = nil
      aView.dismiss({
        cb?()
      })
    }
  }
  
  
  // MARK: network activity
  
  func startNetworkActivity(withMessage userMessage: String?, cb: @escaping () -> ()) {
    
    var message = NSLocalizedString("Please wait", comment: "Please wait.")
    if let uM = userMessage {
      message = uM
    }
    
    NetworkActivityView.loadActivity(message) { view in
      self.networkActivityView = view
      cb()
    }
  }

  func updateNetworkProgress(_ progress: Float) {
    DispatchQueue.main.async {
      self.networkActivityView?.progress = progress
    }
  }


  func updateNetworkStatus(_ string: String, progress: Float) {
    DispatchQueue.main.async {
      self.networkActivityView?.status = string
      self.networkActivityView?.progress = progress
    }
  }
  
  func showNetworkError(_ string: String) {
    
    DispatchQueue.main.async {
      if let a = self.networkActivityView {
        a.error = string
      } else {
        NetworkActivityView.loadActivity(string) { view in
          self.networkActivityView = view
          self.networkActivityView?.error = string
        }
      }
    }
  }
  
  func showNetworkInfo(_ title: String, message: String) {
    
    DispatchQueue.main.async {
      if let a = self.networkActivityView {
        a.showInfo(title, message: message)
      } else {
        NetworkActivityView.loadActivity(message) { view in
          view.showInfo(title, message: message)
        }
      }
    }
  }
  
  
  func stopNetworkActivity() {
    
    DispatchQueue.main.async {
      
      guard let aView = self.networkActivityView else {
        return
      }
      if !aView.inErrorMode {
        self.dismissActivity()
      }
    }
  }
  
  // MARK: network
  
  
  func syncProject(_ project: Project, cb: @escaping () -> ()) {
  
//    self.sync = SyncProject(project: project, localId: project.localId)
//    
//    self.startNetworkActivity(withMessage: NSLocalizedString("Sync", comment: "Sync")) { [unowned self] in
//      self.networkActivityView?.abortCallback = {
//        self.sync?.aborted = true
//        self.network.cancelCurrentRequest()
//        self.sync = nil
//      }
//      
//      self.networkActivityView?.retryCallback = {
//        
//        self.sync?.start {
//          self.sync = nil
//          cb()
//        }
//      }
//      
//      self.networkActivityView?.cancelCallback = {
//        self.sync = nil
//        cb()
//      }
//      
//      self.sync?.start {
//        self.sync = nil
//        cb()
//      }
//    }
  }
  
  func listRemoteProjects(_ cb: @escaping ([ProjectListItem]) -> (), error: @escaping (Error) -> ()) {
    
    let currentProjects = Project.mr_findAll() as! [Project]
    
    Config.networkConfig.getServerProjectList(cb, currentProjects: currentProjects, error: error)
    
  }
  
  func getProject(_ localId: String) {
    self.sync = SyncProject(project: nil, localId: localId)
    // self.sync = syncProject(nil, cb: localId)
    
    self.startNetworkActivity(withMessage: NSLocalizedString("Sync", comment: "Sync")) { [unowned self] in
      self.networkActivityView?.abortCallback = {
        self.sync?.aborted = true
        self.network.cancelCurrentRequest()
        self.sync = nil
      }
      
      self.networkActivityView?.retryCallback = {
        
        self.sync?.start {
          self.sync = nil
        }
      }
      
      self.networkActivityView?.cancelCallback = {
        self.sync = nil
      }
      
      self.sync?.start {
        self.sync = nil
      }
    }
    
  }
  
  func permanantlyDeleteProject(_ project: Project, vc: UIViewController, completion: () -> ()) {
    project.removeWithFiles()
  }
  
  
  func deleteAllProjects() {
    
    let projects = Project.mr_findAll() as! [Project]
    for project in projects {
      project.removeWithFiles()
    }
    
    Manager.sharedInstance.saveCurrentState(nil)
    
    
  }
  
}
