//
//  ZipExport.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-10-13.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import Foundation
import zipzap
import MagicalRecord
import PromiseKit
import CryptoSwift

class ZipExport {
  
  var filename: URL!
  
  fileprivate var project: Project!
  fileprivate var entries:[ZZArchiveEntry] = []
  fileprivate var tempFolder: String!
  
  init(project: Project, ext: String = "zip") {
    
    self.project = project
    
    let pathComponent = FileManager_.safeFilename("\(project.nonEmptyProjectTitle) (export).\(ext)")
    self.tempFolder = NSTemporaryDirectory()
    self.filename = URL(fileURLWithPath: self.tempFolder).appendingPathComponent(pathComponent)
    
    if Foundation.FileManager.default.fileExists(atPath: self.filename.path) {
      do  {
        try Foundation.FileManager.default.removeItem(atPath: self.filename.path)
      } catch {
        Config.error("Cound not delete existing zip file at path \(self.filename.path)")
      }
    }
  }
  
  func addAllProjectFilesToArchive() -> Promise<Void> {
    return Promise<Void> { fulfill, reject in
      
      MagicalRecord.save({context in
        
        let project = self.project.mr_(in: context)!
        let files = File.mr_find(byAttribute: "project", withValue: project) as! [File]
        
        for file in files {
          
          let path = file.path
          let filename = file.filename
          
          let entry = ZZArchiveEntry(fileName: filename, compress: false, dataBlock: { _ -> Data! in
            if let data = try? Data(contentsOf: path) {
              return data
            } else {
              Config.error("File does not exist at path: \(path)")
              return Data()
            }
          })
          self.entries.append(entry)
          
        }
        
      }, completion: { endAllProjectFilesToArchive(fullfill: fulfill(())) }());
    }
    
  }
    func endAllProjectFilesToArchive(fullfill:Void) -> MRSaveCompletionHandler? {
        let saveCompletionHandler:MRSaveCompletionHandler? = nil
        return saveCompletionHandler
    }
  
  func addFileToArchive(_ filename: String, data: Data) {
    
    let entry = ZZArchiveEntry(fileName: filename, compress: false, dataBlock: { _ -> Data! in
      return data
    })
    
    self.entries.append(entry)
    
  }
  
  
  func addPlansToArchive() -> Promise<Void> {

    return Promise<Void> { fulfill, reject in

      let predicate = NSPredicate(format: "project = %@", self.project)
      let areas = Area.mr_findAll(with: predicate) as! [Area]
      
      for area in areas {
        let data = area.imageData
        let archiveEntry = ZZArchiveEntry(fileName: area.filename, compress: false) { _ -> Data! in
          return data
        }
        self.entries.append(archiveEntry)
        
      }
      fulfill(())
      
    }
    
    
  }
  
  func addExcelToArchive(withObservations observations:Bool, withPlans: Bool) -> Promise<Void> {
    
    return Promise<Void> { fulfill, reject in

        let exporter = ExcelExport(project: self.project, withObservations: observations, withPlans: withPlans)

        exporter.promise().then { file -> () in
          let excelFile = "\(self.project.nonEmptyProjectTitle).xlsx"

          let excelEntry = ZZArchiveEntry(fileName: excelFile, compress: false) { _ -> Data! in
            return (try? Data(contentsOf: file))
          }
          self.entries.append(excelEntry)
          fulfill(())

    }
    }
    
  }
  
  func addReportToArchive() -> Promise<Void> {
    
    return Promise<Void> { fulfill, reject in
      Manager.sharedInstance.exportSettings.loadDefaultSettingsFromProject(self.project)
      let exp = PDFExport(project: self.project, exportSettings: Manager.sharedInstance.exportSettings)


        exp.runInBackground() {
          let pdfFile = "\(self.project.nonEmptyProjectTitle) \(PDFFilenameAppendString).pdf"
          let pdfEntry = ZZArchiveEntry(fileName: pdfFile, compress: false) { _ -> Data! in
            return (try? Data(contentsOf: exp.filename!))
          }
          self.entries.append(pdfEntry)
          fulfill(())
      }}
    
  }
  
  func addPhotosToReport() -> Promise<Void> {
    
    return Promise<Void> { fulfill, reject in
      MagicalRecord.save({context in
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let project = self.project.mr_(in: context)!
        let predicate = NSPredicate(format: "area.project = %@", project)
        
        guard let issues = Issue.mr_findAll(with: predicate, in: context) as? [Issue] else {
          Config.error()
          return
        }
        
        for issue in issues {
          
          let commentPredicate = NSPredicate(format: "issue = %@ and imageFile != nil", issue)
          
          guard let comments = Comment.mr_findAllSorted(by: "createdDate", ascending: true, with: commentPredicate, in: context) as? [Comment] else {
            Config.error()
            continue
          }
          
          
          for (index, comment) in comments.enumerated()  {
            
            let filename = "\(comment.exportNameForSequence(index + 1)).jpg"
            let imageURL = URL(fileURLWithPath: self.tempFolder).appendingPathComponent(filename)
            
            autoreleasepool() {
              let image = comment.renderCommentPhotoWithPill(nil, usePercentage: true)!
              
              if let data = UIImageJPEGRepresentation(image, project.jpegPhotoQuality) {
                try? data.write(to: imageURL, options: [.atomic])
              } else {
                Config.error("Could not convert photo to JPEG")
              }
              
            }
            
            let imageEntry = ZZArchiveEntry(fileName: filename, compress: false) { _ -> Data! in
              return (try? Data(contentsOf: imageURL))
            }
            self.entries.append(imageEntry)
            
          }
          
        }
        
        }, completion: { _, _ in
          fulfill(())
      });
    }
    
  }
  
  func addJSONToArchive() -> Promise<Void> {
    
    return Promise<Void> { fulfill, reject throws in
      let json = JSONExport(project: self.project)
      let data = try json.exportProject()
      if Manager.sharedInstance.features.exportUnencryptedFiles {
        self.addFileToArchive("export.json", data: data)
      } else {
        let encryptedData = try data.encrypt(cipher: AES(key: Config.INFIELDKEY, iv: Config.INFIELDIV))
        self.addFileToArchive("export.json", data: encryptedData)
      }
      fulfill(())
    }
    
    
  }
  
  
  func packageZipFile() throws {
    
    let archive = try ZZArchive(url: self.filename, options: [ZZOpenOptionsCreateIfMissingKey: true])
    try archive.updateEntries(self.entries)
    
    
  }
  
  
}
