//
//  DatabaseMigrator.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-12-21.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import Foundation
import PromiseKit
import CoreData

protocol DatabaseMigratorDelegate: class {
  func progress(_ progress: Float, info: String)
}

class DatabaseMigrator: NSObject {
  
  weak var delegate: DatabaseMigratorDelegate?
  
  fileprivate var currentDatabase: String!
  fileprivate let keychainSQLKey = "sql-store"
  
  fileprivate var currentSQLStore: URL {
    get {
      let paths = Foundation.FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      let documentsURL = paths[0]
      return  documentsURL.appendingPathComponent("wsp-\(self.currentDatabase).sql")
      
    }
  }
  
  fileprivate var newSQLStore: URL {
    get {
      let paths = Foundation.FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      let documentsURL = paths[0]
      let backupString = self.currentDatabase == "a" ? "b" : "a"
      return  documentsURL.appendingPathComponent("wsp-\(backupString).sql")
    }
  }
  
  var migrationNeeded: Bool {
    get {
      do {
        let sourceMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: self.currentSQLStore)
        guard let managedObjectModel = NSManagedObjectModel.mr_newManagedObjectModelNamed("wsp.momd") else {
          Config.error()
          return true
        }
        return !managedObjectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetadata)
      } catch {
        Config.info("Couldn't read store metadata, initial run?")
        return false
      }
    }
  }
  
  
  init(database: String) {
    self.currentDatabase = database
    
  }
  
  
  func migrate(_ cb: @escaping (_ newDB: String, _ success: Bool) -> ()) {
    
    var success = true
    if(self.migrationNeeded) {
      Config.database("Performing migration")
      
      Config.privateQueue.async {
        success = self.performMigrations()
       
        DispatchQueue.main.async {
          cb(self.currentDatabase, success)
        }
      }
      
    } else {
      Config.database("Database seems to match the current version")
      cb(self.currentDatabase, success)
    }
    
    
  }
  
  
  func performMigrations() -> Bool {
    
    while self.migrationNeeded {
      do {
        let sourceMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: self.currentSQLStore)
        let sourceModel = NSManagedObjectModel.mergedModel(from: [Bundle.main], forStoreMetadata: sourceMetadata)!
        let modelPaths: [String] = self.modelPaths()
        
        var mapping: NSMappingModel!
        var destinationModel: NSManagedObjectModel!
        for modelPath in modelPaths {
          destinationModel = NSManagedObjectModel(contentsOf: URL(fileURLWithPath: modelPath))
          mapping = NSMappingModel(from: [Bundle.main], forSourceModel: sourceModel, destinationModel: destinationModel)
          
          if mapping != nil {
            break
          }
        }
        
        if mapping == nil {
          Config.error("Could not find appropriate mapping model, aborting")
          return false
        }
        
        
        let manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
       
        manager.addObserver(self, forKeyPath: "migrationProgress", options: .new, context: nil)
        self.clearNewSQLStore()
        
        do {
          try manager.migrateStore(from: self.currentSQLStore, sourceType: NSSQLiteStoreType, options: nil, with: mapping, toDestinationURL: self.newSQLStore, destinationType: NSSQLiteStoreType, destinationOptions: nil)
          manager.removeObserver(self, forKeyPath: "migrationProgress")
        } catch let err {
          manager.removeObserver(self, forKeyPath: "migrationProgress")
          Config.error("Could not migrate database correctly: \(err)")
          return false
        }
        
        self.toggleDBs()
        
      } catch {
        Config.error("Couldn't read store metadata, aborting")
        return false
        
      }
    }
    
    return true
    
  }
  
  func clearNewSQLStore() {
    let fm = Foundation.FileManager()
    
    if fm.fileExists(atPath: self.newSQLStore.path) {
      do {
        try fm.removeItem(at: self.newSQLStore)
      } catch let err {
        Config.error("Couldn't remove previous backup; aborting: \(err)")
      }
    }
    
  }
  
  func toggleDBs() {
    self.currentDatabase = self.currentDatabase == "a" ? "b" : "a"
  }
  
  func modelPaths() -> [String] {
    
    var modelPaths: [String] = []
    let momdArray: [String] = Bundle.main.paths(forResourcesOfType: "momd", inDirectory: nil)
    for momdPath: String in momdArray {
      let resourceSubpath = URL(fileURLWithPath: momdPath).lastPathComponent
      let array: [String] = Bundle.main.paths(forResourcesOfType: "mom", inDirectory: resourceSubpath)
      modelPaths += array
    }
    let otherModels: [String] = Bundle.main.paths(forResourcesOfType: "mom", inDirectory: nil)
    modelPaths += otherModels
    return modelPaths
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if object is NSMigrationManager, let manager = object as? NSMigrationManager {
      
      DispatchQueue.main.async {
        if manager.currentEntityMapping.name != nil {
          self.delegate?.progress(manager.migrationProgress, info: manager.currentEntityMapping.name)
        }
      }
      
      
    } else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
  }
  
}
