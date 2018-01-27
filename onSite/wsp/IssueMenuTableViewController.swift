//
//  IssueMenuTableViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-04-12.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit


protocol IssueMenuViewControllerDelegate: class {
  func deletedIssue(_ issue: Issue, renumbering: Bool)
  func relabeledIssue(_ issue: Issue?)
}

class IssueMenuTableViewController: UITableViewController {
  
  weak var delegate: IssueMenuViewControllerDelegate?
  weak var issueView: IssueView!
  
  @IBOutlet weak var deleteCell: UITableViewCell!
  @IBOutlet weak var moveArrowLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    self.tableView.backgroundColor = UIColor.clear
    self.view.backgroundColor = UIColor.clear
    
    
    if let popover = self.navigationController?.popoverPresentationController {
      popover.backgroundColor = UIColor.clear
    }
    
    if !self.issueView.issue.hasArrow {
      self.deleteCell.isHidden = true
      self.preferredContentSize = CGSize(width: 300, height: 216)
      self.moveArrowLabel.text = NSLocalizedString("Add Arrow", comment: "Add arrow issue menu item")
    }
    
  }
  
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = super.tableView(tableView, cellForRowAt: indexPath)
    
    cell.backgroundColor = UIColor.clear
    
    return cell
  }
  
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
  
    switch indexPath.row {
      
    case 0:
      self.copyPressed()
      
    case 1:
      self.movePressed()
      
    case 2:
      self.deletePressed()
      
    case 3:
      self.renumberPressed()
      
    case 4:
      self.arrowPressed()
      
    default:
      self.deleteArrowPressed()
    }
    
  }
  
 func movePressed() {
  
    self.issueView.areaView.startMove(self.issueView)
    self.dismiss(animated: true, completion: nil)
    
  }
  
  func arrowPressed() {
    self.issueView.areaView.startArrow(self.issueView)
    self.dismiss(animated: true, completion: nil)
    
  }
  
  func deletePressed() {
    
    
    let issue = self.issueView.issue
    
    if self.issueView.issue.isLastestIssue() {
      
      let titleString = NSLocalizedString("Are you sure?", comment: "Are you sure?")
      let alert = UIAlertController(title: titleString, message: "", preferredStyle: UIAlertControllerStyle.alert)
      
      let removeString = NSLocalizedString("Yes", comment: "Yes")
      alert.addAction(UIAlertAction(title: removeString, style: .default, handler: { action in
        
        issue?.remove(andRenumber: false) {
          self.delegate?.deletedIssue(self.issueView.issue, renumbering: false)
          self.dismiss(animated: true, completion: nil)
          
        }
      }))
      
      let cancelString = NSLocalizedString("No", comment: "No")
      alert.addAction(UIAlertAction(title: cancelString, style: .default, handler: { action in
      }))
      
      
      self.present(alert, animated: true, completion: nil)
      
    } else {
      let titleString = NSLocalizedString("Renumber existing issues?", comment: "Renumber existing issues?")
      let alert = UIAlertController(title: titleString, message: "", preferredStyle: UIAlertControllerStyle.alert)
      
      let removeString = NSLocalizedString("Yes", comment: "Yes")
      alert.addAction(UIAlertAction(title: removeString, style: .default, handler: { action in
        
        
        issue?.remove(andRenumber: true) {
          self.delegate?.deletedIssue(self.issueView.issue, renumbering: true)
          self.dismiss(animated: true, completion: nil)
        }
        
      }))
      
      let cancelString = NSLocalizedString("No", comment: "No")
      alert.addAction(UIAlertAction(title: cancelString, style: .default, handler: { action in
        
        issue?.remove(andRenumber: false) {
          self.delegate?.deletedIssue(self.issueView.issue, renumbering: false)
          self.dismiss(animated: true, completion: nil)
        }
      }))
      
      alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel) { action -> Void in
        self.dismiss(animated: true, completion: nil)
      
      })
      
      self.present(alert, animated: true, completion: nil)
      
    }
    
  }
  
  func renumberPressed() {
    
    let newIssueText = NSLocalizedString("New Issue Number", comment: "New Issue Number")
    let alert: UIAlertController = UIAlertController(title: newIssueText, message: "", preferredStyle: .alert)
    var inputTextField: UITextField!
    
      alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel) { action -> Void in
        self.dismiss(animated: true, completion: nil)
      
      })
    
    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default) { action -> Void in
      if let number = Int(inputTextField.text!) {
        self.issueView.issue.renumberIssue(number)
        self.delegate?.relabeledIssue(nil)
        self.dismiss(animated: true, completion: nil)
      }
      })
    
    alert.addTextField { textField -> Void in
      inputTextField = textField
      textField.keyboardType = .numberPad
      inputTextField.addTarget(self, action: #selector(IssueMenuTableViewController.textChanged(_:)), for: .editingChanged)
    }
    
    (alert.actions[1] as UIAlertAction).isEnabled = false
    
    self.present(alert, animated: true, completion: nil)
    
    
  }
  
  @objc func textChanged(_ sender:AnyObject) {
    let tf = sender as! UITextField
    var resp : UIResponder = tf
    while !(resp is UIAlertController) { resp = resp.next! }
    let alert = resp as! UIAlertController
    (alert.actions[1] as UIAlertAction).isEnabled = (Int(tf.text!) != nil)
  }
  
   func deleteArrowPressed() {
    
    self.issueView.issue.removeArrow()
    self.issueView.issue.setModified()
    
    Manager.sharedInstance.saveCurrentState( {
      self.issueView.areaView.redrawArrows()
      self.dismiss(animated: true, completion: nil)
    })
    
  }
  
  func copyPressed() {
    
    self.issueView.areaView.project.addCopiedIssue(self.issueView.issue)
    self.dismiss(animated: true, completion: nil)
    
  }
  
  
  
}
