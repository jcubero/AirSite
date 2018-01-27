//
//  UIColor+Extensions.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-09-29.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation

extension UIColor {
  
  convenience init(red: Int, green: Int, blue: Int) {
    assert(red >= 0 && red <= 255, "Invalid red component")
    assert(green >= 0 && green <= 255, "Invalid green component")
    assert(blue >= 0 && blue <= 255, "Invalid blue component")
    
    self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
  }
  
  convenience init(netHex:Int) {
    self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
  }
  
  static func wspBlue() -> UIColor {
    return UIColor(netHex: 0x1453a2)
  }
  
  static func wspLightBlue() -> UIColor {
    return UIColor(netHex: 0x0073ff)
  }
  
  static func wspNeutral() -> UIColor {
    return UIColor(netHex: 0x5d7987)
  }
  
  static func systemBlue() -> UIColor {
    return UIColor(red: 0.0, green:122.0/255.0, blue:1.0, alpha:1.0)
  }
  
}
