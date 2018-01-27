//
//  ProjectNavigationController.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-08-23.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

class ProjectNavigationController: UINavigationController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationBar.tintColor = UIColor.white
  }
  
  override var preferredStatusBarStyle : UIStatusBarStyle {
    if let _  = self.topViewController as? Login {
      return UIStatusBarStyle.default
    } else {
      return UIStatusBarStyle.lightContent
    }
    
  }
  
}
