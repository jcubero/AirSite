//
//  UIBezierPath+Extensions.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-09-29.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation

extension UIBezierPath {
  
  class func getAxisAlignedArrowPoints(_ points: inout Array<CGPoint>, forLength: CGFloat, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat ) {
    
    let tailLength = forLength - headLength
    points.append(CGPoint(x: 0, y: tailWidth/2))
    points.append(CGPoint(x: tailLength, y: tailWidth/2))
    points.append(CGPoint(x: tailLength, y: headWidth/2))
    points.append(CGPoint(x: forLength, y: 0))
    points.append(CGPoint(x: tailLength, y: -headWidth/2))
    points.append(CGPoint(x: tailLength, y: -tailWidth/2))
    points.append(CGPoint(x: 0, y: -tailWidth/2))
    
  }
  
  
  class func transformForStartPoint(_ startPoint: CGPoint, endPoint: CGPoint, length: CGFloat) -> CGAffineTransform{
    let cosine: CGFloat = (endPoint.x - startPoint.x)/length
    let sine: CGFloat = (endPoint.y - startPoint.y)/length
    
    return CGAffineTransform(a: cosine, b: sine, c: -sine, d: cosine, tx: startPoint.x, ty: startPoint.y)
  }
  
  
    class func bezierPathWithArrowFromPoint(startPoint:CGPoint, endPoint: CGPoint, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat) -> UIBezierPath {
        
        let xdiff: Float = Float(endPoint.x) - Float(startPoint.x)
        let ydiff: Float = Float(endPoint.y) - Float(startPoint.y)
        let length = hypotf(xdiff, ydiff)
        
        var points = [CGPoint]()
        self.getAxisAlignedArrowPoints(&points, forLength: CGFloat(length), tailWidth: tailWidth, headWidth: headWidth, headLength: headLength)
        
        var transform: CGAffineTransform = self.transformForStartPoint(startPoint, endPoint: endPoint, length:  CGFloat(length))

        let path = CGMutablePath()
        path.addLines(between:points)
        path.closeSubpath()
        
        let uiPath: UIBezierPath = UIBezierPath(cgPath:path)
        return uiPath
    }
}
