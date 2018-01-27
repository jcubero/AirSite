//
//  Tag.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-06-26.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord
import PromiseKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


enum TagType: String {
  case Text = "Text", Input = "Input", NumericInput = "NumericInput", End = "End"
  static let allValues = [Text, Input, NumericInput, End]
}



@objc(Tag)

class Tag: SyncableModel {
  
  // properties
  @NSManaged var title: String?
  @NSManaged var color: NSNumber?
  @NSManaged var shape: NSNumber?
 
  // relationships
  @NSManaged var parent: Tag?
  @NSManaged var children: NSSet?
  @NSManaged var issueTags: NSSet?
  @NSManaged var level: Level
  
  static let TagTitleInput = "{@}"
  static let TagTitleNumericInput = "{#}"
  static let TagTitleEnd = "{End}"
  
  static let NoShapeImage = "ic_crop_7_5"
  static let NoColorColor = Tag.colorForValue(0)
  
  static var endPredicate: NSPredicate {
    get {
     return NSPredicate(format: "title ==[c] %@", Tag.TagTitleEnd)
    }
  }

  override class func registerSyncableData(_ converter: RemoteDataConverter) {
  
    converter.registerRemoteData("title", remote: "title", type: .String)
    converter.registerRemoteData("color", remote: "color", type: .Integer)
    converter.registerRemoteData("shape", remote: "shape", type: .Integer)
    
    converter.registerRemoteData("parent", remote: "parent", type: .Relationship, entity: "Tag")
    
  }
  
  var type : TagType {
    get {
      if let title = self.title {
        if title.range(of: Tag.TagTitleInput) != nil {
          return .Input
        } else if title.range(of: Tag.TagTitleNumericInput) != nil {
          return .NumericInput
        } else if title.range(of: Tag.TagTitleEnd) != nil {
          return .End
         }
      }
      return .Text
    }
  }
  
  var tagHierarchy: [Tag] {
    get {
      var currentTag = self
      var tags: [Tag] = [currentTag]
      
      while (currentTag.hasParent()) {
        currentTag = currentTag.parent!
        tags.append(currentTag)
      }
      
      return tags.reversed()
      
    }
  }
  
  var isInputType: Bool { get {return self.type == .NumericInput || self.type == .Input }}
  
  var nonEmptyTitle: String {
    get {
      var title = ""
      
      if let t = self.title {
        title = t
      }
      
      return title
    }
  }
  
  var nonEmptyAttributedTitle: NSAttributedString {
    
    let title = self.nonEmptyTitle as NSString
    let string = NSMutableAttributedString(string: title as String)
    let underlineLength = 6
    
    if self.type == .Input || self.type == .NumericInput {
      
      let lookup = self.type == .Input ? Tag.TagTitleInput: Tag.TagTitleNumericInput
      var range = title.range(of: lookup)
      let spaces = String(repeating: " ", count: underlineLength)
      
      string.replaceCharacters(in: range, with: spaces)
      range.length = underlineLength
      string.addAttribute(NSAttributedStringKey.underlineStyle, value: NSUnderlineStyle.styleSingle.rawValue, range: range)
      
      
    }
    
    return string
    
  }

  var nonEmptyColoredAttributedTitle: NSAttributedString {
    
    let title = self.nonEmptyTitle as NSString
    let string = NSMutableAttributedString(string: title as String)
    let underlineLength = 6
    
    if self.type == .Input || self.type == .NumericInput {
      
      let lookup = self.type == .Input ? Tag.TagTitleInput: Tag.TagTitleNumericInput
      var range = title.range(of: lookup)
      let spaces = String(repeating: " ", count: underlineLength)
      
      string.replaceCharacters(in: range, with: spaces)
      range.length = underlineLength
      string.addAttribute(NSAttributedStringKey.underlineStyle, value: NSUnderlineStyle.styleSingle.rawValue, range: range)
      string.addAttribute(NSAttributedStringKey.foregroundColor, value:UIColor.systemBlue(), range: range)
      
    }
    
    return string
    
  }
  

  var shouldHideTag:Bool  {
    return self.nonEmptyTitle.uppercased() == "N.A."
  }
  
  
  // for shapes and colors, a zero value means none, so these are indexed starting at 1 onwards
  static let Shapes = ["Square", "Diamond", "Hexagon", "Parallelogram", "Circle"]

  
  func shapeValue() -> String {
    if let shapeInt = self.shape {
      var imageName: String
      
      switch shapeInt {
      case 1:
        imageName = "Square"
      case 2:
        imageName = "Diamond"
      case 3:
        imageName = "Hexagon"
      case 4:
        imageName = "Parallelogram"
      default:
        imageName = "Circle"
      }
      return imageName
    } else {
      return Tag.defaultImage()
    }
    
  }
  
  
  var colorString : String { get {
    if let color = self.color?.int32Value {
      if color == 0 {
        return "Default"
      }
      if color <= Tag.Colors.count {
        return Tag.Colors[Int(color) - 1]
      }
    }
    return "Default"
    }
  }
  
