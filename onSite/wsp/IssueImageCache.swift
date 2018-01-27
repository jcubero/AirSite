//
//  IssueImageCache.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-03-02.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation


class IssueImageCache {
  
  let size: CGFloat
  let manager: Manager = Manager.sharedInstance
  
  var imageCache: [String: UIImage] = [:]
  
  init(project: Project) {
    
    self.size = Config.speedrackSize
    
  }
  
  
  func getImageWithShape(_ shape: String, color: UIColor, ofSize: CGFloat) -> UIImage {
    
    let key = "\(shape)-\(color.hexStringValue())-\(ofSize)"
    
    if let image = self.imageCache[key] {
      return image
    } else {
      
      let shapeImage = UIImage(named: shape)!
      let coloredImage = self.fillImageWithColor(shapeImage, size: size, color: color)
      
      self.imageCache[key] = coloredImage
      
      return coloredImage
      
    }
  }
  
  
  func fillImageWithColor(_ image: UIImage, size: CGFloat, color: UIColor) -> UIImage {
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
    let context = UIGraphicsGetCurrentContext()
    context?.clip(to: rect, mask: image.cgImage!)
    context?.setFillColor(color.cgColor)
    context?.fill(rect)
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return UIImage(cgImage: img!.cgImage!, scale: 0, orientation: .downMirrored)
  }
  
  
}
