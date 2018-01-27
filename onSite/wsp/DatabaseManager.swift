//
//  DatabaseManager.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-11-09.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import Foundation
import MagicalRecord
import PromiseKit
import KeychainAccess

class DatabaseManager {
  
  fileprivate var currentDatabase:String = "a"
  fileprivate let keychainSQLKey = "sql-store"
  
  fileprivate var currentSQLStore: URL {
    get {
      let paths = Foundation.FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      let documentsURL = paths[0]
      return  documentsURL.appendingPathComponent("wsp-\(self.currentDatabase).sql")
      
    }
  }
  
  fileprivate var backupSQLStore: URL {
    get {
      let paths = Foundation.FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      let documentsURL = paths[0]
      let backupString = self.currentDatabase == "a" ? "b" : "a"
      return  documentsURL.appendingPathComponent("wsp-\(backupString).sql")
    }
  }
  
  fileprivate var backupStoreCoordinator: NSPersistentStoreCoordinator?
  fileprivate var backupManagedObjectContext: NSManagedObjectContext? {
    get {
      if let psc = self.backupStoreCoordinator {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = psc
        return managedObjectContext
      } else {
        return nil
      }
    }
  }
  
  fileprivate let keychain = Keychain(service: Config.keychainService)
  
  var migrator: DatabaseMigrator!
  
  var isMigrationNecessary: Bool {
    get {
      return self.migrator.migrationNeeded
    }
  }
  
  
  init() {
    
    MagicalRecord.setLoggingLevel(.warn)
    
    do {
      let store: String? = try self.keychain.getString(self.keychainSQLKey)
      if store != nil {
        self.currentDatabase = store!
      }
    } catch {
      // do nothing
    }
    
    self.migrator = DatabaseMigrator(database: self.currentDatabase)
  }
  
  
  func migrate(_ fromViewController: UIViewController, cb: @escaping () -> ()) {
    
    if !Config.runMigration {
      
      let alert = UIAlertController(title: "Database will be erased.", message: "", preferredStyle: UIAlertControllerStyle.alert)
      let cancelString = NSLocalizedString("Cancel", comment: "Cancel")
      alert.addAction(UIAlertAction(title: cancelString, style: .default, handler: { action in
        
        abort()
        
      }))
      
      let replaceString = NSLocalizedString("Erase", comment: "Erase")
      alert.addAction(UIAlertAction(title: replaceString, style: .destructive, handler: { action in
        
        alert.dismiss(animated: true, completion: nil)
        
        let fm = Foundation.FileManager()
        if fm.fileExists(atPath: self.currentSQLStore.path) {
          do {
            try fm.removeItem(at: self.currentSQLStore)
          } catch let err {
            Config.error("Couldn't remove previous backup; aborting: \(err)")
          }
        }
        self.initDatabase()
        cb()
        
        
      }))
      
      fromViewController.present(alert, animated: true, completion: nil)
      
      return
    }
    
    
    self.migrator.migrate() { newDB, success in
      if success {
        self.currentDatabase = newDB
        
        if !Config.testMigration {
          do {
            try self.keychain.set(self.currentDatabase, key: self.keychainSQLKey)
          } catch {
            Config.error("Couldn't save current databse preference in local keychain")
          }
        }
        
        self.initDatabase()
        cb()
        
      } else {
        Config.error("Could not successfully migrate database")
      }
    }
  }
  
  func initDatabase() {
    
    Config.startup("Loading database \(self.currentSQLStore.pathComponents.last!)")
    
    MagicalRecord.setupCoreDataStackWithStore(at: self.currentSQLStore)
    NSManagedObjectContext.mr_default().undoManager = nil
    
    self.describeDatabase()
    
  }
  
  
  fileprivate func describeDatabase() {
    
    let allStores = NSPersistentStoreCoordinator.mr_default()!.persistentStores
    let fm = Foundation.FileManager.default
    
    for store in allStores {
      let lastPath = store.url!.lastPathComponent
      do  {
        let attr = try fm.attributesOfItem(atPath: store.url!.path)
        let size: NSNumber = attr[FileAttributeKey.size] as! NSNumber
        let string = ByteCountFormatter.string(fromByteCount: size.int64Value, countStyle: .file)
        Config.startup("Size of \(lastPath) is \(string)")
      } catch {
        // ignore
      }
    }
    
    let projectCount = Project.mr_numberOfEntities().intValue
    let areaCount = Area.mr_numberOfEntities().intValue
    let tagCount = Tag.mr_numberOfEntities().intValue
    let issueCount = Issue.mr_numberOfEntities().intValue
    
    Config.startup("Total projects: \(projectCount)")
    Config.startup("Total areas: \(areaCount)")
    Config.startup("Total tags: \(tagCount)")
    Config.startup("Total issues: \(issueCount)")
    
  }
  
