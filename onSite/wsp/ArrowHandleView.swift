//
//  ArrowHandleView.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-08-21.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

class ArrowHandleView: IssueBaseView, UIGestureRecognizerDelegate, UIActionSheetDelegate {
  
//  var size: CGFloat!
//  var project: Project!
//  let manager: Manager = Manager.sharedInstance
  
  weak var view: UIView!
  weak var areaView: AreaViewController!
  var issue: Issue!
  var position: Position!
  var isMoving = false
  
  var used = false
  
  var pill: UIView!
  var handle: UIView!
  
  var controlImageView: UIImageView!
  var issueTitle: UILabel!
  
  var areaRect: CGRect!
  var originalSize: CGSize!
  var zoom: CGFloat!
  
  var arrowMode: Bool = false
  
  var scalingFactor: CGFloat {
    get {
     return originalSize.width / areaRect.width
    }
  }
  
  init(area: AreaViewController) {
   
    let size = Config.speedrackSize
    super.init(frame: CGRect(x: size/2, y: size/2, width: size/2, height: size/2))
    
    self.size = size
    
    self.areaView = area
    self.project = self.areaView.project
    self.loadView()
    self.isHidden = true
    
  }
  
  
  func loadWithIssue(_ issue: Issue, areaRect: CGRect, zoom: CGFloat, originalSize: CGSize) {
    self.areaRect = areaRect
    self.zoom = zoom
    self.issue = issue
    
    guard let positions = issue.positions else {
      Config.error("No positions for issue \(issue)!")
      return
    }
    
    for obj in positions {
      if let position = obj as? Position {
        self.position = position
        break
      }
    }
    self.originalSize = originalSize
    self.updateLocation(areaRect, zoom: zoom)
    self.alpha = 0
  }
  
  
  func loadView() {
    self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.size, height: self.size)
   
    let centerAdjust = (self.size - Config.draggingHandleSize)/2
    
    self.controlImageView = UIImageView()
    self.controlImageView.image = UIImage(named: "IconPanTool")
    self.controlImageView.frame = CGRect(x: centerAdjust, y: centerAdjust, width: Config.draggingHandleSize, height: Config.draggingHandleSize)
    self.controlImageView.addShadow()
    self.addSubview(self.controlImageView)
    
  }
  
  override func move(_ pos: CGPoint) {
    var pos = pos
    pos.y += self.offset
    self.position.x = (pos.x - areaRect.origin.x) * (originalSize.width) / areaRect.width as NSNumber
    self.position.y = (pos.y - areaRect.origin.y) * (originalSize.height) / areaRect.height as NSNumber
    self.areaView.arrowPositionUpdated(self.position)
    
  }
  
  func moveDidCancel() {
    
    self.position.hasArrow = true
    self.finishMove()
    
  }
  
  func moveDidEnd(_ pos: CGPoint) {
    
    var pos: CGPoint = pos
    
    self.position.hasArrow = true
    pos.y += self.offset
    self.position.x = (pos.x - areaRect.origin.x) * (originalSize.width) / areaRect.width as NSNumber
    self.position.y = (pos.y - areaRect.origin.y) * (originalSize.height) / areaRect.height as NSNumber
    
    self.finishMove()
  }
  
  func enterArrowMode(withBottomSpace bottomSpace: CGFloat) {
    
    var adjust = -0.5 * self.offset * self.scalingFactor
    
    if bottomSpace < 3 * adjust {
      adjust = -3 * adjust
    }
    
    if !self.position.hasArrow!.boolValue {
      self.position.hasArrow = true
      self.position.x = self.position.markerX
      self.position.y = (self.position.markerY as! CGFloat) + adjust as NSNumber
      self.areaView.arrowPositionUpdated(self.position)
      self.updateLocation(self.areaRect, zoom: self.zoom)
      
    }
    
    UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
      self.alpha = 1
      }, completion: { f in
        self.areaView.arrowPositionUpdated(self.position)
    })
  }
  
  
  func updateLocation(_ areaRect: CGRect, zoom: CGFloat) {
    
    if self.position == nil {
      return
    }
    
    if self.position.x == nil || self.position.y == nil {
      return
    }
    
    self.areaRect = areaRect
    self.zoom = zoom
    
    let x = areaRect.origin.x + (self.position!.x! as! CGFloat * zoom)
    let y = areaRect.origin.y + (self.position!.y! as! CGFloat * zoom) - self.offset
    
    self.center = CGPoint(x: x, y: y)
  }
  
  
  func finishMove() {
    UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
      self.alpha = 0
      }, completion: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }

}
