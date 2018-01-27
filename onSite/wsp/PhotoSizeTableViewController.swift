//
//  PhotoSizeTableViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-11-19.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import UIKit

class PhotoSizeTableViewController: UITableViewController {
  
  var exportSettings: ExportSettings = Manager.sharedInstance.exportSettings

  
  @IBOutlet var tableCells: [UITableViewCell]!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.clearsSelectionOnViewWillAppear = false
    
    self.updateCellsBasedOnExportSettings()
  }

  func updateCellsBasedOnExportSettings() {
    
    let cellUpdate = { (nums: [Int]) -> () in
      for (index, cell) in self.tableCells.enumerated() {
        cell.textLabel?.text = String(nums[index])
        if nums[index] == self.exportSettings.photoPageCount {
          cell.accessoryType = .checkmark
        } else {
          cell.accessoryType = .none
        }
      }
    }
   
    if self.exportSettings.photoPageOrientation == .portrait {
      cellUpdate([2, 6, 9, 12])
    } else  {
      cellUpdate([1, 4, 9, 12])
    }
    
  }
  
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
  
    let cell = tableView.cellForRow(at: indexPath)!
    
    self.exportSettings.photoPageCount = Int(cell.textLabel!.text!)!
    
    self.updateCellsBasedOnExportSettings()
    tableView.deselectRow(at: indexPath, animated: true)
    self.navigationController?.popViewController(animated: true)
  
  }
  
  
  


}
