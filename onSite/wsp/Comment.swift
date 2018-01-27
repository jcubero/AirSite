//
//  Comment.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-07-31.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord
import PromiseKit

@objc(Comment)

class Comment: SyncableModel {
  
  // properties
  @NSManaged var title: String?
  @NSManaged var areaX: NSNumber?
  @NSManaged var areaY: NSNumber?
  @NSManaged var areaWidth: NSNumber?
  @NSManaged var areaHeight: NSNumber?
  
  
  @NSManaged var commentType: String?
  
  @NSManaged var cropData: NSValue?
  @NSManaged var rotationData: NSNumber?
  
  // relationships
  @NSManaged var issue: Issue?
  @NSManaged var user: User?
  @NSManaged var imageFile: File?
  @NSManaged var originalImageFile: File?
  
  // images
  var image: UIImage? { get {
    return self.imageFile?.image
    } set {
      if newValue != nil {
        let imageFile = self.makeFile("imageFile", project: self.project)
        imageFile.image = newValue
      }
    }
  }
  
  var imageData: Data? { get {
    return self.imageFile?.imageData
    } set {
      if newValue != nil {
        let imageFile = self.makeFile("imageFile", project: self.project)
        imageFile.imageData = newValue
      }
    }}
  
    var imagePath: URL? { get { return self.imageFile?.path } }
  
  var originalImageData: Data? { get {
    return self.originalImageFile?.imageData
    } set {
      if newValue != nil {
        let imageFile = self.makeFile("originalImageFile", project: self.project)
        imageFile.imageData = newValue
      }
    }}
  
  
  var project: Project { get { return self.issue!.area!.project! } }
  
  
  func sequenceName(_ seq: Int) -> String {
    
    guard let issue = self.issue else {
      Config.error()
      return "Comment without Issue!"
    }
    
    let sequence = String(format: "%02d", seq)
    
    return "\(issue.issueTag).\(sequence)"
    
    
  }
  
  
  func exportNameForSequence(_ seq: Int) -> String {
    
    let sequence = self.sequenceName(seq)
    
    return "\(sequence) - \(self.createdDateFormatted)"
    
  }

