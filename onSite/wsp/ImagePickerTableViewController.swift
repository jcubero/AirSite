//
//  ImagePickerTableViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-03-08.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit

class ImagePickerTableViewController: UITableViewController {

  var callingVc: ImagePicker!
  
  var filesString: String = NSLocalizedString("Import", comment: "Import image from a file.")
  
  @IBOutlet weak var fromFileLabel: UILabel!
  @IBOutlet weak var removeTableViewCell: UITableViewCell!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.fromFileLabel.text = self.filesString
    
    if !callingVc.showRemove {
      removeTableViewCell.isHidden = true
      self.preferredContentSize = CGSize(width: 300, height: 145)
    } else {
      self.preferredContentSize = CGSize(width: 300, height: 185)
    }
    
    self.presentingViewController!.presentedViewController!.preferredContentSize = self.preferredContentSize
    self.tableView.isScrollEnabled = false
    
    self.tableView.tableFooterView = UIView()
    
    
  }
  
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    let row = indexPath.row
    
    if row == 0 {
      
      self.navigationController?.dismiss(animated: true) { () in
        self.callingVc.cameraHandler()
      }
      
      
    } else if row == 1 {
      
      self.navigationController?.dismiss(animated: true) { () in
        self.callingVc.libraryHandler()
      }
      
      
    } else if row == 3 {
      
      self.navigationController?.dismiss(animated: true) { () in
        self.callingVc.clearHandler()
      }
      
    } else {
      
      self.navigationController?.dismiss(animated: true) { () in
        self.callingVc.fileHandler()
      }
      
    }
    
    
  }
  
}
