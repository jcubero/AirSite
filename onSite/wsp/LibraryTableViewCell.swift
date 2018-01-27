//
//  LibraryTableViewCell.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-12-14.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import UIKit


class LibraryTableViewCell: LibraryBaseCell {


  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let touch = touches.first {
      if touch.location(in: self).x < (0.5 * self.frame.size.width) {
        self.touchSide = .left
      } else {
        self.touchSide = .right
      }
    }
    super.touchesBegan(touches, with: event)
  }
  

}
