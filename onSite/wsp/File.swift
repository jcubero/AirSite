//
//  File.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-02-25.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
import CoreData
import Haneke

enum FileTypes: String {
  case Image = "jpg"
  case Excel = "xlsx"
  case DB = "db"
  case Zip = "zip"
  case Infield = "infield"
  case PDF = "pdf"
  case JSON = "json"
  static let allValues = [Image, Excel, DB, Zip, Infield, PDF, JSON]
}

@objc(File)

class File: SyncableModel {

  @NSManaged var fileType: String
  @NSManaged var fileQuality: String
  
  
  // relationships
  @NSManaged var project: Project?

  
  let fm = FolderManager.sharedInstance
  
  var type: FileTypes {
    get {
      for i in FileTypes.allValues {
        if i.rawValue == self.fileType {
          return i
        }
      }
      self.fileType = FileTypes.Image.rawValue
      return .Image
    } set {
      self.fileType = newValue.rawValue
    }
  }
  
  var path: URL {
    get {
      let path = self.fm.imageFolder
      return path.appendingPathComponent(self.filename)
    }
  }
  
  var filename: String {
    get {
      let ext = self.type.rawValue
      return "\(self.localId).\(ext)"
    }
  }
  
  var image: UIImage? { get {
    if self.type == .Image {
      let image = UIImage(contentsOfFile: path.path)
      if image == nil {
        Config.warn("Not an image!")
        
      }
      return image
    } else {
      Config.error("not an image!")
      return nil
    }
    } set {
      if let img = newValue {
        self.insertImage(img)
      } else {
        Config.error("Trying to set nil image")
      }
    }
  }
  
  var imageData: Data? { get {
    if self.type == .Image {
      return (try? Data(contentsOf: URL(fileURLWithPath: path.path)))
    } else {
      return nil
    }
    } set {
      if let data = newValue {
        self.type = .Image
        self.insertData(data)
      } else {
        Config.error("Trying to set nil image")
      }
    }
  }
  
  var pdfData: Data? { get {
    if self.type == .PDF {
      return (try? Data(contentsOf: URL(fileURLWithPath: path.path)))
    } else {
      return nil
    }
    } set {
      if let data = newValue {
        self.type = .PDF
        self.insertData(data)
      } else {
        Config.error("Trying to set nil pdf")
      }
    }
  } 
  
  var exportableFileStruct: FileStruct? {
    get {
      if let data = self.imageData {
        var fs =  FileStruct(url: path, type: self.type, blankWithData: data)
        let newId = ProcessInfo.processInfo.globallyUniqueString as String
        fs.name = newId
        return fs
      } else {
        return nil
      }
    }
  }
  
  var baseEncodedData: String {
    get {
      guard let data =  try? Data(contentsOf: URL(fileURLWithPath: path.path)) else {
        return ""
      }
      return data.base64EncodedString(options: .lineLength64Characters)
      
    }
  }

  func deleteFileData() {

    let fm = Foundation.FileManager.default

    do {
      try fm.removeItem(at: self.path)
      Config.info("Removed file: \(self.filename)")
    } catch let err {
      Config.error("Could not delete file: \(err)")
    }

  }
  
  func addFileFromPath(_ source: String, type: FileTypes) {
    
    self.type = type
    let fm = Foundation.FileManager.default
    
    if !fm.fileExists(atPath: source) {
      Config.error("File does not exist in source!")
      return
    }
   
    self.clearCacheOnDuplicate()
    
    do {
      try fm.moveItem(atPath: source, toPath: self.path.path)

    } catch {
      Config.error("\(error)")
    }
    
  }
  
  fileprivate func insertImage(_ image: UIImage) {
    
    
    self.type = .Image

    if let data = UIImageJPEGRepresentation(image, project!.jpegPhotoQuality) {
      self.insertData(data)

    } else {
      Config.error("Unable to convert image to data!")
    }
  }
  
  fileprivate func insertData(_ data: Data) {
    
    self.clearCacheOnDuplicate()
    var path = self.path

    // check if file exists; and if so, remove it and change the localId
    let fm = Foundation.FileManager.default
    if fm.fileExists(atPath: path.path) {
      Config.info("Removing previous file: \(self.filename)");
      do {
        try fm.removeItem(at: path)
        self.resetLocalId()
        path = self.path
      } catch let err {
        Config.error("\(err)")
      }
    }

    try? data.write(to: path, options: [.atomic])
    Config.info("Writing file: \(self.filename)")
    
  }
  
  
  fileprivate func clearCacheOnDuplicate() {
    
    let fm = Foundation.FileManager.default
    FileObjectManager.sharedInstance.clearCacheForProject(self.project!)
 
    if fm.fileExists(atPath: self.path.path) {
      Config.info("Clearing image cache.")
      Shared.imageCache.removeAll()
      
    }
    
  }
  

}



class FileObjectManager: NSObject, NSFetchedResultsControllerDelegate {
  
  static let sharedInstance = FileObjectManager()
  
  let fm = Foundation.FileManager.default
  
  fileprivate var cache: [String: UInt64]  = [:]
  
  func fileSizeForProject(_ project: Project, cb: @escaping (UInt64)->()) {
    
    let key = project.localId
    
    if let size = cache[key] {
      cb(size)
    } else {
      self.computeProjectSize(project, cb: cb)
    }
    
  }
  
  func clearCacheForProject(_ project: Project) {
    
    let key = project.localId
    self.cache.removeValue(forKey: key)
    
  }
  
  
  fileprivate func computeProjectSize(_ mainProject: Project, cb: @escaping (UInt64) -> ()) {
    
    let key = mainProject.localId

    NSManagedObjectContext.mr_default().mr_save({ (context) in
      
      guard let project = mainProject.mr_(in: context) else {
        Config.error()
        return
      }
      
      guard let files = File.mr_find(byAttribute: "project", withValue: project, in: context) as? [File] else {
        Config.error()
        return
      }
      
      var sum: UInt64 = 0
      
      for file in files {
        
        do {
          let fileAttributes = try self.fm.attributesOfItem(atPath: file.path.path)
          sum += (fileAttributes[FileAttributeKey.size] as! NSNumber).uint64Value
        } catch let err {
          Config.error("\(err)")
        }
      }
      
      self.cache[key] = sum
      
    }
        
        
//        , completion: { completion() in
//
//        if let size = self.cache[key] {
//          cb(size)
//        } else {
//          cb(0)
//        }
//    }
    )
    
  }
  
  
  
  
}



