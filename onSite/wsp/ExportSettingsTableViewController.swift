//
//  ExportSettingsTableViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-08-03.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

class ExportSettingsTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {

  @IBOutlet weak var orientationCell: UITableViewCell!
  @IBOutlet weak var pageSizeCell: UITableViewCell!
  @IBOutlet weak var photosPerPage: UITableViewCell!
  @IBOutlet weak var photoPageOrientation: UITableViewCell!
 
  @IBOutlet weak var coverPageCell: UITableViewCell!
  @IBOutlet weak var plansCell: UITableViewCell!
  @IBOutlet weak var commentsCell: UITableViewCell!
  @IBOutlet weak var imagesCell: UITableViewCell!
  @IBOutlet weak var detailCell: UITableViewCell!
  
  var exportSettings: ExportSettings = Manager.sharedInstance.exportSettings
  var allowDismissal: Bool = true
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.popoverPresentationController?.delegate = self
    self.exportSettings.hasChanges = false
   
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.updateCellsBasedOnExportSettings()
  }
  
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier == "Orientation" {
      let vc = segue.destination as! OrientationSettingsTableViewController
      vc.orientationType = .area
      
    } else if segue.identifier == "PhotoOrientation" {
      let vc = segue.destination as! OrientationSettingsTableViewController
      vc.orientationType = .photos
    }
  }
  
  
  func updateCellsBasedOnExportSettings() {
   
    if self.exportSettings.orientation == .portrait {
      self.orientationCell.detailTextLabel!.text = "Portrait"
    } else {
      self.orientationCell.detailTextLabel!.text = "Landscape"
    }
    
    if self.exportSettings.size == .eight {
      self.pageSizeCell.detailTextLabel!.text = "8½ x 11"
    } else {
      self.pageSizeCell.detailTextLabel!.text = "11 x 17"
    }
    
    
    self.photosPerPage.detailTextLabel!.text = String(self.exportSettings.photoPageCount)
    
    if self.exportSettings.photoPageOrientation == .portrait {
      self.photoPageOrientation.detailTextLabel!.text = "Portrait"
    } else {
      self.photoPageOrientation.detailTextLabel!.text = "Landscape"
    }
    
    if self.exportSettings.cover {
      self.coverPageCell.accessoryType = .checkmark
    } else {
      self.coverPageCell.accessoryType = .none
    }
    
    if self.exportSettings.plans {
      self.plansCell.accessoryType = .checkmark
    } else {
      self.plansCell.accessoryType = .none
    }
    
    if self.exportSettings.comments {
      self.commentsCell.accessoryType = .checkmark
    } else {
      self.commentsCell.accessoryType = .none
    }
    
    if self.exportSettings.images {
      self.imagesCell.accessoryType = .checkmark
    } else {
      self.imagesCell.accessoryType = .none
    }
    
    if self.exportSettings.imageDetails {
      self.detailCell.accessoryType = .checkmark
    } else {
      self.detailCell.accessoryType = .none
    }
    
  }

  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    if indexPath.section == 1 && indexPath.row == 0 {
      self.exportSettings.cover =  !self.exportSettings.cover
    }
    
    if indexPath.section == 1 && indexPath.row == 1 {
      self.exportSettings.plans =  !self.exportSettings.plans
    }
    
    if indexPath.section == 1 && indexPath.row == 2 {
      self.exportSettings.comments =  !self.exportSettings.comments
    }
    
    if indexPath.section == 1 && indexPath.row == 3 {
      self.exportSettings.images =  !self.exportSettings.images
    }
    
    if indexPath.section == 1 && indexPath.row == 4 {
      self.exportSettings.imageDetails =  !self.exportSettings.imageDetails
    }
    
    if indexPath.section == 2 && indexPath.row == 0 {
      
      self.exportSettings.delegate?.getPDF({ (url) -> () in
        let fileManager = FileManager_(vc: self, forFileTypes: [.PDF]) //Todo: Compare with Swift 2 code
        fileManager.shareFile(url, cb: { _ -> () in
        })
      })
    }
    
    self.updateCellsBasedOnExportSettings()
    tableView.deselectRow(at: indexPath, animated: true)
  
  }
  
  func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
    return self.allowDismissal
  }
  
  
  func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
    
    if exportSettings.hasChanges {
      self.exportSettings.delegate?.didChangeSettings(self.exportSettings)
    }
    
  }
  
}
