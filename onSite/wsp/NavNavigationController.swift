//
//  NavNavigationController.swift
//  wsp
//
//  Created by Jon Harding on 2015-10-20.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import UIKit

protocol NavNavigationControllerDelegate: class {
  func hideNav()
}

class NavNavigationController: UINavigationController {
  
  weak var myDelegate: NavNavigationControllerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let swipeFromRight = UISwipeGestureRecognizer(target: self, action: #selector(NavNavigationController.handleSwipeFromRight(_:)))
    swipeFromRight.direction = .left
    self.view.addGestureRecognizer(swipeFromRight)
    
  }
  
  
  override func viewWillAppear(_ animated: Bool) {
    
    super.viewWillAppear(animated)
    self.setNavigationBarHidden(true, animated: false)
    
  }
  
  @objc func handleSwipeFromRight(_ rec: UISwipeGestureRecognizer) {
    self.myDelegate?.hideNav()
  }
  
}
