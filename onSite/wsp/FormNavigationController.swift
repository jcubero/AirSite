//
//  FormNavigationController.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-05-30.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit

class FormNavigationController: UINavigationController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
//    self.navigationBar.tintColor = UIColor.whiteColor()
  }
  
  override var preferredStatusBarStyle : UIStatusBarStyle {
    return UIStatusBarStyle.lightContent
  }
  
}
