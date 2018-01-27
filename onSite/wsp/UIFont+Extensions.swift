//
//  UIFont+Extensions.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-09-29.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation

extension UIFont {
  
  static func materialIconsOfSize(_ size: CGFloat) -> UIFont {
    return UIFont(name: "MaterialIcons-Regular", size: size)!
  }
  
  func sizeOfString (_ string: String, constrainedToWidth width: CGFloat) -> CGSize {
    return (string as NSString).boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
      options: NSStringDrawingOptions.usesLineFragmentOrigin,
      attributes: [NSAttributedStringKey.font: self],
      context: nil).size
  }


  var isItalic: Bool {
    return fontDescriptor.symbolicTraits.contains(.traitItalic)
  }

  func setItalic() -> UIFont {
    if isItalic {
      return self
    } else {
      var symTraits = fontDescriptor.symbolicTraits
      symTraits.insert([.traitItalic])
      let fontDescriptorVar = fontDescriptor.withSymbolicTraits(symTraits)
      return UIFont(descriptor: fontDescriptorVar!, size: 0)
    }
  }
  
  func removeItalic()-> UIFont {
    if !isItalic {
      return self
    } else {
      var symTraits = fontDescriptor.symbolicTraits
      symTraits.remove([.traitItalic])
      let fontDescriptorVar = fontDescriptor.withSymbolicTraits(symTraits)
      return UIFont(descriptor: fontDescriptorVar!, size: 0)
    }
  }
}
