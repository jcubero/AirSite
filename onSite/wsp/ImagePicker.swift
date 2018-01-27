//
//  ImagePicker.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-03-08.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

class ImagePicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  weak var refferingViewController : UIViewController!
  var completionCallback: ((Data) -> ())?
  var multipleCompletionCallback: (([FileStruct]) -> ())?
  var allowZip: Bool = false
  var fileManager: FileManager_?
  
  var location: CGRect!
  var showRemove: Bool = true
  
  
  func loadImagePickerInViewController(_ vc: UIViewController, location: CGRect,  completion: @escaping (Data) -> ()) {
    
    self.refferingViewController = vc
    self.completionCallback = { completion($0) }
    self.location = location
    
    let storyboard = UIStoryboard(name: "ImagePicker", bundle: nil)
    let importMenu = storyboard.instantiateInitialViewController() as! UINavigationController
    
    let imagePicker = importMenu.viewControllers.first! as! ImagePickerTableViewController
    
    imagePicker.callingVc = self
    
    let popup = UIPopoverController(contentViewController: importMenu)
    popup.present(from: location, in: vc.view, permittedArrowDirections: .any, animated: true)
    
  }
  
    func loadMultipleImagePickerInViewController(vc: UIViewController, location: CGRect, completion: @escaping ([FileStruct]) -> ()) {
        
        self.refferingViewController = vc
        self.multipleCompletionCallback = { completion($0) }
        self.location = location
        
        let storyboard = UIStoryboard(name: "ImagePicker", bundle: nil)
        let importMenu = storyboard.instantiateInitialViewController() as! UINavigationController
        
        let imagePicker = importMenu.viewControllers.first! as! ImagePickerTableViewController
        
        imagePicker.callingVc = self
        let message = NSLocalizedString("From image or zip file...", comment: "Import image from a file or an archive")
        imagePicker.filesString = message
        
        let popup = UIPopoverController(contentViewController: importMenu)
        popup.present(from: location, in: vc.view, permittedArrowDirections: .any, animated: true)
        
    }
  
  
  func cameraHandler() {
    
    let vc = self.refferingViewController
    let location = self.location
    let picker: UIImagePickerController = UIImagePickerController()
    picker.delegate = self
    
    // check if camera is available, and if not, open the gallery view so as not to crash
    
    if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
      picker.sourceType = UIImagePickerControllerSourceType.camera
      //        picker.modalPresentationStyle = .FormSheet
      
      picker.allowsEditing = false
      picker.showsCameraControls = true
      
      let popover = UIPopoverController(contentViewController: picker)
      popover.present(from: location!, in: (vc?.view)!, permittedArrowDirections: .any, animated: true)
      
      //          vc.presentViewController(picker, animated: true, completion: nil)
      
    } else {
      picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
      let popover = UIPopoverController(contentViewController: picker)
      popover.present(from: location!, in: (vc?.view)!, permittedArrowDirections: .any, animated: true)
    }
    
  }
  
  func libraryHandler() {
    let vc = self.refferingViewController
    let location = self.location
    let picker: UIImagePickerController = UIImagePickerController()
    
    picker.delegate = self
    picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
    let popover = UIPopoverController(contentViewController: picker)
    popover.present(from: location!, in: (vc?.view)!, permittedArrowDirections: .any, animated: true)
    
  }
  
  func clearHandler() {
    if let comp = self.completionCallback {
      comp(Data())
    }
  }
  
  func fileHandler() {
    
    var fileTypes: [FileTypes] = [.Image, .PDF]
    
    if self.multipleCompletionCallback != nil {
      fileTypes.append(.Zip)
    }
    
    self.fileManager = FileManager_(vc: self.refferingViewController, forFileTypes: fileTypes)
    
    self.fileManager!.loadFilePicker() { [unowned self] files in
      if let comp = self.completionCallback {
        if files.count  == 1 {
          let file = files[0]
          comp(file.data as Data)
        }
        
      } else if let comp = self.multipleCompletionCallback {
        comp(files)
        
      }
    }
  }
  
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [AnyHashable: Any]!) {
    
    picker.dismiss(animated: true, completion: nil)
    
    // convert the image to a jpeg
    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
      let data = UIImageJPEGRepresentation(image, Project.areaPhotoQuality)
      
      DispatchQueue.main.async {
        // call the completion on the image
        if let comp = self.completionCallback {
          comp(data!)
          
        } else if let comp = self.multipleCompletionCallback {
          let file = FileStruct(url: nil, type: .Image, blankWithData: data!)
          comp([file])
        }
      }
    }
  }
}
