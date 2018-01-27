//
//  IssueBaseView.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-08-22.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

class IssueBaseView: UIView {
  
  var size: CGFloat!
  var project: Project!
  
  var colorInt: Int = 0
  var shapeInt: Int = 0
  
  let manager: Manager = Manager.sharedInstance
  
  var draggingOffset: CGFloat = 0
  var offset: CGFloat = -88
  
  init(project: Project, anchor: CGPoint) {
    
    let size = Config.speedrackSize
    
    let frame = CGRect(x: anchor.x, y: anchor.y, width: size, height: size)
    super.init(frame: frame)
    self.project = project
    self.size = size
  }

  func move(_ pos: CGPoint) {
    Config.error("Should be overridden")
    abort()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
}
