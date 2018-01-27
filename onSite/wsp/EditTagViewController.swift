//
//  EditTagViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-01-05.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit

class EditTagViewController: UIViewController, UITextFieldDelegate {
 
  var levelItem: Tag?
  var level: Level!
  var parentItem: Tag?
  var project: Project!
  
  var selectedShape: Int = 0
  var selectedColor: Int = 0
  
  var levelIsShapeLevel: Bool = false
  var levelIsColorLevel: Bool = false
  
  @IBOutlet weak var doneButton: UIBarButtonItem!
  
  @IBOutlet weak var tagTitleTextField: UITextField!
  
  @IBOutlet weak var inputTypeDescription: UILabel!
  @IBOutlet weak var numericTypeDescription: UILabel!
  @IBOutlet weak var infoTypeDescription: UILabel!
  
  @IBOutlet weak var typeSegmentedControl: UISegmentedControl!
  
  @IBOutlet weak var shapeSwitch: UISwitch!
  @IBOutlet weak var colorSwitch: UISwitch!
  
  @IBOutlet weak var tagTypeConstraint: NSLayoutConstraint!
  
  @IBOutlet var shapeCollection: [UIImageView]!
  @IBOutlet var colorCollection: [UIImageView]!
  
  
  @IBOutlet weak var shapesContainer: UIView!
  @IBOutlet weak var colorsContainer: UIView!
  
