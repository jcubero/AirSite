//
//  SyncProject.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-06-28.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
import PromiseKit
import MagicalRecord
import SwiftyJSON

struct ProgressPiece {

  var piece: Float
  var progress: Float
}


class  EstimatedPieces {


  var progress: Float = 0

  var values: [Float]
  var countOfItems: [Int]

  let subdivisions: [String]

  init(subdivisions: [String]) {
    self.subdivisions = subdivisions

    let initialFraction: Float =  1 / Float(self.subdivisions.count)
    var current: Float = 0

    self.values = []
    self.countOfItems = []
    for _ in subdivisions {
      self.values.append(current)
      self.countOfItems.append(1)
      current += initialFraction
    }

  }

  func progressAtItem(item: String) -> Float {

    guard let index = subdivisions.index(of: item) else { Config.error(); return 0 }
    return values[index]

  }

  func pieceAtItem(item: String) -> Float {

    guard let index = subdivisions.index(of: item) else { Config.error(); return 0 }

    let currentValue = values[index]

    if index >= values.count - 1 {
      return 1 - currentValue
    } else {
      return values[index + 1] - currentValue
    }

  }

  func from(item: String, adjust: String, withNumberOfItems: Int) {


    guard let itemIndex = subdivisions.index(of: item) else { Config.error(); return }
    guard let adjustIndex = subdivisions.index(of: adjust) else { Config.error(); return }

    let nextItemIndex = itemIndex + 1
    let lastItemIndex = subdivisions.count - 1

    if nextItemIndex > adjustIndex { return }
    if nextItemIndex  >= lastItemIndex { Config.error(); return }

    objc_sync_enter(countOfItems)
    countOfItems[adjustIndex] = withNumberOfItems
    objc_sync_exit(countOfItems)

    var numOfItems = 0
    for i in nextItemIndex...lastItemIndex {
      numOfItems += countOfItems[i]
    }

    var currentProgress = progressAtItem(item: item)
    let remainingProgress = 1 - currentProgress
    let progressPerPiece = remainingProgress / Float(numOfItems)

    for i in nextItemIndex...lastItemIndex {
      let countForItem = countOfItems[i - 1]
      let fraction = progressPerPiece * Float(countForItem)
      currentProgress += fraction
      objc_sync_enter(values)
      values[i] = currentProgress
      objc_sync_exit(values)
    }

  }


}




class SyncProject {
  
  let tempPath = NSTemporaryDirectory()
  
  var manager: Manager = Manager.sharedInstance
  var network: Network { return manager.network }
  var sourceProject: Project!
  
  
  var project: Project!
  var localId: String
  var context: NSManagedObjectContext!
  
  var aborted: Bool = false
  
  var currentFileManifest: [String] = []
  var finalJSON: JSON!
    
    
    
    
    var finalFileManifest: [String] = []
  
  var remoteFiles: [String: ServerData] = [:]
  
  var idsToDelete: [String]  = []
  
  var downloadOnly: Bool = false
  
  let fm = FileManager()
  
  var pieces: EstimatedPieces!
  
