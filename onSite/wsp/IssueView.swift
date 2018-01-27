//
//  IssueView.swift
//  wsp
//
//  Created by Jon Harding on 2015-07-29.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

protocol IssueViewDelegate: class {
  
  func issueDidLongPress(_ issueView: IssueView)
  func issueDidLoseFocus(_ issueView: IssueView)
  
}


class IssueView: IssueBaseView, UIGestureRecognizerDelegate, UIActionSheetDelegate {
  
  let strokeSize: CGFloat = 1
  let strokeColor: UIColor = UIColor.white
  
  let activeStrokeSize: CGFloat = 5
  
  var used:Bool = false
  
  weak var delegate: IssueViewDelegate?
  var originX: CGFloat!
  var originY: CGFloat!
  
  var view: UIView!
  weak var areaView: AreaViewController!
  weak var issueImageCache: IssueImageCache!
  var issue: Issue!
  var position: Position!
  var isMoving = false
  
//  var pill: UIView!
//  var handle: UIView!

  var imageView: UIImageView!
  var strokeView: UIImageView!
  var activeStrokeView: UIImageView!
  var handleImageView: UIImageView!
  var issueTitle: UILabel!
  
  var areaRect: CGRect!
  var originalSize: CGSize!
  var zoom: CGFloat!
  
  var arrowMode: Bool = false
  var tapped: Bool = false
  
  init(project: Project, imageCache: IssueImageCache) {
    
    super.init(project: project, anchor: CGPoint(x: 0, y: 0))
    
    self.issueImageCache = imageCache
    self.loadView()
    
    let tapRec = UITapGestureRecognizer(target: self, action:#selector(IssueView.handleTap(_:)))
    tapRec.delegate = self
    self.addGestureRecognizer(tapRec)
    let longPressRec = UILongPressGestureRecognizer(target: self, action: #selector(IssueView.handleLongPress(_:)))
    longPressRec.delegate = self
    self.addGestureRecognizer(longPressRec)
    
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func loadView() {
    
    self.isHidden = true
    
    self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.size, height: self.size)
    
    let centerAdjust = (self.size - Config.draggingHandleSize)/2
    
    self.draggingOffset = centerAdjust + (Config.draggingHandleSize / 2)
    
    self.handleImageView = UIImageView()
    self.handleImageView.frame = CGRect(x: centerAdjust, y: centerAdjust, width: Config.draggingHandleSize, height: Config.draggingHandleSize)
    self.handleImageView.alpha = 0
    
    self.imageView = UIImageView()
    self.imageView.frame = CGRect(x: 0, y: 0, width: self.size, height: self.size)
    
    self.strokeView = UIImageView()
    self.strokeView.frame = CGRect(x: -self.strokeSize, y: -self.strokeSize, width: self.size + 2 * self.strokeSize, height: self.size + 2 * self.strokeSize)
    
    self.activeStrokeView = UIImageView()
    self.activeStrokeView.frame = CGRect(x: -self.activeStrokeSize, y: -self.activeStrokeSize, width: self.size + 2 * self.activeStrokeSize, height: self.size + 2 * self.activeStrokeSize)
    self.activeStrokeView.alpha = 0
    
    self.issueTitle = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
    self.issueTitle.textColor = UIColor.white
    self.issueTitle.textAlignment = NSTextAlignment.center
    self.addSubview(self.issueTitle)
    
    self.addSubview(self.handleImageView)
    self.addSubview(self.activeStrokeView)
    self.addSubview(self.strokeView)
    self.addSubview(self.imageView)
    self.addSubview(self.issueTitle)
    
    self.renderImageAndColorForTag(nil)
    
  }
  
  
  
  func updateIssueWithProject(_ project: Project, issue: Issue, area: AreaViewController, areaRect: CGRect, zoom: CGFloat, originalSize: CGSize) {
    
    self.used = true
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
        self.originX = position.markerX as! CGFloat
        self.originY = position.markerY as! CGFloat
        break
      }
    }
    
    self.originalSize = originalSize
    self.areaView = area
    self.project = self.areaView.project
    
    
    self.updateLocation(areaRect, zoom: zoom)
    
    self.renderImageAndColorForTag(self.issue)
    
    if self.handleImageView.image == nil {
      self.handleImageView.image = UIImage(named: "DragTarget")
    }
    self.isHidden = false
  }
  
  
  func renderImageAndColorForTag(_ issue: Issue?) {
    var shape = Tag.defaultImage()
    var color = Tag.defaultColor()
    if let i = issue {
      shape = i.shape
      color = i.color
      self.issueTitle.text = i.issueTag
    }
    
    self.imageView.image = self.issueImageCache.getImageWithShape(shape, color: color, ofSize: self.imageView.frame.size.width)
    self.strokeView.image = self.issueImageCache.getImageWithShape(shape, color: self.strokeColor, ofSize: self.strokeView.frame.size.width)
    self.activeStrokeView.image = self.issueImageCache.getImageWithShape(shape, color: color, ofSize: self.activeStrokeView.frame.size.width)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    if self.isMoving {
      self.tapped = true
    }
  }
  
