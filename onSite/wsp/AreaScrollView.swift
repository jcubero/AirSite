//
//  AreaScrollView.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-08-17.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

class AreaScrollView: UIScrollView, UIGestureRecognizerDelegate {
  
  weak var pages: PagesViewController!
  var touchesCount = 0
  var superiorGestureRecognizer: UIPanGestureRecognizer?
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  
}
