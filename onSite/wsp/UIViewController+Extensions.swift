//
//  UIViewController+Extensions.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-09-29.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit


extension UIViewController {
  
  func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
      deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
  }
  
  func presentModalViewControllerFromRight(_ viewController: UIViewController) {
    self.presentModalViewControllerWithCustomTransition(viewController, transitionSubType: kCATransitionFromRight)
  }
  
  func presentModalViewControllerFromLeft(_ viewController: UIViewController) {
    self.presentModalViewControllerWithCustomTransition(viewController, transitionSubType: kCATransitionFromLeft)
  }
  
  func presentModalViewControllerWithCustomTransition(_ viewController: UIViewController, transitionSubType: String) {
    let transition: CATransition = CATransition()
    transition.duration = 0.25
    transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    transition.type = kCATransitionPush
    transition.subtype = transitionSubType
    self.view.window?.layer.add(transition, forKey: "kCATransition")
    self.present(viewController, animated: false, completion: nil)
  }
  
  
  func addRightArrowButtonToNavigationBar(withTitle title: String, target: AnyObject, selector: Selector) -> UIButton {
    
    let button = UIButton(type: UIButtonType.custom)
    button.setTitle(title, for: UIControlState())
    button.titleLabel?.textAlignment = NSTextAlignment.left
    button.setImage(UIImage(named:"ic_chevron_right_white_48pt"), for: UIControlState())
    button.setImage(UIImage(named:"ic_chevron_right_white_48pt"), for: UIControlState.selected)
    button.setImage(UIImage(named:"ic_chevron_right_white_48pt"), for: UIControlState.highlighted)
    button.titleEdgeInsets = UIEdgeInsetsMake(0, -70, 0, 0)
    button.imageEdgeInsets = UIEdgeInsetsMake(0, -44, 0, 0)
    button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0);
    button.titleLabel!.transform = CGAffineTransform(scaleX: -1.0, y: 1.0);
    button.imageView!.transform = CGAffineTransform(scaleX: -1.0, y: 1.0);
    button.sizeToFit();
    
    button.addTarget(target, action: selector, for: .touchUpInside)
    
    let barButton = UIBarButtonItem(customView: button)
    self.navigationItem.setRightBarButton(barButton, animated: false)
    
    return button
    
  }
  
}
