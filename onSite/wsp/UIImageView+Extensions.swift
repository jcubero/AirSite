//
//  UIImageView+Extensions.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-09-29.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation

extension UIImageView {
  func fillWithColor(_ color: UIColor) {
    let rect = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
    let context = UIGraphicsGetCurrentContext()
    context?.clip(to: rect, mask: (self.image?.cgImage)!)
    context?.setFillColor(color.cgColor)
    context?.fill(rect)
    var img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    img = UIImage(cgImage: (img?.cgImage!)!, scale: 0, orientation: .downMirrored)
    self.image = img
  }
}
