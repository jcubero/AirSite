//
//  LayerView.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-08-21.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

class LayerView: UIView {
  
  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    for subview in subviews {
      if !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
        return true
      }
    }
    return false
  }
  
}
