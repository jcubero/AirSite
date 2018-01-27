//
//  ContentView.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-09-19.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

class ContentView: UIView {

  override func hitTest(_ point: CGPoint, with e: UIEvent?) -> UIView? {
    if let result = super.hitTest(point, with:e) {
      return result
    }
    for sub in Array(self.subviews.reversed()) {
      let pt = self.convert(point, to:sub)
      if let result = sub.hitTest(pt, with:e) {
        return result
      }
    }
    return nil
  }

}