  override func removeWithFiles() {

    if let file = self.imageFile {
      file.deleteFileData()
    }

    if let file = self.originalImageFile {
      file.deleteFileData()
    }

    super.removeWithFiles()

  }
  
  
  override class func registerSyncableData(_ converter: RemoteDataConverter) {
  
    converter.registerRemoteData("title", remote: "title", type: .String)
    converter.registerRemoteData("areaX", remote: "area_x", type: .Float)
    converter.registerRemoteData("areaY", remote: "area_y", type: .Float)
    converter.registerRemoteData("areaWidth", remote: "area_width", type: .Float)
    converter.registerRemoteData("areaHeight", remote: "area_height", type: .Float)
    
    converter.registerRemoteData("user", remote: "user", type: .User)
    
    converter.registerRemoteData("commentType", remote: "comment_type", type: .String)
    
    converter.registerRemoteData("cropData", remote: "crop", type: .Value)
    converter.registerRemoteData("rotationData", remote: "rotation", type: .Float)
    
    converter.registerRemoteData("imageFile", remote: "image", type: .Image)
    converter.registerRemoteData("originalImageFile", remote: "imageFile", type: .Image)
    
  }

  
  func savePhotoIfNeeded() {
    
    // TODO: Make this work
    if let project = self.issue?.area?.project {
      if let image = self.image {
        if project.photoAutoSave.boolValue == true {
          
          let img = image
          
          if project.photoEmbedPills.boolValue {
            UIImageWriteToSavedPhotosAlbum(self.renderCommentPhotoWithPill(nil, usePercentage: true)!, nil, nil, nil)
          } else {
            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
          }
        }
      }
    } else {
      Config.error("There's a comment floating around without an issue!")
    }
    
  }
  
  
  func renderCommentPhotoWithPill(_ inputSize: CGSize?, usePercentage: Bool, scaleFactor: CGFloat = 1) -> UIImage? {
   
    if self.image == nil {
      return nil
    }
    
    var img: UIImage?
    autoreleasepool() {
      
      let image = self.image!
      var resizedImage: UIImage!
      
      var size: CGSize!
      var height: CGFloat = Config.pillMetadataHeight
      
      if inputSize != nil {
        size = inputSize!
        resizedImage = self.resizeImage(image, maxHeight: size.height - height, maxWidth: size.width, scaleFactor: scaleFactor)
      } else {
        size = image.size
        resizedImage = image
        if usePercentage {
          height = 0.2 * size.height
        }
        size.height += height
      }
      
      var heightAdjust: CGFloat = 3
      if usePercentage {
        heightAdjust = 0
      }
      
      let centeredImage = CGRect(origin: CGPoint(x: (size.width - resizedImage.size.width) / 2, y: (size.height - resizedImage.size.height) - height + heightAdjust), size: resizedImage.size)
      
      var leftMargin: CGFloat = centeredImage.origin.x
      if leftMargin > 0.2 * size.width {
        leftMargin = 0.2 * size.width
      }
      
      if leftMargin < 2 {
        leftMargin = 2
      }
      
      let greyRect = CGRect(x: 0, y: size.height - height, width: size.width, height: height)
      let issueSize = 0.7 * height
      let issueDisp = (height - issueSize) / 2 - 1
//      let issueDisp = height / 8
      let issuePoint = CGPoint(x: greyRect.origin.x + issueSize/2 + leftMargin, y: greyRect.origin.y + issueDisp + issueSize/2)
      
      let titleSize = 0.2 * height
      let textMargin = 0.3 * titleSize
      let textStart = greyRect.origin.x + issueSize + issueDisp + leftMargin
      let textWidth = greyRect.width - textStart - leftMargin
      let titleRect = CGRect(x: textStart, y: greyRect.origin.y + issueDisp, width: textWidth, height: titleSize)
      
      let subtitleSize = 0.7 * titleSize
      let subtitleRect = CGRect(x: textStart, y: titleRect.origin.y + textMargin + titleSize, width: textWidth, height: subtitleSize * 2.3)
      
      // name and data
      let nameSize = subtitleSize
      
      
      UIGraphicsBeginImageContextWithOptions(size, false, scaleFactor)
      
      let context = UIGraphicsGetCurrentContext()
      
      
//      UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).setFill()
      UIColor.white.setFill()
      context?.fill(CGRect(origin: CGPoint.zero, size: size))
      
      // image
      resizedImage.draw(in: centeredImage)
      
      UIColor.black.setStroke()
      context?.stroke(CGRect(origin: CGPoint.zero, size: size))
      
      // issue number
      self.issue!.drawIssueLabelAtPoint(issuePoint, ofSize: issueSize)
      
      // tag title
      var paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .left
//      var textAttributes: [String: AnyObject] = [NSAttributedStringKey.font.rawValue: UIFont.systemFont(ofSize: titleSize)]
        // var textAttributes: NSAttributedStringKey = [NSAttributedStringKey.font.rawValue: UIFont.systemFont(ofSize: titleSize)]
        
        
        
      var textAttributes: [NSAttributedStringKey: Any] = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: titleSize)]

        
      textAttributes[NSAttributedStringKey.paragraphStyle] = paragraphStyle
      textAttributes[NSAttributedStringKey.backgroundColor] = UIColor.clear
      textAttributes[NSAttributedStringKey.foregroundColor] = UIColor.black
        (self.issue!.topLevelTagTitle as NSString).draw(in: titleRect, withAttributes: textAttributes)
        (self.issue!.topLevelTagTitle as NSString).draw(in: titleRect, withAttributes: textAttributes)
      
      // tag subtitle
      paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .left
      textAttributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: subtitleSize)]
      textAttributes[NSAttributedStringKey.paragraphStyle] = paragraphStyle
      textAttributes[NSAttributedStringKey.backgroundColor] = UIColor.clear
      textAttributes[NSAttributedStringKey.foregroundColor] = UIColor.black
      (self.issue!.formattedChildTitle as String).draw(in: subtitleRect, withAttributes: textAttributes)
      
      // name & date
      let subtitleMeasured = (self.issue!.formattedChildTitle as NSString).boundingRect(with: subtitleRect.size, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: textAttributes, context: nil)
      let nameAndDateRect = CGRect(x: textStart, y: subtitleRect.origin.y + fmin(subtitleMeasured.size.height, subtitleRect.size.height) + textMargin, width: textWidth, height: 1.5 * nameSize)
      
      paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .left
      textAttributes = [NSAttributedStringKey.font: UIFont.italicSystemFont(ofSize: nameSize)]
      textAttributes[NSAttributedStringKey.paragraphStyle] = paragraphStyle
      textAttributes[NSAttributedStringKey.backgroundColor] = UIColor.clear
      textAttributes[NSAttributedStringKey.foregroundColor] = UIColor.black
      
      let dateString = self.createdDateFormatted

      if let user = self.user, let username = user.username {
        let nameAndDate = username + " - " + dateString
        (nameAndDate as NSString).draw(in: nameAndDateRect, withAttributes: textAttributes)
      } else {
        Config.error("Found comment without username")
      }
      
      img = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
    }
    
    return img;
  }

  
  func resizeImage(_ image: UIImage, maxHeight: CGFloat, maxWidth: CGFloat, scaleFactor: CGFloat = 1) -> UIImage {
    
    let hScale = maxHeight / image.size.height
    let wScale = maxWidth / image.size.width
    let scale = min(hScale, wScale)
    
    let newWidth = image.size.width * scale
    let newHeight = image.size.height * scale
    UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, scaleFactor)
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }
  
  
}
