//
//  ArrowView.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-08-21.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit
import CoreData

class ArrowView: UIView, NSFetchedResultsControllerDelegate {
  
  let manager: Manager = Manager.sharedInstance
  
  var project: Project!
  var area: Area!
  var rect: CGRect!
  var originalSize: CGSize!
  var fetched = false
  var issues: [Issue]?
  weak var avc: AreaViewController!
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  func redraw(_ rect: CGRect, originalSize: CGSize, issues: [Issue]?) {
    self.rect = rect
    self.originalSize = originalSize
    self.issues = issues
    self.setNeedsDisplay()
  }
  
  override func draw(_ rect: CGRect) {
    super.draw(rect)
    
    self.layer.sublayers = nil
    
    if self.rect == nil {
      return
    }
    
    guard let issues = self.issues else {
      return
    }
    
    for issue in issues {
      guard let positions = issue.positions else {
        continue
      }
      for position in positions.allObjects as! [Position] {
        if position.hasArrow == nil || !position.hasArrow!.boolValue {
          continue
        }
        
        let markerX = position.markerX
        let markerY = position.markerY
        
        let unsavedX = position.x
        let unsavedY = position.y
        
        let x = self.rect.origin.x + (unsavedX as! CGFloat) * (self.rect.width/self.originalSize.width)
        let y = self.rect.origin.y + (unsavedY as! CGFloat) * (self.rect.height/self.originalSize.height)
        
        let mX = self.rect.origin.x + (markerX as! CGFloat) * (self.rect.width/self.originalSize.width)
        let mY = self.rect.origin.y + (markerY as! CGFloat) * (self.rect.height/self.originalSize.height)
        
        let arrowPath = UIBezierPath.bezierPathWithArrowFromPoint(CGPoint(x: mX, y: mY), endPoint: CGPoint(x: x, y: y), tailWidth: 1, headWidth: 8, headLength: 6)
        
        var color = position.issue!.color
        if self.avc.drawLighter && !self.avc.darkerIssue(issue) {
          color = color.withAlphaComponent(0.09)
        }
        
        let layer = CAShapeLayer()
        layer.path = arrowPath.cgPath
        layer.fillColor = color.cgColor
        layer.strokeColor = color.cgColor
        
        
        self.layer.addSublayer(layer)
        
      }
    }
  }
}