  @IBOutlet weak var shapesDescription: UILabel!
  @IBOutlet weak var colorsDescription: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    for shape in self.shapeCollection {
      let tap = UITapGestureRecognizer(target: self, action: #selector(EditTagViewController.shapeChanged(_:)))
      shape.isUserInteractionEnabled = true
      shape.addGestureRecognizer(tap)
    }
    
    for color in self.colorCollection {
      let tap = UITapGestureRecognizer(target: self, action: #selector(EditTagViewController.colorChanged(_:)))
      color.isUserInteractionEnabled = true
      color.addGestureRecognizer(tap)
    }
    
    self.tagTitleTextField.delegate = self
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if let item = self.levelItem {
      self.navigationItem.title = NSLocalizedString("Edit Tag", comment: "Edit Tag")
      self.tagTitleTextField.text = item.title
     
      if item.type == .NumericInput {
        self.typeSegmentedControl.selectedSegmentIndex = 2
      } else if item.type == .Input {
        self.typeSegmentedControl.selectedSegmentIndex = 1
      } else {
        self.typeSegmentedControl.selectedSegmentIndex = 0
      }
      self.doneButton.title = NSLocalizedString("Done", comment: "Done")
      
      
    } else {
      
      self.navigationItem.title = NSLocalizedString("New Tag", comment: "New Tag")
      self.typeSegmentedControl.selectedSegmentIndex = 0
     
      self.doneButton.title = NSLocalizedString("Add", comment: "Add")
      
    }
    
    self.updateVisibility()
    
    if self.level.hasShapes {
      self.levelIsShapeLevel = true
      self.shapeSwitch.isOn = true
     
      if let item = self.levelItem, let number = item.shape {
        self.selectedShape = number.intValue
      }
      
    } else {
      self.levelIsShapeLevel = false
      self.shapeSwitch.isOn = false
    }
    
    if self.level.hasColors {
      self.levelIsColorLevel = true
      self.colorSwitch.isOn = true
      if let item = self.levelItem, let number = item.color {
        self.selectedColor = Int(number.int32Value.advanced(by: -1))
      }
    } else {
      self.levelIsColorLevel = false
      self.colorSwitch.isOn = false
    }
    
    self.renderShapes()
    self.renderColors()
    self.tagTitleChange(self.tagTitleTextField)
    
  }
  
  
  @objc func shapeChanged(_ sender: AnyObject?) {
    
    let tap = sender as! UIGestureRecognizer
    let imageView = tap.view as! UIImageView
    if let selected = self.shapeCollection.index(of: imageView) {
      self.selectedShape = selected
      self.renderShapes()
    }
    
  }
  
  @objc func colorChanged(_ sender: AnyObject?) {
    
    let tap = sender as! UIGestureRecognizer
    let imageView = tap.view as! UIImageView
    if let selected = self.colorCollection.index(of: imageView) {
      self.selectedColor = selected
      self.renderColors()
    }
    
  }
  
  func renderShapes() {
    
    if self.levelIsShapeLevel {
      self.shapesContainer.isHidden = false
      self.shapesDescription.isHidden = true
      
      for (index, view) in self.shapeCollection.enumerated() {
        if self.selectedShape == index {
          let image = self.makeImage(Tag.imageForValue(index), color: UIColor.systemBlue(), stroke: true)
          view.image = image
        } else {
          let image = self.makeImage(Tag.imageForValue(index), color: UIColor.gray, stroke: false)
          view.image = image
        }
        
      }
    } else {
      self.shapesContainer.isHidden = true
      self.shapesDescription.isHidden = false
      
    }
  }
  
  func renderColors() {
    
    if self.levelIsColorLevel {
      self.colorsContainer.isHidden = false
      self.colorsDescription.isHidden = true
      
      for (index, view) in self.colorCollection.enumerated() {
        if self.selectedColor == index {
          let image = self.makeImage("Circle", color: Tag.colorForValue(index + 1), stroke: true)
          view.image = image
        } else {
          let image = self.makeImage("Circle", color: Tag.colorForValue(index + 1), stroke: false)
          view.image = image
        }
      }
      
    } else {
      self.colorsContainer.isHidden = true
      self.colorsDescription.isHidden = false
      
    }
    
  }
  
 
  @IBAction func updateVisibility() {
    
    
    let defaultText: [String] = ["", "{@}", "{#}"]
    if defaultText.contains(self.tagTitleTextField.text!) {
      self.tagTitleTextField.text = defaultText[self.typeSegmentedControl.selectedSegmentIndex]
      self.tagTitleChange(self.tagTitleTextField)
    }
    
    if self.typeSegmentedControl.selectedSegmentIndex == 0 {
      self.tagTypeConstraint.constant = 24
      self.inputTypeDescription.isHidden = true
      self.numericTypeDescription.isHidden = true
      self.infoTypeDescription.isHidden = true
      
    } else if self.typeSegmentedControl.selectedSegmentIndex == 1 {
      self.tagTypeConstraint.constant = 150
      self.inputTypeDescription.isHidden = false
      self.numericTypeDescription.isHidden = true
      self.infoTypeDescription.isHidden = false
      
    } else if self.typeSegmentedControl.selectedSegmentIndex == 2 {
      self.tagTypeConstraint.constant = 150
      self.inputTypeDescription.isHidden = true
      self.numericTypeDescription.isHidden = false
      self.infoTypeDescription.isHidden = false
      
    }
    
  }
  
  
  @IBAction func cancel(_ sender: AnyObject) {
    
    self.dismiss(animated: true, completion: nil)
    
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    self.view.endEditing(true)
    return false
  }
 
  func makeImage(_ imageString: String, color: UIColor, stroke: Bool) -> UIImage {
    
    let image = self.resizeImage(UIImage(named: imageString)!, newHeight: 64)
    
    let imageRect = CGRect(x: 4, y: 4, width: image.size.width - 8, height: image.size.height - 8)
    let strokeRect = CGRect(x: 2, y: 2, width: image.size.width - 4, height: image.size.height - 4)
    let superStrokeRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    
    let shapeImage = self.fillImageWithColor(image, color: color)
    var shapeStrokeImage: UIImage?
    if stroke {
      shapeStrokeImage = self.resizeImage(self.fillImageWithColor(image, color: UIColor.white), newHeight: strokeRect.size.height)
    }
    
    let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    UIGraphicsBeginImageContext(rect.size)
    
    if stroke {
      shapeImage.draw(in: superStrokeRect, blendMode: CGBlendMode.normal, alpha: 1.0)
      shapeStrokeImage?.draw(in: strokeRect, blendMode: CGBlendMode.normal, alpha: 1.0)
    }
    self.resizeImage(shapeImage, newHeight: imageRect.size.height).draw(in: imageRect)
    
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return img!
  }
  
  
  func fillImageWithColor(_ image: UIImage, color: UIColor) -> UIImage {
    
    let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()
    
    context?.clip(to: rect, mask: image.cgImage!)
    context?.setFillColor(color.cgColor)
    context?.fill(rect)
    
    
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return img!
  }
  
  func resizeImage(_ image: UIImage, newHeight: CGFloat) -> UIImage {
    
    let scale = newHeight / image.size.height
    let newWidth = image.size.width * scale
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }
  
  
  
  func createNewTag() -> Tag {
    let tag = Tag.mr_createEntity()!
    tag.setModified()
    
    if self.level == nil {
      Config.error("Level cannot be nil")
      abort()
    }
    
    tag.level = self.level
    
    if self.level.isTreeLevel.boolValue {
      if let parent = self.parentItem {
        tag.parent = parent
      }
    }
    
    self.level.setLevelAction(.skip, withParent: self.parentItem)
    
    return tag
    
  }
  
  @IBAction func save(_ sender: AnyObject) {
    
    if self.levelIsColorLevel != self.level.isColorLevel.boolValue {
      if self.levelIsColorLevel {
        self.level.makeThisAColorLevel()
      } else {
        self.level.isColorLevel = false
      }
    }
    
    if self.levelIsShapeLevel != self.level.isShapeLevel.boolValue {
      if self.levelIsShapeLevel {
        self.level.makeThisAShapeLevel()
      } else {
        self.level.isShapeLevel = false
      }
    }
    
    var tag: Tag! = self.levelItem
    
    if self.levelItem == nil {
      tag = self.createNewTag()
    }
    
    tag.title = self.tagTitleTextField.text
    if self.level.hasShapes {
      tag.shape = NSNumber(value: self.selectedShape as Int)
    }
    
    if self.level.hasColors {
      tag.color = NSNumber(value: self.selectedColor + 1 as Int)
    }
    
    
    Manager.sharedInstance.saveCurrentState(nil)
    
    self.dismiss(animated: true, completion: nil)
  }
  
  
  @IBAction func changeShapeLevel(_ sender: AnyObject) {
    
    if self.shapeSwitch.isOn {
      
      if let level = self.project.shapeLevel, level != self.level {
  
        
        let titleString = NSLocalizedString("Add Shapes To Level", comment: "Add Shapes To Level")
        let replMsg = NSLocalizedString("This will remove shapes from %s and add them to this level instead?", comment: "This will remove shapes from %s and add them to this level instead?")
        let message = replMsg.replacingOccurrences(of: "%s", with: level.nonEmptyTitle)
        let alert = UIAlertController(title: titleString, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Continue", comment: "Continue"), style: .default, handler: { action in
          self.levelIsShapeLevel = true
          self.renderShapes()
        }))
        
        let cancelString = NSLocalizedString("Cancel", comment: "Cancel")
        alert.addAction(UIAlertAction(title: cancelString, style: .default, handler: { action in
          self.shapeSwitch.setOn(false, animated: true)
          self.levelIsShapeLevel = false
          self.renderShapes()
        }))
        
        self.present(alert, animated: true, completion: nil)
        
        
      } else {
        self.levelIsShapeLevel = true
        self.renderShapes()
      }
      
    } else {
      self.levelIsShapeLevel = false
      self.renderShapes()
      
    }
    
    
  }

  
  @IBAction func changeColorLevel(_ sender: AnyObject) {
    
    if self.colorSwitch.isOn {
      
      if let level = self.project.colorLevel {
        
        let titleString = NSLocalizedString("Add Colors To Level", comment: "Add Colors To Level")
        let replMsg = NSLocalizedString("This will remove colors from %s and add them to this level instead?", comment: "This will remove colors from %s and add them to this level instead?")
        let message = replMsg.replacingOccurrences(of: "%s", with: level.nonEmptyTitle)
        let alert = UIAlertController(title: titleString, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Continue", comment: "Continue"), style: .default, handler: { action in
          self.levelIsColorLevel = true
          self.renderColors()
        }))
        
        let cancelString = NSLocalizedString("Cancel", comment: "Cancel")
        alert.addAction(UIAlertAction(title: cancelString, style: .default, handler: { action in
          self.levelIsColorLevel = false
          self.colorSwitch.setOn(false, animated: true)
          self.renderColors()
        }))
        
        self.present(alert, animated: true, completion: nil)
        
        
      } else {
        self.levelIsColorLevel = true
        self.renderColors()
      }
      
    } else {
      
      self.levelIsColorLevel = false
      self.renderColors()
      
    }
    
  }

  @IBAction func tagTitleChange(_ sender: AnyObject) {
    if let value = self.tagTitleTextField.text {
      if value.characters.count > 0 {
        self.doneButton.isEnabled = true
      } else {
        self.doneButton.isEnabled = false
      }
      
    }
  }
  
}


