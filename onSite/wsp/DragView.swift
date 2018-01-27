//
//  Drag.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-08-03.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

enum DragViewMode {
  case recentlyUsed, copied, locked, new
}

class DragView: IssueBaseView, UIGestureRecognizerDelegate {
  
  weak var areaViewController: AreaViewController!
  
  var handle: UIView!
  
  var draggable: UIView!
  var imageView: UIImageView!
  var handleImageView: UIImageView!
  
  var isDragging = false
  var anchor: CGPoint!
  var aTag: Issue?
  
  var imageCache: IssueImageCache!
  
  var inUse:Bool = true
  var imageLabel: UILabel!
  
  var mode: DragViewMode = .new
  var longPressTimer: Timer?
  var touchesBeganPoint: CGPoint?
  
  init(project: Project, tag: Issue?, anchor: CGPoint, imageCache: IssueImageCache) {
    super.init(project: project, anchor: anchor)
    
    if tag == nil {
      self.size = Config.draggingHandleSize
    } else {
      self.size = Config.speedrackSize
    }
    self.imageCache = imageCache
    
    self.frame = CGRect(x: anchor.x, y: anchor.y, width: self.size, height: self.size)
    
    self.anchor = anchor
    
    self.draggable = UIView()
    
    self.draggable.frame = CGRect(x: 0, y: 0, width: self.size, height: self.size)
    
    self.imageView = UIImageView()
    self.imageView.frame = CGRect(x: 0, y: 0, width: self.size, height: self.size)
    
    self.handle = UIView()
    self.handle.frame = self.draggable.frame
    
    let centerAdjust = (self.size - Config.draggingHandleSize)/2
    self.handleImageView = UIImageView()
    self.handleImageView.frame = CGRect(x: centerAdjust, y: centerAdjust, width: Config.draggingHandleSize, height: Config.draggingHandleSize)
    self.handleImageView.image = UIImage(named: "DragTarget")
    
    self.addSubview(self.draggable)
    self.draggable.addSubview(self.handle)
    self.handle.addSubview(self.handleImageView)
    self.draggable.addSubview(self.imageView)
    
    self.handle.isHidden = true
    self.aTag = tag
    self.renderImageAndColorForTag(tag)
    
    if let issue = tag {
      self.imageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.size, height: self.size))
      self.imageLabel.text = issue.issueNumber
      self.imageLabel.textColor = UIColor.white
      self.imageLabel.textAlignment = NSTextAlignment.center
      self.imageView.addSubview(self.imageLabel)
    } else {
      self.addTargetImage()
    }
    
    self.animateShadow(8, offset: CGSize(width: 0, height: 4), opacity: 0.28)
    
    
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(DragView.handleTap(_:)))
    self.addGestureRecognizer(tapGesture)
    
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func resetWithNewIssue(_ issue: Issue) {
    self.aTag = issue
    self.renderImageAndColorForTag(issue)
    self.imageLabel.text = issue.issueNumber
    
  }
 
  func addTargetImage() {
    let decoIcon = UIImageView()
    let imageSize: CGFloat = 20
    decoIcon.contentMode = UIViewContentMode.scaleAspectFit
    decoIcon.frame = CGRect(x: self.size/2 - imageSize/2, y: self.size/2 - imageSize/2, width: imageSize, height: imageSize)
    decoIcon.image = UIImage(named: "crosshair-icon")
    self.imageView.addSubview(decoIcon)
  }
  
  func renderImageAndColorForTag(_ tag: Issue?) {
    var shape = Tag.defaultImage()
    var color = UIColor.wspNeutral()
    if let t = tag {
      shape = t.shape
      color = t.color
    }
    self.imageView.image = self.imageCache.getImageWithShape(shape, color: color, ofSize: self.imageView.frame.size.width)
  }
  
  @objc func handleTap(_ sender: AnyObject) {
    
    self.areaViewController.issue = self.aTag
    
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    
    self.cancelLongPressTimer()
    self.initiateLongPressTimer()
    
    guard let touch = touches.first else {
      Config.error("Could not read touch information!")
      return
    }
    self.touchesBeganPoint = touch.location(in: self.areaViewController.pillRack)
    
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesMoved(touches, with: event)
    
    guard let touch = touches.first else {
      Config.error("Could not read touch information!")
      return
    }
    
    let current = touch.location(in: self.areaViewController.pillRack)
    guard let begin = self.touchesBeganPoint else {
      Config.error("Could not read touch information!")
      return
    }
    
    let distance = hypot((current.x - begin.x), (current.y - begin.y))
    if distance > 15 {
      self.cancelLongPressTimer()
      self.initiateDrag()
    }
    
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    self.cancelLongPressTimer()
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesCancelled(touches, with: event)
    self.cancelLongPressTimer()
    
  }
  
  func initiateLongPressTimer() {
    self.longPressTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(DragView.longPressEvent(_:)), userInfo: nil, repeats: false)
  }
  
  func cancelLongPressTimer() {
    if let timer = self.longPressTimer {
      timer.invalidate()
      self.longPressTimer = nil
    }
  }
  
  @objc func longPressEvent(_ sender: AnyObject) {
    
    self.longPressTimer = nil
    
    if self.mode == .recentlyUsed {
      self.areaViewController.drag = nil
      self.dragDidCancel()
      guard let issue = self.aTag else {
        return
      }
      
      self.areaViewController.project.addLockedIssue(issue)
      
    } else if self.mode == .locked {
      self.areaViewController.drag = nil
      self.dragDidCancel()
      guard let _ = self.aTag else {
        return
      }
      
      self.finishedLocking()
      
    }
    
  }
  
  func initiateDrag() {
    
    self.dragDidStart()
    self.areaViewController.startDrag(self)
    
  }
  
  func dragDidStart() {
    self.isHidden = false
    self.handle.isHidden = false
    if self.isDragging {
      return
    }
    self.isDragging = true
    self.animateShadow(15, offset: CGSize(width: 0, height: 15), opacity: 0.25)
    UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
      self.handle.frame.origin.y = self.offset
      self.handle.alpha = 1
      }, completion: { finished in
        
    })
  }
  
  func shrink(_ completion: (() -> ())?) {
    UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
      self.imageView.frame.origin.y = self.offset + (self.size/2 - self.size/2)
      self.handle.alpha = 0
      }, completion: { finished in
        if completion != nil {
          completion!()
        }
    })
  }
  
  func dragDidEnd(_ animated: Bool) {
    
    self.isDragging = false
    self.animateShadow(8, offset: CGSize(width: 0, height: 4), opacity: 0.28)
    self.handle.isHidden = false
    
    if animated {
      UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
        self.imageView.frame.origin.y = 0
        self.handle.frame.origin.y = 0
        }, completion: { finished in
      })
      
    } else {
      self.imageView.frame.origin.y = 0
      self.handle.frame.origin.y = 0
      
    }
  }
  
  func dragDidCancel() {
    self.isDragging = false
    self.animateShadow(8, offset: CGSize(width: 0, height: 4), opacity: 0.28)
    self.handle.isHidden = false
    UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
      self.imageView.frame.origin.y = 0
      self.handle.frame.origin.y = 0 
      self.handle.alpha = 0
      }, completion: { finished in
    })
    
  
  }
  
  override func move(_: CGPoint) {
    
  }
  
  func reset() {
    self.isDragging = false
    self.imageView.layer.shadowOffset = CGSize(width: 0, height: 0)
    self.imageView.layer.shadowOpacity = 0.45
    self.imageView.layer.shadowRadius = 3
    self.imageView.frame.origin.y = 0
    self.handle.frame.origin.y = 0
  }
  
  func remakeFrame(_ anchor: CGPoint) {
    self.frame = CGRect(x: anchor.x, y: anchor.y, width: self.size, height: self.size)
    
  }
  
  func finishedCopying() {
    if self.mode == .copied {
      self.aTag!.copied = nil
      self.inUse = false
      self.isHidden = true
      
    }
  }
  
  func finishedLocking() {
    if self.mode == .locked {
      self.aTag!.locked = nil
      self.inUse = false
      self.isHidden = true
    }
    
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
