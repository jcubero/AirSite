//
//  EditAreaModal.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-06-29.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit


class EditAreaModal : UIViewController, UITextFieldDelegate {
  
  @IBOutlet weak var areaTitle: UITextField!
  @IBOutlet weak var imageEditor: EditAreaImageView!
 
  @IBOutlet weak var aspectButton: UIButton!
  
  @IBOutlet weak var doneButton: UIButton!
  
  var area : Area? = nil
  var newArea:Bool = false

  override func viewDidLoad() {
    super.viewDidLoad()
   
    self.areaTitle.delegate = self
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
  
    super.viewWillAppear(animated)
 
    if let a = self.area {
      if let image = a.image {
        self.imageEditor.image = image
      }
      self.areaTitle.text = a.title
    }
    self.updateButtonOnAspectChange()
    
    self.titleChange(self.areaTitle)
  
  }
  
  func updateButtonOnAspectChange() {
    
    if self.imageEditor.cropAspectRatio > 1 {
      self.aspectButton.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))
      
    } else {
      self.aspectButton.transform = CGAffineTransform(rotationAngle: CGFloat(0))
    }
    
  }
  
  @IBAction func onRemoveArea(_ sender: AnyObject) {
    
    if self.newArea {
      self.area?.removeWithFiles()
      Manager.sharedInstance.saveCurrentState(nil)
    }
   
    self.dismiss(animated: true, completion: {
    })
    
  }

  @IBAction func onRotateLeft() {
   
    self.imageEditor.rotation = CGFloat(Double.pi/2)
    
  }
  
  @IBAction func onRotateRight() {
    
    self.imageEditor.rotation = CGFloat(Double.pi/2)
    
  }
  
  @IBAction func onDone(_ sender: AnyObject) {
    
    let issueCount = self.area!.issues!.count
    if issueCount > 0 && self.imageEditor.imageHasChanged {
      
      let replMessage = NSLocalizedString("Modifying this area will invalidate the positions of %s observations.", comment: "Modifying this area will invalidate the positions of %s observations.")
      let message = replMessage.replacingOccurrences(of: "%s", with: "\(issueCount)")
      
      let alert = UIAlertController(title: NSLocalizedString("Modify Area", comment: "Modify Area"), message: message, preferredStyle: UIAlertControllerStyle.alert)
      
      alert.addAction(UIAlertAction(title: NSLocalizedString("Continue", comment: "Continue"), style: .cancel, handler: { action in
        self.saveAllAndDismiss()
      }))
      
      let cancelString = NSLocalizedString("Cancel", comment: "Cancel")
      alert.addAction(UIAlertAction(title: cancelString, style: .default, handler: { action in
        self.dismiss(animated: true, completion: nil)
      }))
      
      self.present(alert, animated: true, completion: nil)
    } else {
      self.saveAllAndDismiss()
    }
    
    
  }
  
  func saveAllAndDismiss() {
    
    self.area?.title = self.areaTitle.text!
    
    self.area?.image = self.imageEditor.image
    
    self.area?.setModified()
    self.dismiss(animated: true, completion: {
      Manager.sharedInstance.saveCurrentState(nil)
    })
    
  }
  
  
  @IBAction func changeAspect(_ sender: AnyObject) {
    
    self.imageEditor.cropAspectRatio = 1.0 / self.imageEditor.cropAspectRatio
    self.updateButtonOnAspectChange()
    
    
  }
  
  
  @IBAction func titleChange(_ sender: AnyObject) {
    if let value = self.areaTitle.text {
      if value.characters.count > 0 {
        self.doneButton.isHidden = false
      } else {
        self.doneButton.isHidden = true
      }
      
    }
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    self.view.endEditing(true)
    return false
    
  }
  
}

