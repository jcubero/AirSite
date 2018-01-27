//
//  FileManager.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-10-05.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import Foundation


import Foundation
import UIKit
import MobileCoreServices
import zipzap
import PromiseKit
import CryptoSwift

struct FileStruct {
  var name: String
  var type: FileTypes
  var data: Data
  var path: String?
  var fullName: String?
  
  init(url: URL?, type: FileTypes, blankWithData: Data) {
    self.name = ""
    self.data = blankWithData
    self.path = url?.path
    self.type = type
  }
  
  init(url: URL?, type: FileTypes, title: String, data: Data) {
    self.name = title
    self.data = data
    self.path = url?.path
    self.type = type
  }
  
  init(url: URL, name: String,  type: FileTypes) {
    
    self.name = name
    self.data = Data()
    self.path = url.path
    self.type = type
    
  }
  
}

enum SelectOptions {
  case filePicker
  case camera
  case library
}

protocol FilesDelegate: class {
  func filesDidDismiss()
  func handlerDidLaunch()
}

class FileManager_ : NSObject, UIDocumentMenuDelegate, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
 
  var refferingViewController : UIViewController!
  weak var delegate: FilesDelegate?
  var selectOptions: [SelectOptions] = []
  var fileTypes: [FileTypes] = []
  
  var callback: (([FileStruct]) -> ())!
  var options: [String: ()->()] = [:]
  
  let picker: UIImagePickerController = UIImagePickerController()
  
  init(vc: UIViewController, forFileTypes: [FileTypes]) {
    
      self.refferingViewController = vc
      self.selectOptions = [.camera, .library, .filePicker]
      self.fileTypes = forFileTypes
      self.callback = { _ -> () in }
      super.init()
      
      self.picker.delegate = self
    
  }
  

  func addOptionWithTitleAndCallback(_ title: String, callback: @escaping ()->()) {
    
    self.options[title] = callback
    
  }
  
  func shareFile(_ file: URL, cb: @escaping ([FileStruct])->()) {
    
    self.callback = cb
    
    let documentPicker = UIDocumentPickerViewController(url: file, in: .exportToService)
    documentPicker.delegate = self
    self.refferingViewController.present(documentPicker, animated: true, completion: nil)
  }
  
  func loadFilePicker(_ callback: @escaping ([FileStruct]) -> ()) {
    
    self.callback = callback
    
    var documentType = [kUTTypeData as String, kUTTypeImage as String, kUTTypePlainText as String]
    
    if self.fileTypes.count == 1 && self.fileTypes.contains(.Image) {
      documentType = [kUTTypeImage as String]
    }
    let documentPicker = UIDocumentPickerViewController(documentTypes: documentType, in: .import)
    documentPicker.delegate = self
    self.refferingViewController.present(documentPicker, animated: true, completion: nil)
    
  }
  
  
  func loadImagePickerInViewController(_ location: CGRect, cb: @escaping ([FileStruct]) -> ()) {
    
    self.callback = cb
    
    let picker: UIImagePickerController = UIImagePickerController()
    picker.delegate = self
    
    picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
    let popover = UIPopoverController(contentViewController: picker)
    popover.present(from: location, in: self.refferingViewController.view, permittedArrowDirections: .any, animated: true)
    
  }
  
  
  
  // MARK: document menu and document picker
  
  func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
    documentPicker.delegate = self
    if let vc = self.refferingViewController {
      vc.present(documentPicker, animated: true, completion: nil)
    }
    
  }
  
  func documentMenuWasCancelled(_ documentMenu: UIDocumentMenuViewController) {
    self.delegate?.filesDidDismiss()
  }
 
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
    
    if (controller.documentPickerMode == UIDocumentPickerMode.import) {

      let filename = (url.lastPathComponent as NSString).deletingPathExtension as String
      let ext = url.pathExtension
      
      
      if self.fileTypes.contains(.Image) {
        if let data = try? Data(contentsOf: URL(fileURLWithPath: url.path)) {
          
          if self.validateImage(data) {
            var file = FileStruct(url: url, type:.Image, blankWithData: data)
            file.name = filename
            self.callback([file])
            url.stopAccessingSecurityScopedResource()
            return
          }
        }
      }
      
      if self.fileTypes.contains(.Excel) {
       
        if ext == "xlsx" {
          var file = FileStruct(url: url, type: .Excel, blankWithData: try! Data(contentsOf: url))
          file.name = filename
          self.callback([file])
          url.stopAccessingSecurityScopedResource()
          return
        }
        
      }
      
      if self.fileTypes.contains(.PDF) {
       
        if ext == "pdf" {
          var file = FileStruct(url: url, type: .PDF, blankWithData: try! Data(contentsOf: url))
          file.name = filename
          self.callback([file])
          url.stopAccessingSecurityScopedResource()
          return
        }
        
      }
      
      // must be last
      if self.fileTypes.contains(.Zip) {
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
          self.handleMultipleZipImageSelect(url)
        })
        url.stopAccessingSecurityScopedResource()
        return
      }
      
      // unknown FileStruct chosen
      
      Config.error("Invalid file \(url.path) selected")
      self.callback([])
      
    } else {
      self.callback([])
      
    }
    
    url.stopAccessingSecurityScopedResource()
    
  }

  func handleMultipleZipImageSelect(_ url: URL) {
    
    // check for path extension, and load things based on that
    let ext = url.pathExtension
    let manager = Manager.sharedInstance
    
    
    let message = NSLocalizedString("Importing zip archive", comment: "Importing zip archive")
    manager.startActivity(withMessage: message)
    
    var returnFiles: [FileStruct] = []
    
    if ext == "zip" || ext == Config.projectFileExtension {
      // archives
      let projectExt = ext
      do {
        let archive = try ZZArchive(url: url)
        var images: [FileStruct]  = []
        
        for entry in archive.entries {
          do {
            let fileName = entry.fileName
            let data:Data = try entry.newData()
            let ext = (fileName as NSString).pathExtension
            let name = (fileName as NSString).deletingPathExtension
            if ext == "xlsx" {
              // let write the file somewhere first
              
              let pathComponent = ProcessInfo.processInfo.globallyUniqueString + ".xlsx"
              let path = NSTemporaryDirectory()
              let url = URL(fileURLWithPath: path).appendingPathComponent(pathComponent)
              try? data.write(to: url, options: [.atomic])
              var file = FileStruct(url: url, type: .Excel, title: name as String, data: data)
              file.fullName = fileName
              images.append(file)
              
            } else if ext == "json" {
              // write the file somewhere first
              if let fileStruct = self.processJSONInArchive(data, name: name, fileName: fileName, containerExtension: projectExt) {
                images.append(fileStruct)
              }
              

            } else if ext == "pdf" {
              
              if projectExt == Config.projectFileExtension {
                var file = FileStruct(url: nil, type: .PDF, title: name as String, data: data)
                file.fullName = fileName
                images.append(file)
                
              } else {
                
                let provider = CGDataProvider( data: data as CFData)
                if provider != nil {
                  let pdf = CGPDFDocument(provider!)
                  if pdf != nil {
                    if let d  = self.makeImageFromPDF(pdf!) {
                      var file = FileStruct(url: nil, type: .Image, title: name as String, data: d)
                      file.fullName = fileName
                      images.append(file)
                    }
                  }
                }
              }
              
            } else if UIImage(data: data) != nil {
              var file = FileStruct(url: nil, type: .Image, title: name as String, data: data)
              file.fullName = fileName
              images.append(file)
            }
          } catch {
            Config.error("Found unknown file in archive")
          }
        }
        
        if images.count > 0 {
          returnFiles = images
        }
      } catch {
        Config.error("Could not open zip file, aborting")
      }
      
    } else if ext == "pdf" {
      // pdf document
        
        let pdfDocumentRef = CFURLCreateWithFileSystemPath(nil, url.absoluteString as CFString, CFURLPathStyle.cfurlposixPathStyle, false)
        
        if let pdf = CGPDFDocument(pdfDocumentRef!) {
        if let d = self.makeImageFromPDF(pdf) {
          returnFiles = [FileStruct(url: nil,  type: .Image, blankWithData: d)]
        }
      }
    } else {
      // image
      if let data = try? Data(contentsOf: URL(fileURLWithPath: url.path)) {
        if self.validateImage(data) {
          returnFiles = [FileStruct(url: nil, type: .Image, blankWithData: data)]
        }
      }
    }
    
    manager.stopActivity({
      self.callback(returnFiles)
    })
    
  }
  
  func validateImage(_ image: Data) -> Bool {
    
    if UIImage(data: image) == nil {
      return false
    }
    return true
    
  }

  func processJSONInArchive(_ data: Data, name: String, fileName: String, containerExtension: String) -> FileStruct? {

    let pathComponent = ProcessInfo.processInfo.globallyUniqueString + ".json"
    let path = NSTemporaryDirectory()
    let url = URL(fileURLWithPath: path).appendingPathComponent(pathComponent)
    
    var decryptedJsonData: Data? = nil
    if containerExtension == Config.projectFileExtension {
      do {
        decryptedJsonData = try data.decrypt(cipher: AES(key: Config.INFIELDKEY, iv: Config.INFIELDIV))
        Config.info("Will attempt decrypted \(fileName) in InField file.")
      } catch {
        Config.info("Could not decrypt \(fileName) in InField file. Will not attempt.")
        if !Manager.sharedInstance.features.allowImportOfUnencryptedInfieldFiles {
          return nil
        }
      }
    }


    var validData: Data? = nil
    if let jsonData = decryptedJsonData {
      do {
        try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        validData = jsonData
      } catch let err {
        Config.error("Could not decode encrypted JSON file: \(err)")
        if !Manager.sharedInstance.features.allowImportOfUnencryptedInfieldFiles {
          return nil
        }
      }
    }

    if validData == nil {
      do {
        try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        validData = data
      } catch let err {
        Config.error("Could not decode JSON file: \(err)")
      }
    }

    if let data = validData {
      try? data.write(to: url, options: [.atomic])
      var file = FileStruct(url: url, type: .JSON, title: name as String, data: data)
      file.fullName = fileName
      return file
    } else {
      return nil
    }

  }
  
  
  func makeImageFromPDF(_ pdf: CGPDFDocument) -> Data? {
    
    let page = pdf.page(at: 1)
    if page == nil {
      return nil
    }
    let cropBox = page?.getBoxRect(CGPDFBox.cropBox)
    let minSize: CGFloat = 3000
    let value = CGFloat(12.0) + CGFloat(13.0)
    // let scale =  cropBox.width > cropBox.height ? minSize / cropBox.height : minSize / cropBox.width

    var scale:CGFloat
    if (cropBox?.width.isLess(than: (cropBox?.height)!))!{
        scale = minSize / (cropBox?.height)!
    }
    else{
        scale = minSize / (cropBox?.width)!
    }
    //let scale =  cropBox?.width.isLess(than: (cropBox?.height)!)? minSize / (cropBox?.height)! : minSize / (cropBox?.width)!
    let size = CGSize(width: (cropBox?.width)! * scale, height: (cropBox?.height)! * scale)
    let rect = CGRect(origin:CGPoint.zero, size:size)
    
    UIGraphicsBeginImageContextWithOptions(size, false, 1)
    
    let context = UIGraphicsGetCurrentContext()
    
    
    context?.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    context?.fill(rect)
    context?.translateBy(x: -1.0, y: size.height)
    // Todo: context.scaleBy(x: scale, y: -scale)
    context?.drawPDFPage(page!)
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    let data = UIImageJPEGRepresentation(image!, Project.areaPhotoQuality)
  
    return data
    
  }
  
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    self.delegate?.filesDidDismiss()
    
  }
  
  // MARK: image picker
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [AnyHashable: Any]!) {
    
    picker.dismiss(animated: true, completion: nil)
    
    // convert the image to a jpeg
    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
      if let data = UIImageJPEGRepresentation(image, Project.areaPhotoQuality) {
      
        DispatchQueue.main.async {
          // call the completion on the image
          let files = [FileStruct(url: nil, type: .Image, blankWithData: data)]
          self.callback(files)
        }
      }
    }
  }
  
  
  
  static func safeFilename(_ file: String) -> String {
    
    return file.replacingOccurrences(of: "/", with: " ")
    
    
  }
  
}


