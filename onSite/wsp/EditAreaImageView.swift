//
//  EditAreaImageView.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-07-28.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit
//import PEPhotoCropEditor

class EditAreaImageView: UIView {
  
  
  fileprivate var _rotation: CGFloat = 0
  fileprivate var _aspect: CGFloat = 4.0 / 3.0
  
  fileprivate var _origImage: UIImage!
  fileprivate var changed: Bool = false
  
  var image :UIImage {
    get {
      
      if self.imageView.userHasModifiedCropArea  || self.changed {
        return self.imageView.croppedImage
      } else {
        return self._origImage
      }
    }
    set {
      
      if newValue.size.height > newValue.size.width && self._aspect > 1 {
        self._aspect = 1 / self._aspect
      }
      
      if newValue.size.height / newValue.size.width != self._aspect {
        self._origImage = self.imageWithAspect(newValue, aspect: self._aspect)
      } else {
        self._origImage = newValue
      }
      
      self.imageView.image = self._origImage
      self.imageView.cropAspectRatio = self.cropAspectRatio
    }
  }

  var rotation: CGFloat {
    get {
      return self._rotation
    }
    set {
      self.changed = true
      self._rotation += newValue
      self.imageView.setRotationAngle(self._rotation, snap: false)
      
    }
  }
  
  
  var cropAspectRatio: CGFloat {
    get {
      return self._aspect
    }
    set {
      self.changed = true
      self._aspect = newValue
      self.imageView!.image = self.imageWithAspect(self._origImage, aspect: newValue)
      self.imageView!.cropAspectRatio = newValue
      self._rotation = 0
    }
  }
  
  var cropRect: CGRect {
    get {
      return self.imageView.cropRect
    }
  }
  
  var imageHasChanged: Bool {
    get {
      return self.imageView.userHasModifiedCropArea  || self.changed
    }
  }
  
  
  weak var imageView: PECropView!
  
  required init?(coder aDecoder: NSCoder) {
    
    super.init(coder: aDecoder)
    
    self.clipsToBounds = true
    
    let cropView =  PECropView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
    cropView.backgroundColor = UIColor.white
    cropView.cropAspectRatio = 4.0 / 3.0
    cropView.keepingCropAspectRatio = true
    self.imageView = cropView
    
    self.addSubview(self.imageView!)
    
    Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(EditAreaImageView.resetCrop), userInfo: nil, repeats: false)
  
  }
  
  @objc func resetCrop() {
    
    self.imageView.cropAspectRatio = self.cropAspectRatio
    self.imageView.keepingCropAspectRatio = true
    
    
  }
  
  func imageWithAspect(_ image: UIImage, aspect: CGFloat) -> UIImage {
    
    var centeredImage: UIImage!
    autoreleasepool() {
      
      let imageAspect = image.size.width /  image.size.height
      
      var size = CGSize.zero
      if imageAspect > aspect {
        size = CGSize(width: image.size.width, height: image.size.width / aspect)
      } else {
        size = CGSize(width: image.size.height * aspect, height: image.size.height)
      }
      
      UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
      let context = UIGraphicsGetCurrentContext();
      
      context?.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0);
      context?.fill(CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height));
      
      var x:CGFloat = 0
      var y:CGFloat = 0
      y = (size.height - image.size.height) / 2
      x = (size.width - image.size.width) / 2
      image.draw(in: CGRect(x: x, y: y, width: image.size.width, height: image.size.height))
      
      centeredImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
    }
    
    return centeredImage
    
  }
  
  
}


