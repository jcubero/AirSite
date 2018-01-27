//
//  EditProjectTabBarController.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-09-17.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


protocol EditSettingsTabBarDelegate: class {
  func dismissProject()
  func editSettingsDidDisappear()
}

class EditProjectTabBarController: UITabBarController, UIGestureRecognizerDelegate {
  
  var project: Project?
  weak var settingsDelegate: EditSettingsTabBarDelegate?
  
  @IBOutlet weak var doneButton: UIBarButtonItem!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    let title = NSLocalizedString("Data Collecting", comment: "Data Collecting")
    addRightArrowButtonToNavigationBar(withTitle: title, target: self, selector: #selector(EditProjectTabBarController.projectButtonClicked(_:)))
    
    self.title = NSLocalizedString("Settings", comment: "Settings")
    
    automaticallyAdjustsScrollViewInsets = false
    extendedLayoutIncludesOpaqueBars = false
    edgesForExtendedLayout = UIRectEdge.bottom
    
    navigationItem.backBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Settings", comment: "Settings"), style: .plain, target: nil, action: nil)

    Manager.sharedInstance.initCachesForProject(self.project!)
  
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    Manager.sharedInstance.sendScreenView("Project Settings")
    
  }
  
  @objc func projectButtonClicked(_ sender: UIBarButtonItem) {

    if self.project?.areas?.allObjects.count > 0 {
      Manager.sharedInstance.startActivity(withMessage: NSLocalizedString("Loading...", comment: ""))
    }

    self.performSegue(withIdentifier: "ShowProject", sender: self)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    if (self.isMovingFromParentViewController){
      if self.project!.isEmpty {
        self.project?.removeWithFiles()
        Manager.sharedInstance.saveCurrentState(nil)
        
      }
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "ShowProject" {
      if let vc = segue.destination as? ProjectContainerViewController {
        vc.project = self.project

      }
    }
  }
  
}
