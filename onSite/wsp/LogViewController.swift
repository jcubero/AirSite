//
//  LogViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-09-22.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit
import PromiseKit
import SwiftyJSON

class LogViewController: UIViewController {
  
  var projectListMenu: ProjectListMenuTableViewController?
  
  
  @IBOutlet weak var logsTextView: UITextView!
  @IBOutlet weak var urlLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    

    logsTextView.text = LogFiles.sharedInstance.read()
    urlLabel.text = "API: \(Config.networkConfig.API)"
    
  }
  
  @IBAction func dismissPressed(_ sender: AnyObject) {
    
    
    self.dismiss(animated: true, completion: { [unowned self] in
      self.projectListMenu?.dismiss(animated: true, completion: nil)
    })
    
    
  }
  
  @IBAction func clearLogsPressed(_ sender: AnyObject) {
    
    let titleString = NSLocalizedString("Delete all logs from this device?", comment: "Delete all logs from this device?")
    let alert = UIAlertController(title: titleString, message: "", preferredStyle: UIAlertControllerStyle.alert)
    
    let removeString = NSLocalizedString("Delete", comment: "Delete")
    alert.addAction(UIAlertAction(title: removeString, style: .destructive, handler: { action in
      LogFiles.sharedInstance.clear()
      self.logsTextView.text = LogFiles.sharedInstance.read()
      
    }))
    
    let cancelString = NSLocalizedString("Cancel", comment: "Cancel")
    alert.addAction(UIAlertAction(title: cancelString, style: .default, handler: { action in
      alert.dismiss(animated: true, completion: nil)
    }))
    
    self.present(alert, animated: true, completion: nil)
    
    
    
  }
  
}