  init(project: Project?, localId: String) {
    
    self.localId = localId
    
    if let project = project {
      self.sourceProject = project
      self.downloadOnly = false
    } else {
      self.downloadOnly = true
      
    }
  }
  
    
  func start(cb: @escaping () -> ()) {
    
    UIApplication.shared.isNetworkActivityIndicatorVisible = true

    currentFileManifest = []
    finalFileManifest = []
    remoteFiles = [:]
    idsToDelete = []

    self.pieces = EstimatedPieces(subdivisions: [
      "authenticateWithServer",
      "downloadProjects",
      "mergeProjects",
      "downloadProjectFileList",
      "findFilesMissingOnServer",
      "uploadMissingFiles",
      "uploadProject",
      "downloadAndCollectFiles",
      "deleteAndRecreateProjectWithFiles",
      "deleteMergedProjects",
      ])
    
    dispatch_promise(Config.privateQueue) { () -> () in
      self.context = NSManagedObjectContext.mr_()

      if self.downloadOnly {
        self.project = Project.create(self.context)
        self.project.setPrimitiveValue(self.localId, forKey: "localUnique")

        self.pieces.from(item: "authenticateWithServer", adjust: "findFilesMissingOnServer", withNumberOfItems: 0)
        self.pieces.from(item: "authenticateWithServer", adjust: "uploadProject", withNumberOfItems: 0)

      } else {
        self.project = self.sourceProject.mr_(in: self.context)
        
      }
      
      }
      .then(on: Config.privateQueue, execute: self.authenticateWithServer)
      .then(on: Config.privateQueue, execute: self.downloadProjects)
      .then(on: Config.privateQueue, execute: self.mergeProjects)
      .then(on: Config.privateQueue, execute: self.downloadProjectFileList)
      .then(on: Config.privateQueue, execute: self.findFilesMissingOnServer)
      .then(on: Config.privateQueue, execute: self.uploadMissingFiles)
      .then(on: Config.privateQueue, execute: self.uploadProject)
      .then(on: Config.privateQueue, execute: self.downloadAndCollectFiles)
      .then(on: Config.privateQueue, execute: self.deleteAndRecreateProjectWithFiles)
      .then(on: Config.privateQueue, execute: self.deleteMergedProjects)
      .then(on: DispatchQueue.main, execute: { ()  -> Promise<Void> in
        return Promise<Void> { f, r in
          self.manager.stopNetworkActivity()
          cb()
            f(())
        }
      }).catch { error in
        

        do {
        
            throw error
            
        } catch Throwable.abort {
        
            self.manager.stopNetworkActivity()
            
            cb()
            
        } catch Throwable.conflict {
        
            self.manager.showNetworkInfo("Merge Conflict", message: "A merge conflict has occured preventing sync with the server, a new project has been created instead.")
                  self.project.updateLocalKeys()
                  self.project.title = self.project.nonEmptyProjectTitle + " (Conflict)"
                  self.context.mr_saveToPersistentStoreAndWait()
                  cb()
                } catch Throwable.invalidGroup {
                  self.project.updateLocalKeys()
                  self.context.mr_saveToPersistentStoreAndWait()
                  self.start(cb: cb)
                } catch Throwable.noNetwork {
                  self.manager.showNetworkError("Lost connection to the server")
                } catch let err {
                  Config.network("Error: \(err)")
                  self.manager.showNetworkError("A network error occured")
                }
        }
        .always{
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
  
  func authenticateWithServer() -> Promise<Void> {
    let otherUser = self.manager.getCurrentUser()
    let user = otherUser.mr_(in: context)!
    return SyncUsers.authenticateUser(user)
    
  }
  
  
  func deleteMergedProjects() throws -> Promise<Void> {
    
    let promise: Promise<Void> = Promise<Void> { f, r in f(()) }

    self.manager.updateNetworkStatus("Deleting merged project from server.", progress: self.pieces.progressAtItem(item: "deleteMergedProjects"))

    if self.idsToDelete.count > 0 && !self.downloadOnly {
      let route = try Config.Routes.deleteProjects(project, ids: self.idsToDelete)
      
      return network
        .request(request: route)
        .then { _ -> () in
          
      }
    } else {
      return promise
    }
    
  }

  func deleteAndRecreateProjectWithFiles(files: [FileStruct]) throws -> Void {
    
    self.manager.updateNetworkStatus("Saving project to iPad.", progress: self.pieces.progressAtItem(item: "deleteAndRecreateProjectWithFiles"))
    Manager.sharedInstance.preventFileDetetion = true
    self.project.mr_deleteEntity(in: context)
    
    self.project = try Project.createFromJSONInContext(context, json: self.finalJSON, files: files, preservingFileKeys: true)
    
    self.context.mr_saveToPersistentStoreAndWait()
    Manager.sharedInstance.preventFileDetetion = false
    
  }
  
    func downloadAndCollectFiles() throws -> Promise<[FileStruct]> {


        var set1 = Set<String>()
        var set2 = Set<String>()
        
        var index = 0;
        for _ in self.finalFileManifest {
            set1.insert(self.finalFileManifest[index])
            index += 1;
        }
        
        index = 0;
        for _ in self.currentFileManifest {
            set2.insert(self.finalFileManifest[index])
            index += 1;
        }
        
        let missingFiles = set1.subtracting(set2)
        
    var promise: Promise<[FileStruct]> = Promise<[FileStruct]> { f, r in f([]) }
    
    let total = missingFiles.count
    let piece: Float = (1 / Float(total)) * self.pieces.pieceAtItem(item: "downloadAndCollectFiles")
    var currentProgress = self.pieces.progressAtItem(item: "downloadAndCollectFiles")

    if total > 0 {
      self.manager.updateNetworkStatus("Downloading image 1 of \(total).", progress: currentProgress)
    }
    
    for (index, file) in missingFiles.enumerated() {
      guard let fileEntity = self.remoteFiles[file] else {
        Config.error("File needed by project missing on server: \(file)")
        throw Throwable.network
      }
      let type = fileEntity[Config.Fields.File.fileType] as! String
      let path = "\(file).\(type)"
      let destination = NSURL(fileURLWithPath: tempPath).appendingPathComponent(path)
 
      promise = promise.then(on: Config.privateQueue,  execute: { files -> Promise<[FileStruct]> in
        var mutatingFiles = files
        do {
          try self.fm.removeItem(at: destination!) 
        } catch {
          
        }
        
        if self.aborted {
          throw Throwable.abort
        }
        
        
        return try Config.networkConfig.downloadFileToLocation(self.remoteFiles[file]!, destination: destination!, currentProgress: currentProgress, diff: piece)
          .then { url -> [FileStruct] in
          let file = FileStruct(url: url, name: file, type: FileTypes(rawValue: type)!)

          currentProgress += piece
          if index + 2 <= total {
            self.manager.updateNetworkStatus("Downloading image \(index + 2) of \(total).", progress: currentProgress)
          }
          
          if self.aborted {
            throw Throwable.abort
          }
          
          mutatingFiles.append(file)
          return mutatingFiles
          
        }
      })
    }
    
    
    promise = promise.then(on: Config.privateQueue, execute: { files throws -> [FileStruct] in
      var mutatingFiles = files
      
      let predicate = NSPredicate(format: "project = %@", self.project)
      guard let existingFiles = File.mr_findAll(with: predicate, in: self.context) as? [File] else {
        Config.error()
        throw Throwable.db
      }
        
      for file in existingFiles {
        
        let destination = NSURL(fileURLWithPath: self.tempPath).appendingPathComponent(file.filename)
        
        do {
          try self.fm.removeItem(at: destination!) 
        } catch {
          
        }
        if self.fm.fileExists(atPath: file.path.path) {
          try self.fm.moveItem(at: file.path, to: destination!)
          let file = FileStruct(url: destination!, name: file.localId, type: file.type)
          mutatingFiles.append(file)
          
        }
        
      }
      
      return mutatingFiles
      
    })
    
    return promise
    
    
  }
  
  
  func downloadProjectFileList() -> Promise<[ServerData]> {
    
    self.manager.updateNetworkStatus("Downloading list of files.", progress: self.pieces.progressAtItem(item: "downloadProjectFileList"))
    
    return network.request(request: Config.Routes.listFiles(project))
      .then(on: Config.privateQueue, execute: { json in
        return Promise<[ServerData]> { fulfill, reject in
          if let ret = json.arrayObject as? [ServerData] {
            
            for item in ret {
              self.remoteFiles[item[Config.Fields.File.localId] as! String] = item
            }
            
            if self.aborted {
              throw Throwable.abort
            }
            
            fulfill(ret)
          } else {
            reject(Throwable.network)
          }
        }
      })
    
  }
  
  
  func downloadProjects() -> Promise<[JSON]> {
    

    let currentProgress = self.pieces.progressAtItem(item: "downloadProjects")
    self.manager.updateNetworkStatus("Downloading project information.", progress: currentProgress)

    let request = Config.Routes.getProjects(project)
    request.preProgress = currentProgress
    request.postProgress = currentProgress + self.pieces.pieceAtItem(item: "downloadProjects")

    return network
      .request(request: request)
      .then  { json -> [JSON] in

        if self.aborted {
          throw Throwable.abort
        }

        guard let currentGroupId = Manager.sharedInstance.user.domain?.id else {
          throw Throwable.authorization
        }

        var jsons: [JSON] = []
        var groupIds: [String] = []
        for subjson in json.arrayValue {
          groupIds.append(subjson[Config.Fields.Project.groupId].stringValue)
          let jsonString = subjson[Config.Fields.Project.data].stringValue
          let j = try JSON(data: jsonString.asData())
          self.idsToDelete.append(subjson[Config.Fields.Project.id].stringValue)
          jsons.append(j)
        }

        if groupIds.count > 0 {
          if !groupIds.contains(currentGroupId) {
            throw Throwable.invalidGroup
          }
        }

        return jsons
        
    }
    
    
  }
  
  
  func mergeProjects(jsonsIm: [JSON]) -> Promise<Void> {
    
    
    return Promise<Void> { fulfill, reject throws in

      self.manager.updateNetworkStatus("Merging projects.", progress: self.pieces.progressAtItem(item: "mergeProjects"))

      var jsons = jsonsIm
      var json: JSON!
      
      if self.downloadOnly {
        if jsons.count == 0 {
          Config.error("No json objects found for project!")
          throw Throwable.network
        }
        json = jsons.last!
        jsons = Array(jsons.dropLast())
      } else {
        let export = JSONExport(project: self.project)
        json = export.exportJSON()
      }
      
      
      var deletions = Project.combineDeletions(json[SyncableModel.deletionKey], into: [])
      
      guard let cleaned = try Project.verifyIntegrity(json) else {
        Config.error("Couldn't verify the JSON object returned from the server")
        throw Throwable.network
      }

      json = cleaned

      for remoteJson in jsons {
        guard let cleanedRemoteJSON = try Project.verifyIntegrity(remoteJson) else {
          Config.error("Couldn't verify the JSON object returned from the server")
          throw Throwable.network
        }
        json = try Project.mergeJSON(json, optSecondJSON: cleanedRemoteJSON)
        deletions = Project.combineDeletions(cleanedRemoteJSON[SyncableModel.deletionKey], into: deletions)
      }
      
      var process = try Project.mergeDeletions(json, deletions: deletions)
      let dels = Project.deletionsToJSON(deletions)
      
      process[SyncableModel.deletionKey] = dels
      self.finalJSON = process
      
      let entityIds = Set(try Project.getListOfEntityIds(self.finalJSON))
      let relationshipIds = Set(try Project.getListOfRelationshipIds(self.finalJSON))
      let leftOvers = relationshipIds.subtracting(entityIds)

      if leftOvers.count > 0 {
        Config.error("Merge conflict detected on: \(self.finalJSON["title"].stringValue) with \(leftOvers.count) conflicts.")
        throw Throwable.conflict
      }
      
      
      self.finalFileManifest = try Project.createFileManifest(json)

        fulfill(test())
    }
  }


    func test(){
        
        
    }
  func uploadProject() throws -> Promise<Void> {
    
    
    if self.downloadOnly {
      return Promise<Void> {f, r in f(test()) }
      
    }

    let currentProgress = self.pieces.progressAtItem(item: "uploadProject")
    self.manager.updateNetworkStatus("Uploading project data.", progress: currentProgress)

    let json = self.finalJSON.rawString()!
    let usersSet = try Project.createUserManifest(self.finalJSON)
    let users = JSON(Array(usersSet))

    let route = try Config.Routes.uploadProject(project, json: json, userManifest: users.rawString()!)
    route.preProgress = currentProgress
    route.postProgress = currentProgress + self.pieces.pieceAtItem(item: "uploadProject")

    return network.request(request: route)
      .then(on: Config.privateQueue) { _ -> Promise<Void> in
      return Promise<Void> { fulfill, reject throws in
        fulfill(self.test())
      }
    }
    
  }
  
  
  
  func findFilesMissingOnServer(data: [ServerData]) -> Promise<[File]> {
    
    return Promise<[File]> { fulfill, reject in

      self.manager.updateNetworkStatus("Getting file list from server.", progress: self.pieces.progressAtItem(item: "findFilesMissingOnServer"))

      let predicate = NSPredicate(format: "project = %@", self.project)
      guard let files = File.mr_findAll(with: predicate, in: self.context) as? [File] else {
        Config.error()
        reject(Throwable.db)
        return
      }
      
      self.currentFileManifest = files.map { "\($0.localId)" }
      
      let newFiles = files.filter { file in
        for d in data {
          guard let localId = d[Config.Fields.File.localId] as? String else {
            Config.error()
            continue
          }
          if localId == file.localId {
            return false
          }
        }
        return true
        
      }
      
      let localMissingFiles = data.filter { d in
        guard let localId = d[Config.Fields.File.localId] as? String else {
          Config.error()
          return false
        }
        for file in files {
          if localId == file.localId {
            return false
          }
        }
        return true
      }
      
      let numberOfFilesNotOnServer = newFiles.count
      let numberOFFilesNotLocal = localMissingFiles.count

      Config.network("Files not on server: \(numberOfFilesNotOnServer)")
      Config.network("Files not local: \(numberOFFilesNotLocal)")
      Config.network("Files in both places: \(files.count - numberOfFilesNotOnServer)")

      self.pieces.from(item: "findFilesMissingOnServer", adjust: "downloadAndCollectFiles", withNumberOfItems: numberOFFilesNotLocal)
      self.pieces.from(item: "findFilesMissingOnServer", adjust: "uploadMissingFiles", withNumberOfItems: numberOfFilesNotOnServer)

      fulfill(newFiles)
    }
  }
  
  func uploadMissingFiles(files: [File]) -> Promise<Void> {
    
    let total = files.count
    let piece: Float = (1 / Float(total)) * self.pieces.pieceAtItem(item: "uploadMissingFiles")
    let currentProgress = self.pieces.progressAtItem(item: "uploadMissingFiles")
    
    var promise: Promise<Void> = Promise<Void> { f, r in  }
    
    if total > 0 {
      self.manager.updateNetworkStatus("Uploading \(1) of \(total) files.", progress: currentProgress)

      for (index, file) in files.enumerated() {
        promise = promise.then(on: Config.privateQueue, execute: {
          return try self.uploadFile(file: file, index: index, total: total, piece: piece)
        })
        
      }
    }
    
    return promise
    
  }
  
  func uploadFile(file: File, index: Int, total: Int, piece: Float) throws -> Promise<Void> {

    let request = try Config.Routes.uploadFile(project, file: file)
    let currentProgress = self.pieces.progressAtItem(item: "uploadMissingFiles") + piece * Float(index)

    request.preProgress = currentProgress
    request.postProgress = currentProgress + piece

    return network.request(request: request)
      .then(on: Config.privateQueue) { _ -> Promise<Void> in
      
      return Promise<Void> { fulfill, reject throws in
        
        if index + 2 <= total {
          self.manager.updateNetworkStatus("Uploading \(index + 2) of \(total) files.", progress: currentProgress + piece)
        }
        if self.aborted {
          throw Throwable.abort
        }
        fulfill(self.test())
        
      }
    }
  }
  
}