  @objc func handleTap(_ rec: UIGestureRecognizer) {
    if !self.isMoving {
      self.areaView.issue = self.issue
    }
    
  }
  
  func focus() {
    UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
      self.activeStrokeView.alpha = 0.5
      }, completion: { finished in
    })
  }
  
  func unfocus() {
    UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
      self.activeStrokeView.alpha = 0
      }, completion: { finished in
    })
  }
  
  @objc func handleLongPress(_ rec: UILongPressGestureRecognizer) {
    self.areaView.showIssueMenuPopover(self)
  }
  
  func update(_ tagCollection: TagCollection?) {
    if tagCollection != nil {
      self.issue.tagsCollection = tagCollection!
      self.renderImageAndColorForTag(self.issue)
    } else {
      self.isHidden = true
    }
  }
  
  func updateLocation(_ areaRect: CGRect, zoom: CGFloat) {
    
    if (self.originX == nil || self.originY == nil) {
      Config.error("Position is missing for an issue!")
      return
    }
    
    self.areaRect = areaRect
    self.zoom = zoom
    
    let x = areaRect.origin.x + (self.originX * zoom)
    let y = areaRect.origin.y + (self.originY * zoom)
//    self.frame = CGRect(x: x, y: y, width: self.size, height: self.size)
    self.center = CGPoint(x: x, y: y)
    
  }
  
  func startArrow() {
    self.arrowMode = true
    self.areaView.enterArrowMode(self.issue)
  }
  
  func moveDidStart() {
    self.isMoving = true
    self.animateShadow(15, offset: CGSize(width: 0, height: 15), opacity: 0.25)
    
    UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
      let centerAdjust = (self.size - Config.draggingHandleSize)/2
      self.frame.origin.y += -self.offset
      self.handleImageView.frame.origin.y = centerAdjust + self.offset
      self.handleImageView.alpha = 1
      }, completion: { finished in
    })
    
  }
  
  func moveDidEnd( _ pos: CGPoint, areaRect: CGRect, zoom: CGFloat, originalSize: CGSize) {
    var pos = pos
    self.tapped = false
    self.finishMove {
      
      pos.y += self.offset
      
      self.originX = (pos.x - areaRect.origin.x) * (originalSize.width) / areaRect.width
      self.originY = (pos.y - areaRect.origin.y) * (originalSize.height) / areaRect.height
      
      self.position.markerX = self.originX as! NSNumber
      self.position.markerY = self.originY as! NSNumber
      
      self.position.setModified()
      self.manager.saveCurrentState(nil)
      
    }
  }
  
  func moveDidCancel() {
    self.finishMove {
      UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
        self.updateLocation(self.areaRect, zoom: self.zoom)
        }, completion: { finished in
      })
    }
  }
  
  override func move( _ pos: CGPoint) {
    var pos = pos
    pos.y += self.offset
    
    self.position.markerX = (pos.x - areaRect.origin.x) * (originalSize.width) / areaRect.width as NSNumber
    self.position.markerY = (pos.y - areaRect.origin.y) * (originalSize.height) / areaRect.height as NSNumber
    
    if self.position.hasArrow!.boolValue {
      self.areaView.arrowPositionUpdated(self.position)
    }
    
  }
  
  func finishMove(_ completion: @escaping () -> Void) {
    self.isMoving = false
    self.areaView.moveIssue = nil
    self.areaView.activeIssue = nil
    self.animateShadow(15, offset: CGSize(width: 0, height: 15), opacity: 0)
    UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
      let centerAdjust = (self.size - Config.draggingHandleSize)/2
      self.frame.origin.y = self.frame.origin.y - 88
      self.handleImageView.frame.origin.y = centerAdjust
      self.handleImageView.alpha = 0
      }, completion: { finished in
        completion()
    })
  }
  
  func animateShadow(_ radius: CGFloat, offset: CGSize, opacity: Float) {
    
    var animation = CABasicAnimation(keyPath: "shadowRadius")
    animation.toValue = radius
    self.imageView.layer.add(animation, forKey: "shadowRadius")
    
    animation = CABasicAnimation(keyPath: "shadowOffset")
    animation.toValue = NSValue(cgSize: offset)
    self.imageView.layer.add(animation, forKey: "shadowOffset")
    
    animation = CABasicAnimation(keyPath: "shadowOpacity")
    animation.toValue = opacity
    self.imageView.layer.add(animation, forKey: "shadowOpacity")
    
    self.imageView.layer.shadowOffset = offset
    self.imageView.layer.shadowOpacity = opacity
    self.imageView.layer.shadowRadius = radius
    
  }


}
