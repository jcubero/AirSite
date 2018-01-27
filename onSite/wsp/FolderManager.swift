//
//  FolderManager.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-02-25.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
import MagicalRecord


class FolderManager {
  
  static let sharedInstance = FolderManager()

  
  lazy var imageFolder: URL = {
    
    let paths = Foundation.FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsURL = paths[0]
    return  documentsURL.appendingPathComponent("images/")
    
  }()
  
  
  lazy var logsFolder: URL = {
    
    let paths = Foundation.FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsURL = paths[0]
    return  documentsURL.appendingPathComponent("logs/")
    
  }()
  
  
  
  init () {
    
    
    if !Foundation.FileManager.default.fileExists(atPath: imageFolder.path) {
      do {
        try Foundation.FileManager.default.createDirectory(at: imageFolder, withIntermediateDirectories: false, attributes: nil)
      } catch {
        Config.error("Couldn't create image folder!")
        abort()
      }
    }
    
    if !Foundation.FileManager.default.fileExists(atPath: logsFolder.path) {
      do {
        try Foundation.FileManager.default.createDirectory(at: logsFolder, withIntermediateDirectories: false, attributes: nil)
      } catch {
        Config.error("Couldn't create logs folder!")
        abort()
      }
    }
    
    
  }
  
  func cleanupStorage() {
    
    
    MagicalRecord.save({ context in
        
        do {
            let directoryContents = try Foundation.FileManager.default.contentsOfDirectory(at: self.imageFolder, includingPropertiesForKeys: nil, options: Foundation.FileManager.DirectoryEnumerationOptions())
            let imageSet = Set(directoryContents)
            Config.info("Found \(imageSet.count) files")
            
            let files = File.mr_findAll(in: context) as! [File]
            let paths = files.map { $0.path }
            let fileSet = Set(paths)
            
            let orphans = imageSet.subtracting(fileSet)
            
            if orphans.count > 0  {
                Config.error("Found \(orphans.count) orphaned files")
                for orphan in orphans {
                    try Foundation.FileManager.default.removeItem(at: orphan)
                }
            } else {
                Config.info("Nothing to clean up")
            }
            
            
            
        } catch {
            Config.error()
        }
        
    })
    
    
  }
}
