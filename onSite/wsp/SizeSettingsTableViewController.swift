//
//  SizeSettingsTableViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-08-03.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

class SizeSettingsTableViewController: UITableViewController {

  var exportSettings: ExportSettings = Manager.sharedInstance.exportSettings
  
  @IBOutlet weak var eightCell: UITableViewCell!
  @IBOutlet weak var elevenCell: UITableViewCell!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.updateCellsBasedOnExportSettings()
    
  }

  
  func updateCellsBasedOnExportSettings() {
   
    if self.exportSettings.size == .eight {
      self.eightCell.accessoryType = .checkmark
      self.elevenCell.accessoryType = .none
    } else if self.exportSettings.size == .eleven {
      self.eightCell.accessoryType = .none
      self.elevenCell.accessoryType = .checkmark
    }
    
  }

  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
  
    if indexPath.row == 0 {
      self.exportSettings.size = .eight
    } else if indexPath.row == 1 {
      self.exportSettings.size = .eleven
    }
    
    self.updateCellsBasedOnExportSettings()
    tableView.deselectRow(at: indexPath, animated: true)
    self.navigationController?.popViewController(animated: true)
  
  }
  
  
  

}
