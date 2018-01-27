//
//  Errors.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-06-23.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import Foundation


enum Throwable: Error {
  case `import`
  case clone
  case db
  case network
  case noNetwork
  case abort
  case authorization
  case conflict
  case invalidGroup
}


class LogFiles {
  
  static let sharedInstance = LogFiles()
  
  let fm = FolderManager.sharedInstance
  let fileManager = FileManager.default
  
  var filename: String = "infield.log"
  
  lazy var path: URL  = {
    let path = self.fm.imageFolder
    return path.appendingPathComponent(self.filename)
  }()
  
  lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
  }()
  
  var readyForWriting:Bool = false
  
  init() {
    if !fileManager.fileExists(atPath: path.path) {
     fileManager.createFile(atPath: path.path, contents: nil, attributes: nil)
    }
    readyForWriting = true
  }
  
  
  func write(_ log: String) {
    
    if !readyForWriting { return }
    
    
    let dateString = dateFormatter.string(from: Date())
    let string = "\(dateString) - \(log)\n"
    let data = string.data(using: String.Encoding.utf8)!
    
    do {
      readyForWriting = false
      let fileHandle = try FileHandle(forWritingTo: path)
      
      defer {
        readyForWriting = true
        fileHandle.closeFile()
      }
      
      fileHandle.seekToEndOfFile()
      fileHandle.write(data)
    } catch let err {
      readyForWriting = false
      Config.error("\(err)")
      
    }
  }
  
  
  func read() -> String {
    
    do {
      let string = try NSString(contentsOfFile: path.path, encoding: String.Encoding.utf8.rawValue) as String
      
      let logs = string.components(separatedBy: CharacterSet.newlines)
      let reved = logs.reversed()
      
      return reved.joined(separator: "\n")
      
    } catch let err {
      Config.error("\(err)")
      return ""
    }
    
  }
  
  func clear() {
    
     fileManager.createFile(atPath: path.path, contents: nil, attributes: nil)
    
    
    
  }
  
  
}
