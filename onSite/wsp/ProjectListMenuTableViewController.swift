//
//  ProjectListMenuTableViewController.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-09-19.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

class ProjectListMenuTableViewController: UITableViewController, UIAlertViewDelegate {
  
  weak var delegate: ProjectListMenuDelegate?
  var sortBy: Int?
  
  var enableExperimentalAction: UIAlertAction?
  
  @IBOutlet weak var versionTableViewCell: UITableViewCell!
  @IBOutlet weak var experimentalFeaturesCell: UITableViewCell!
  @IBOutlet weak var userTableViewCell: UITableViewCell!
  
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        
    }
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let indexPath = IndexPath(row: self.sortBy!, section: 0)
    let cell = tableView.cellForRow(at: indexPath)
    cell?.accessoryType = UITableViewCellAccessoryType.checkmark
    
    versionTableViewCell.textLabel?.text = "InField \(Config.versionNumber) - Build \(Config.buildNumner)"
    
    userTableViewCell.textLabel?.text = "User: \(Manager.sharedInstance.getCurrentUser().username!)"
    
  }
  
  // Setting color in storyboard has no impact. Not sure why.
  override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    cell.backgroundColor = UIColor.clear
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    
    let cell = tableView.cellForRow(at: indexPath)
    
    if indexPath.section == 0 {
      for obj in tableView.visibleCells {
        obj.accessoryType = UITableViewCellAccessoryType.none
      }
      
      switch indexPath.row {
      case 0:
        self.dismiss(animated: true) {
          self.delegate!.sort("title", ascending: false, sortByRow: 0)
          cell?.accessoryType = UITableViewCellAccessoryType.checkmark
        }
      case 1:
        self.dismiss(animated: true) {
          self.delegate!.sort("lastModified", ascending: true, sortByRow: 1)
          cell?.accessoryType = UITableViewCellAccessoryType.checkmark
        }
      case 2:
        self.dismiss(animated: true) {
          self.delegate!.sort("createdDate", ascending: true, sortByRow: 2)
          cell?.accessoryType = UITableViewCellAccessoryType.checkmark
        }
      default:
        Config.error()
      }
      
    } else {
      switch indexPath.row {
      case 0:
        break;
        // Experimental Features Dialog
        // self.showExperimentalFeatures()
        

        
      case 1:
        if Manager.sharedInstance.features.showLogs {
          self.performSegue(withIdentifier: "ShowLogs", sender: nil)
        } else {
          tableView.deselectRow(at: indexPath, animated: true)
        }
        return
        
      default:
        Config.error()
      }
    }
    
    tableView.deselectRow(at: indexPath, animated: true)
    self.dismiss(animated: true, completion: nil)
  }
  
  @objc func checkForValidPassword(_ textField: UITextField) {
   
    let pass = textField.text!
    enableExperimentalAction?.isEnabled = pass == Config.experimentalFeaturesCode
    
  }

  func showExperimentalFeatures() {

    if !Manager.sharedInstance.features.experimentalEnabled {
      let title = NSLocalizedString("Experimental Features", comment: "")
      let message = NSLocalizedString("Please enter the code to enable experimental features", comment: "")
      let cancelString = NSLocalizedString("Cancel", comment: "Cancel")
      let alertTitleString = NSLocalizedString("Engage", comment: "")
      
      
      let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
      
      alert.addTextField() { textField in
        textField.placeholder = NSLocalizedString("Enter your code", comment: "")
        textField.isSecureTextEntry = true
        textField.addTarget(self, action: #selector(ProjectListMenuTableViewController.checkForValidPassword(_:)), for: UIControlEvents.editingChanged)
      }
      
      alert.addAction(UIAlertAction(title: cancelString, style: .cancel, handler: { action in
      }))
      
      enableExperimentalAction = UIAlertAction(title: alertTitleString, style: .default, handler: { action in
        Manager.sharedInstance.features.experimentalEnabled = true
        self.dismiss(animated: true, completion: nil)
      })
      enableExperimentalAction!.isEnabled = false
      alert.addAction(enableExperimentalAction!)
      
      self.present(alert, animated: true, completion: nil)
      return
      
      
    } else {
      Manager.sharedInstance.features.experimentalEnabled = false
    }

  }
  
  
  
  func setCheckmark(_ row: Int) {
    self.sortBy = row
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)
    
    if let vc = segue.destination as? LogViewController {
      vc.projectListMenu = self
      
      
    }
    
  }
  
}