  func colorValue() -> UIColor {
    
    if let color = self.color?.int32Value {
      return Tag.colorForValue(Int(color))
    } else {
      return Tag.colorForValue(0)
    }
    
  }
  
  func hasParent() -> Bool {
    if self.parent != nil {
      return true
    } else {
      return false
    }
    
  }
  
  func findTopLevelParent() -> Tag {
    
    if !self.hasParent() {
      return self
    }
    
    var tag = self.parent!
    
    while tag.hasParent() {
      tag = tag.parent!
    }
    return tag
    
  }
  
  @objc func getAllChildren( _ append: [Tag] = []) -> [Tag] {
    var append = append
    
    append.append(self)
   
    if self.children?.count > 0 {
      for child in self.children! {
        append = (child as AnyObject).getAllChildren(append)
      }
    }
    
    return append
  }
  
  static func getFirstTagWithLevel(_ tags: [Tag], level: Level)  -> Tag? {
   
    for tag in tags {
      if tag.level == level {
        return tag
      }
    }
    
    return nil
    
  }
  
  static func defaultColor() -> UIColor {
    return Tag.colorForValue(0)
  }
  
  static func defaultImage() -> String {
    return Tag.imageForValue(0)
  }
  
//  static let Colors = ["Blue", "Green", "Orange", "Red", "Purple", "Black"]
  static let Colors = ["Blue", "Green", "Orange", "Red", "Purple", "Black"]
  static func colorForValue(_ value: Int) -> UIColor {
    
    var color: Int
    switch value {
      // Blue
    case 1:
      color = 0x0073ff
    case 2:
      // Green
      color = 0x00ae24
    case 3:
      // Organge
      color = 0xffc107
    case 4:
      // Red
      color = 0xff1744
    case 5:
      // Purple
      color = 0x9c27b0
    case 6:
      // black
      color = 0x000000
    default:
      // WSP Neutral
      color = 0x5d7987
    }
    
    return UIColor(netHex: color)
  }
  
  static func imageForValue(_ value: Int) -> String {
    var imageName: String
    switch value {
    case 1:
      imageName = "Square"
    case 2:
      imageName = "Diamond"
    case 3:
      imageName = "Hexagon"
    case 4:
      imageName = "Parallelogram"
    default:
      imageName = "Circle"
    }
    return imageName
  }

  
  func addTagToImage(_ image: Data, overlay: UIImage) -> Data {
    
    let inImage = UIImage(data: image)!
    let height: CGFloat = 0.20 * inImage.size.height
    var cropped = CGRect(x: 0, y: 0, width: overlay.size.width - 60, height: overlay.size.height)
    
    if (overlay.scale > 1) {
        cropped = CGRect(x: 0,y: 0, width: cropped.size.width * overlay.scale, height: cropped.size.height * overlay.scale)
    }
    
    
    let imageRef = overlay.cgImage?.cropping(to: cropped)
    let newOverlay = UIImage(cgImage: imageRef!)
    let ovr = self.resizeImage(newOverlay, newHeight: height)
    
    UIGraphicsBeginImageContext(CGSize(width: inImage.size.width, height: inImage.size.height + height))
    
    inImage.draw(in: CGRect(x: 0, y: 0, width: inImage.size.width, height: inImage.size.height))
   
    self.colorValue().setFill()
    let bottomRect = CGRect(x: 0, y: inImage.size.height, width: inImage.size.width,  height: height)
    UIRectFill(bottomRect)
    
    ovr.draw(in: CGRect(x: 0, y: inImage.size.height, width: ovr.size.width, height: ovr.size.height))
    
    
    let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    
    UIGraphicsEndImageContext()
    let project = self.level.project
    
    return UIImageJPEGRepresentation(newImage, project.jpegPhotoQuality)!
    
  }
  
  func resizeImage(_ image: UIImage, newHeight: CGFloat) -> UIImage {
    
    let scale = newHeight / image.size.height
    let newWidth = floor(image.size.width * scale)
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }
  
  func getFormatedChildTitle() -> String? {
    var title: String? = ""
    var tag: Tag? = self
    while let parentTag = tag {
      if tag!.parent != nil {
        if title != "" {
          title = "\(parentTag.title!) > \(title!)"
        } else {
          title = "\(parentTag.title!)"
        }
        tag = parentTag.parent
      } else {
        tag = nil
      }
    }
    return title
  }
  
  
}
