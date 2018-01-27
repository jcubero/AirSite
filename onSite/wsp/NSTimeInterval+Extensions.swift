//
//  NSTimeInterval+Extensions.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-10-20.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation


extension TimeInterval {


  func stringFromat() -> NSString {
    
    let ti = NSInteger(self)
    
    let ms = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
    
    let seconds = ti % 60
    let minutes = (ti / 60) % 60
    let hours = (ti / 3600)
    
    return NSString(format: "%0.2d:%0.2d:%0.2d.%0.4d",hours,minutes,seconds,ms)
  }

}
