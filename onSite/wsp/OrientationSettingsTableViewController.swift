//
//  OrientationSettingsTableViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-08-03.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

enum OrientationSettingsType {
  case area, photos
}

class OrientationSettingsTableViewController: UITableViewController {
  
  var exportSettings: ExportSettings = Manager.sharedInstance.exportSettings
  
  var orientationType: OrientationSettingsType = .area
  
  @IBOutlet weak var portraitCell: UITableViewCell!
  @IBOutlet weak var landscapeCell: UITableViewCell!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.updateCellsBasedOnExportSettings()
    
  }
  
  func updateCellsBasedOnExportSettings() {
    
    var orientationVariable = self.exportSettings.orientation
    
    if self.orientationType == .photos {
      orientationVariable = self.exportSettings.photoPageOrientation
    }
   
    if orientationVariable == .portrait {
      self.portraitCell.accessoryType = .checkmark
      self.landscapeCell.accessoryType = .none
    } else if orientationVariable == .landscape {
      self.portraitCell.accessoryType = .none
      self.landscapeCell.accessoryType = .checkmark
    }
    
  }

  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
  
    if indexPath.row == 0 {
      if self.orientationType == .area {
        self.exportSettings.orientation = .portrait
      } else {
        self.exportSettings.photoPageOrientation = .portrait
      }
    } else if indexPath.row == 1 {
      if self.orientationType == .area {
        self.exportSettings.orientation = .landscape
      } else {
        self.exportSettings.photoPageOrientation = .landscape
      }
    }
    
    
    self.updateCellsBasedOnExportSettings()
    tableView.deselectRow(at: indexPath, animated: true)
    self.navigationController?.popViewController(animated: true)
  
  }
  
  
  
  
}
