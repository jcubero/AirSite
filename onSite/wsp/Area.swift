//
//  Area.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-06-26.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord
import PromiseKit

@objc(Area)

class Area: SyncableModel {
  
  // properties
  
  @NSManaged var title: String
  @NSManaged var order: NSNumber?
  
  
  @NSManaged var cropData: NSValue?
  @NSManaged var rotationData: NSNumber?
  
 
  // relationships
  @NSManaged var project: Project?
  @NSManaged var issues: NSSet?
  @NSManaged var imageFile: File?
  @NSManaged var originalImageFile: File?
  
  // images
  var image: UIImage? { get {
    return self.imageFile?.image
    } set {
      let imageFile = self.makeFile("imageFile", project: self.project!)
      imageFile.image = newValue
    }
  }
  
  var imageData: Data? { get {
    return self.imageFile?.imageData as! Data
    } set {
      let imageFile = self.makeFile("imageFile", project: self.project!)
      imageFile.imageData = newValue
    }}
  
  var imagePath: URL? { get { return self.imageFile?.path as! URL } }
  
  var originalImageData: Data? { get {
    return self.originalImageFile?.imageData as! Data
    } set {
      let imageFile = self.makeFile("originalImageFile", project: self.project!)
      imageFile.imageData = newValue
    }}
  
  
  var filename: String {
    get {
      return "\(self.title).jpg"
    }
  }

  func setImageDataInContext(_ imageData: Data, context: NSManagedObjectContext) {
    
      let imageFile = self.makeFile("imageFile", project: self.project!, inContext: context)
      imageFile.imageData = imageData
    
  }
  
  func nextOrder(_ inContext: NSManagedObjectContext? = nil) -> Int {
    let context = inContext == nil ? NSManagedObjectContext.mr_default() : inContext!
    guard let areas = Area.mr_find(byAttribute: "project", withValue: self.project!, in: context) as? [Area] else {
      return 1
    }
    var topOrder = 0
    for area in areas {
      if let order = area.order {
        topOrder = max(topOrder, order.intValue)
      }
    }
    return topOrder + 1
  }
  
  var imageSize: CGSize {
    guard let image = self.image else {
      return CGSize.zero
    }
    
    return image.size
  }
  
  func issuePositionInArea(_ pos: CGPoint) -> CGPoint {
    var pos = pos
    
    let size = self.imageSize
    
    if pos.x < 0 {
      pos.x = 0
    }
    
    if pos.x > size.width {
      pos.x = size.width
    }
    
    if pos.y < 0 {
      pos.y = 0
    }
    
    if pos.y > size.height {
      pos.y = size.height
    }
    
    return pos
    
  }
  
  func positionInArea(_ pos: CGPoint) -> Bool {
    
    let size = self.imageSize
    var result = true
    
    if pos.x < 0 {
      result = false
    }
    
    if pos.x > size.width {
      result = false
    }
    
    if pos.y < 0 {
      result = false
    }
    
    if pos.y > size.height {
      result = false
    }
    
    return result
    
    
  }

  func importInitialImageToArea(_ data: Data) {

    autoreleasepool { 
      guard let image = UIImage(data: data) else {
        Config.error()
        return
      }
      
      let margin = image.size.width * 0.2
      let canvasSize = CGSize(width: image.size.width + (2 * margin), height: image.size.height + (2 * margin))
      
      
      UIGraphicsBeginImageContextWithOptions(canvasSize, true, 1.0)
      let context = UIGraphicsGetCurrentContext();
      
      context?.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0);
      context?.fill(CGRect(x: 0.0, y: 0.0, width: canvasSize.width, height: canvasSize.height));
      
      image.draw(in: CGRect(x: margin, y: margin, width: image.size.width, height: image.size.height))
      
      let centeredImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      
      let imageData = UIImageJPEGRepresentation(centeredImage!, Project.areaPhotoQuality)
      
      self.originalImageData = imageData
      self.imageData = imageData
    }

  }

  override func removeWithFiles() {

    self.imageFile?.deleteFileData()
    self.originalImageFile?.deleteFileData()

    guard let c = self.issues else {
      return
    }

    for issue in c.allObjects as! [Issue] {
      issue.removeWithFiles()
    }

    super.removeWithFiles()

  }


  override class func registerSyncableData(_ converter: RemoteDataConverter) {
  
    
    converter.registerRemoteData("title", remote: "title", type: .String)
    converter.registerRemoteData("order", remote: "order", type: .Integer)
    
    converter.registerRemoteData("cropData", remote: "crop", type: .Value)
    converter.registerRemoteData("rotationData", remote: "rotation", type: .Float)
    
    converter.registerRemoteData("imageFile", remote: "image", type: .Image)
    converter.registerRemoteData("originalImageFile", remote: "imageFile", type: .Image)
    
    converter.registerRemoteData("issues", remote: "issues", type: .Entities, entity: "Issue", unit: .Separate)
    
  }


}
