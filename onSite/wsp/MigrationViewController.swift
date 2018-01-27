//
//  MigrationViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-12-23.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import UIKit

class MigrationViewController: UIViewController {
  
  @IBOutlet weak var progressView: UIProgressView!
  @IBOutlet weak var pleaseWaitView: UIView!
  @IBOutlet weak var progressInfo: UILabel!
  
  var migrator: DatabaseMigrator!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.progressView.setProgress(0, animated: false)
    self.migrator = Manager.sharedInstance.database.migrator
    self.migrator.delegate = self
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
    
    super.viewDidAppear(animated)
    
    Manager.sharedInstance.sendScreenView("Report")
    
    Manager.sharedInstance.migrateDatabase(self) {
      
      let storyboard = UIStoryboard(name: "Main", bundle: nil)
      let initialViewController = storyboard.instantiateViewController(withIdentifier: "Projects") as! ProjectNavigationController
      self.present(initialViewController, animated: true, completion: nil)
      
    }
    
    
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    
    super.viewWillDisappear(animated)
    self.migrator.delegate = nil
    
  }
  
}


extension MigrationViewController: DatabaseMigratorDelegate {
  
  func progress(_ progress: Float, info: String) {
  
    self.progressView.setProgress(progress, animated: true)
    self.progressInfo.text = info
    
    
  }
}
