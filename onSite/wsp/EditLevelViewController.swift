//
//  EditLevelViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-01-20.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit

class EditLevelViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
 
  var level: Level?
  var project: Project!
  
  var levelIsShapeLevel: Bool = false
  var levelIsColorLevel: Bool = false
  var levelNumber: Int = 0
  
  var previousLevels: [Level] = []
  var basedOnLevel: Level?
  
  weak var parentVC: EditLibraryViewController!
  
  @IBOutlet weak var doneButton: UIBarButtonItem!
  @IBOutlet weak var levelTitleTextField: UITextField!
  
  @IBOutlet weak var variableTypeDescription: UILabel!
  @IBOutlet weak var infoIconLabel: UILabel!
  
  @IBOutlet weak var typeSegmentedControl: UISegmentedControl!
  @IBOutlet weak var typeDescription: UILabel!
  
  @IBOutlet weak var shapeSwitch: UISwitch!
  @IBOutlet weak var colorSwitch: UISwitch!
  
  @IBOutlet weak var tagTypeConstraint: NSLayoutConstraint!
  
  @IBOutlet weak var shapesDescription: UILabel!
  @IBOutlet weak var colorsDescription: UILabel!
  
  @IBOutlet weak var typePicker: UIPickerView!
 
  @IBOutlet weak var deleteButton: UIButton!
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.levelIsShapeLevel = false
    self.shapeSwitch.isOn = false
    self.levelIsColorLevel = false
    self.colorSwitch.isOn = false
    
    if let level = self.level {
      self.navigationItem.title = NSLocalizedString("Edit Level", comment: "Edit Level")
      self.levelTitleTextField.text = level.title
      
      self.typeSegmentedControl.isHidden = true
      
      if level.isTreeLevel.boolValue {
        self.typeDescription.text = "This is a relative level based on \(level.parent!.nonEmptyTitle)"
      } else {
        self.typeDescription.text = NSLocalizedString("This is a regular level", comment: "This is a regular level")
      }
      
      self.doneButton.title = NSLocalizedString("Done", comment: "Done")
      
      if level.hasShapes {
        self.levelIsShapeLevel = true
        self.shapeSwitch.isOn = true
        
      }
      if level.hasColors {
        self.levelIsColorLevel = true
        self.colorSwitch.isOn = true
      }
      
    } else {
      
      self.navigationItem.title = NSLocalizedString("New Level", comment: "New Level")
      self.typeSegmentedControl.selectedSegmentIndex = 0
      self.typeDescription.isHidden = true
     
      self.doneButton.title = NSLocalizedString("Add", comment: "Add")
      self.deleteButton.isHidden = true
      
    }
    
    self.updateVisibility()
    self.createPickerOptions()
    
    self.renderShapes()
    self.renderColors()
    self.levelTitleChange(self.levelTitleTextField)
    
    self.levelTitleTextField.delegate = self
    
  }
  
  
  func renderShapes() {
    
    if self.levelIsShapeLevel {
      self.shapesDescription.text = NSLocalizedString("Flip the switch to turn off shapes for this level.", comment: "Flip the switch to turn off shapes for this level.")
    } else {
      self.shapesDescription.text = NSLocalizedString("Flip the switch to turn on shapes for this level.", comment: "Flip the switch to turn on shapes for this level.")
    }
  }
  
  
  func renderColors() {
    
    if self.levelIsShapeLevel {
      self.colorsDescription.text = NSLocalizedString("Flip the switch to turn off colors for this level.", comment: "Flip the switch to turn off colors for this level.")
    } else {
      self.colorsDescription.text = NSLocalizedString("Flip the switch to turn on colors for this level.", comment: "Flip the switch to turn on colors for this level.")
    }
  }
  
  func createPickerOptions() {
    
    let predicate = NSPredicate(format: "project = %@", self.project)
   
    self.previousLevels = Level.mr_findAllSorted(by: "level", ascending: false, with: predicate) as! [Level]
    
    self.typePicker.dataSource = self
    self.typePicker.delegate = self
    self.typePicker.reloadAllComponents()
    
    if self.previousLevels.count > 0 {
      self.typePicker.selectedRow(inComponent: 0)
      self.basedOnLevel = self.previousLevels[0]
    }
    
  }
  
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return self.previousLevels.count
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return self.previousLevels[row].nonEmptyTitle
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    self.basedOnLevel = self.previousLevels[row]
  }
  
 
  @IBAction func updateVisibility() {
    
    if self.typeSegmentedControl.selectedSegmentIndex == 0 {
      self.tagTypeConstraint.constant = 24
      self.infoIconLabel.isHidden = true
      self.variableTypeDescription.isHidden = true
      self.typePicker.isHidden = true
    } else if self.typeSegmentedControl.selectedSegmentIndex == 1 {
      self.tagTypeConstraint.constant = 200
      self.infoIconLabel.isHidden = false
      self.variableTypeDescription.isHidden = false
      self.typePicker.isHidden = false
      
    }
    
  }
  
  
  @IBAction func cancel(_ sender: AnyObject) {
    
    self.dismiss(animated: true, completion: nil)
    
  }
  
  
  func createNewLevel() -> Level {
    let level = Level.createLevelForProject(self.project, level: self.levelNumber)
    
    if self.typeSegmentedControl.selectedSegmentIndex == 1 {
      level.isTreeLevel = true
      guard let parent = self.basedOnLevel else {
        Config.error("No Parent Found!")
        level.isTreeLevel = false
        return level
      }
      level.parent = parent
    } else {
      level.isTreeLevel = false
    }
    
    return level
    
  }
  
  @IBAction func save(_ sender: AnyObject) {
    
    
    var level: Level! = self.level
    var createdNewLevel: Bool = false
    
    if self.level == nil {
      level = self.createNewLevel()
      createdNewLevel = true
    }
    
    level.title = self.levelTitleTextField.text
    
    if self.levelIsColorLevel != level.isColorLevel.boolValue {
      if self.levelIsColorLevel {
        level.makeThisAColorLevel()
      } else {
        level.isColorLevel = false
      }
    }
    
    if self.levelIsShapeLevel != level.isShapeLevel.boolValue {
      if self.levelIsShapeLevel {
        level.makeThisAShapeLevel()
      } else {
        level.isShapeLevel = false
      }
    }
    
    Manager.sharedInstance.saveCurrentState() {
      Manager.sharedInstance.caches.invalidateLevelActions(forLevel: level)

      self.dismiss(animated: true, completion: {
        self.parentVC.finishEditingLevel(andGoToNextLevel: createdNewLevel)
      })
    }
    
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
      
      if let level = self.project.colorLevel, level != self.level {
        
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

  @IBAction func levelTitleChange(_ sender: AnyObject) {
    if let value = self.levelTitleTextField.text {
      if value.characters.count > 0 {
        self.doneButton.isEnabled = true
      } else {
        self.doneButton.isEnabled = false
      }
      
    }
  }
  
  @IBAction func deleteLevel(_ sender: AnyObject) {
    
    guard let level = self.level else {
      Config.error("How?")
      return
    }
    
    let message = level.getRemovalConcequences()
    
    let alert = UIAlertController(title: "Delete Level", message: message, preferredStyle: UIAlertControllerStyle.alert)
    
    alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .cancel, handler: { action in
      
      level.delete()
      
      Manager.sharedInstance.saveCurrentState({ () -> () in
        self.dismiss(animated: true, completion: {
          self.parentVC.levelHasBeenRemoved()
        })
      })
    }))
    
    let cancelString = NSLocalizedString("Cancel", comment: "Cancel")
    alert.addAction(UIAlertAction(title: cancelString, style: .default, handler: { action in
    }))
    
    self.present(alert, animated: true, completion: nil)
    
    
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    self.view.endEditing(true)
    return false
  }
  
}