  func backupDatabase() -> Promise<Void> {
    
    return Promise<Void> { fulfill, reject throws in
      Config.database("Backing up local database \(self.currentSQLStore.pathComponents.last!) into \(self.backupSQLStore.pathComponents.last!)")
      
      let fm = Foundation.FileManager()
      
      guard let store = NSPersistentStore.mr_default() else {
        Config.error()
        return
      }
      NSManagedObjectContext.mr_rootSaving().reset()
      
      let migrationStore = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel.mr_default()!)
      do {
        if fm.fileExists(atPath: self.backupSQLStore.path) {
          do {
            try fm.removeItem(at: self.backupSQLStore)
          } catch let err {
            Config.error("Couldn't remove previous backup; aborting: \(err)")
            throw Throwable.db
          }
        }
        let sourceStore = try migrationStore.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.currentSQLStore, options: store.options)
        try migrationStore.migratePersistentStore(sourceStore, to: self.backupSQLStore, options: store.options, withType: NSSQLiteStoreType)
        Config.database("Successfully backup up database to: \(self.backupSQLStore.path)")
        
        // set the backup database as the default in case of crash
        let newDB = self.currentDatabase == "a" ? "b" : "a"
        try self.keychain.set(newDB, key: self.keychainSQLKey)
        
        self.setupBackupDatabase()
        fulfill(())
      } catch let err {
        Config.error("Couldn't backup existing store. Aborting. \(err)")
        throw Throwable.db
      }
    }
  }
  
  func exportDatabase(_ current: Bool) -> Promise<URL> {
    
    let paths = Foundation.FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsURL = paths[0]
    let exportURL = documentsURL.appendingPathComponent("export.sql")
    
    var dbURL = self.currentSQLStore
    if !current {
      dbURL = self.backupSQLStore
    }
    
    return Promise<URL> { fulfill, reject throws in
      Config.database("Exporing local  database \(dbURL.pathComponents.last!) into \(exportURL.pathComponents.last!)")
      
      let fm = Foundation.FileManager()
      
      guard let store = NSPersistentStore.mr_default() else {
        Config.error()
        return
      }
      
      NSManagedObjectContext.mr_rootSaving().reset()
      
      let migrationStore = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel.mr_default()!)
      do {
        if fm.fileExists(atPath: exportURL.path) {
          do {
            try fm.removeItem(at: exportURL)
          } catch let err {
            Config.error("Couldn't remove previous backup; aborting: \(err)")
            throw Throwable.db
          }
        }
        let sourceStore = try migrationStore.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: store.options)
        try migrationStore.migratePersistentStore(sourceStore, to: exportURL, options: store.options, withType: NSSQLiteStoreType)
        Config.database("Successfully backup up database to: \(exportURL.path)")
        
        // set the backup database as the default in case of crash
        
        fulfill(exportURL)
      } catch let err {
        Config.error("Couldn't backup existing store. Aborting. \(err)")
        throw Throwable.db
      }
    }
  }
  
  func restoreDatabase() -> Promise<Void> {
    
    return Promise<Void> { fulfill, reject throws in
      
      self.teardownBackupDatabase()
      
      let newDB = self.currentDatabase == "a" ? "b" : "a"
      Config.database("Restoring local database from \(self.currentSQLStore.pathComponents.last!) to \(self.backupSQLStore.pathComponents.last!)")
      
      let reportError = { (err: String) throws -> () in
        Config.error(err)
        throw Throwable.db
      }
      
//      NSManagedObjectContext.MR_rootSavingContext().reset()
      MagicalRecord.cleanUp()
      
      self.currentDatabase = newDB
      do {
        try self.keychain.set(self.currentDatabase, key: self.keychainSQLKey)
      } catch {
        try reportError("Couldn't save current databse preference in local keychain")
      }
      
      MagicalRecord.setupCoreDataStackWithAutoMigratingSqliteStore(at: self.currentSQLStore)
      NSManagedObjectContext.mr_default().undoManager = nil
      NotificationCenter.default.post(name: Notification.Name(rawValue: Config.databaseReloadNotification), object: nil)
      
      fulfill(())
      
    }
  }
  
  func commitDatabase<T>(_ t:T) -> Promise<T> {
   
    return Promise<T> { fulfill, reject throws in
      
      self.teardownBackupDatabase()
      
      Config.database("Commiting database \(self.currentDatabase) as default on app load.")
      
      do {
        try self.keychain.set(self.currentDatabase, key: self.keychainSQLKey)
      } catch {
        Config.error("Couldn't save current databse preference in local keychain")
        throw Throwable.db
      }
      
      fulfill(t)
      
    }
  }
  
  
  fileprivate func setupBackupDatabase() {
    let modelURL = Bundle.main.url(forResource: "wsp", withExtension: "momd")!
    let managedObjectModel =  NSManagedObjectModel(contentsOf: modelURL)!
 
    self.backupStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
    do {
      try self.backupStoreCoordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.backupSQLStore, options: nil)
    } catch let err {
      Config.error("Couldn't set up backup persistent store: \(err)")
    }
  }
  
  fileprivate func teardownBackupDatabase() {
    
    self.backupStoreCoordinator = nil
    
  }
  
 
  func saveBlockToBackupDatabase(_ block: @escaping (NSManagedObjectContext) -> ()) {
    
    if let backupContext = self.backupManagedObjectContext {
      backupContext.perform() {
        block(backupContext)
        backupContext.mr_saveOnlySelfAndWait()
      }
    }
    
    
  }
  
  
}
