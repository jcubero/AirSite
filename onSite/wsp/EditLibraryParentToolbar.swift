//
//  EditLibraryParentToolbar.swift
//  
//
//  Created by Filip Wolanski on 2016-01-15.
//
//

import UIKit


protocol EditLibraryParentToolbarDelegate: class {
  func popToLevel(_ level: Level)
}

class EditLibraryParentToolbar: UIView {
  
  weak var delegate: EditLibraryParentToolbarDelegate?
  
  var parentScrollView: UIScrollView! {
    didSet {
      self.height = self.parentScrollView.frame.height
    }
  }
  
  var tags: [Tag] = [] { didSet { self.setNeedsDisplay() } }
  var level: Level! { didSet { self.setNeedsDisplay() } }
  
  var fontSize: CGFloat = 16
  var font: UIFont  {
    get {
      return UIFont.systemFont(ofSize: self.fontSize)
    }
  }
  
  var defaultColor = UIColor.gray
  var selectColor = UIColor.systemBlue()
  var chevronColor = UIColor(hexString: "cccccc")
  var chevronText = " — "
  
  let startMargin: CGFloat = 32
  
  var height: CGFloat = 50
  var textY : CGFloat {
    get {
      return (self.height - self.fontSize) / 2
    }
  }
 
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    let touch = UITapGestureRecognizer(target: self, action: #selector(EditLibraryParentToolbar.handleTap(_:)))
    self.addGestureRecognizer(touch)
    
    self.backgroundColor = UIColor.clear
    
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  
  @objc func handleTap(_ sender:UITapGestureRecognizer) {
    
    let point = sender.location(in: self)
    var pos: CGFloat = self.startMargin
    
    for tag in self.tags {
      let initPoint = pos
      pos += self.measureStringWidth(tag.nonEmptyTitle)
      
      if initPoint < point.x && point.x < pos {
        self.popTag(tag)
        return
      }
      
      pos += self.measureStringWidth(self.chevronText)
    }
    
  }
  
  func popTag(_ tag: Tag)  {
    
    let index: Int = self.tags.index(of: tag)!
    self.tags.removeSubrange(index..<self.tags.count)
    self.level = tag.level
    self.delegate?.popToLevel(self.level)
    
  }
  
  
  override func draw(_ rect: CGRect) {
    
    let margin: CGFloat = 10
    var pos: CGFloat = self.startMargin
    
    for tag in self.tags {
      pos = self.drawTag(tag.nonEmptyTitle, pos: pos)
      pos = self.drawChevron(pos)
    }
    
    pos = self.drawLegend(level.nonEmptyTitle, pos: pos)
    
    pos += margin + self.startMargin
    self.parentScrollView.contentSize = CGSize(width: pos, height: self.parentScrollView.frame.height)
    
    var x = pos - self.parentScrollView.frame.size.width
    if x < 0 { x = 0 }
    
    self.parentScrollView.setContentOffset(CGPoint(x: x,y: 0), animated: true)
    
    
  }
  
  func drawChevron(_ pos: CGFloat) -> CGFloat {
    
    let attributes = [NSAttributedStringKey.font.rawValue: self.font, NSAttributedStringKey.foregroundColor: self.chevronColor as Any] as! [NSAttributedStringKey : Any]
    
    return self.drawTextWithAttributes(self.chevronText, pos: pos, attributes: attributes as [NSAttributedStringKey : Any])
    
  }
  
  func drawTag(_ s: String, pos: CGFloat) -> CGFloat {
    
    let attributes = [NSAttributedStringKey.font.rawValue: self.font, NSAttributedStringKey.foregroundColor: self.selectColor] as! [NSAttributedStringKey : Any]
    
    return self.drawTextWithAttributes(s, pos: pos, attributes: attributes as [NSAttributedStringKey : Any])
  }
  
  func drawLegend(_ s: String, pos: CGFloat) -> CGFloat {
    
    let attributes = [NSAttributedStringKey.font.rawValue: self.font, NSAttributedStringKey.foregroundColor: self.defaultColor] as! [NSAttributedStringKey : Any]
    return self.drawTextWithAttributes(s, pos: pos, attributes: attributes as [NSAttributedStringKey : Any])
    
  }
  
  func drawTextWithAttributes(_ s: String, pos: CGFloat, attributes: [NSAttributedStringKey : Any]) -> CGFloat {
    
    let rect = CGRect(x: pos, y: self.textY, width: 1000, height: self.height)
    (s as NSString).draw(in: rect, withAttributes: attributes)
    
    return self.measureStringWidth(s) + pos
    
  }
  
  func measureStringWidth(_ s: String) -> CGFloat {
    
    let attributes = [NSAttributedStringKey.font: self.font]
    let bounding = (s as NSString).size(withAttributes: attributes)
    return bounding.width
    
  }
  

}
