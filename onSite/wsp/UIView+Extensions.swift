//
//  UIView+Extensions.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-09-29.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit

extension UIView {
  func addShadow() {
    self.layer.shadowColor = UIColor.black.cgColor
    self.layer.shadowOffset = CGSize(width: 0, height: 4)
    self.layer.shadowOpacity = 0.28
    self.layer.shadowRadius = 8
    self.clipsToBounds = false
  }
  
  
  class func loadFromNibNamed(_ nibNamed: String, bundle : Bundle? = nil) -> UIView? {
    return UINib(
      nibName: nibNamed,
      bundle: bundle
      ).instantiate(withOwner: nil, options: nil)[0] as? UIView
  }
  
}
