//
//  PDFPage.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-11-02.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import Foundation

class PDFPage {
  
  static let dpi: CGFloat = 72
  var width: CGFloat = 8.5 * 72
  var height: CGFloat =  11 * 72
  
  var topMargin: CGFloat = 72 * 1
  var bottomMargin: CGFloat = 72 * 0.75
  var leftMargin: CGFloat = 72 * 0.375
  var rightMargin: CGFloat = 72 * 0.375


  var marginWidth: CGFloat {
    get {
      return self.width - self.leftMargin - self.rightMargin
    }
  }
  
  var marginHeight: CGFloat {
    get {
      return self.height - self.topMargin - self.bottomMargin
    }
  }
  
  
  static func reportFontOfSize(_ size: CGFloat) -> UIFont {
    
    return UIFont(name: "HelveticaNeue", size: size)!
    
  }
  
  static func reportLightFontOfSize(_ size: CGFloat) -> UIFont {
    
    return UIFont(name: "HelveticaNeue-Light", size: size)!
    
  }
  
  static func reportBoldFontOfSize(_ size: CGFloat) -> UIFont {
    
    return UIFont(name: "HelveticaNeue-Bold", size: size)!
    
  }
  
  static func reportItalicFontOfSize(_ size: CGFloat) -> UIFont {
    
    return UIFont(name: "HelveticaNeue-Italic", size: size)!
    
  }
  
  
  func newPage(_ area: Area, project: Project, currentPage: Int)  {
   
    
    UIGraphicsBeginPDFPageWithInfo(CGRect(x: 0, y: 0, width: self.width, height: self.height), nil)
    self.drawHeader(currentPage, area: area, project: project)

    self.drawFooter(currentPage)
    self.drawBottomImage()
    
    let status = "Creating page \(currentPage)"
    Manager.sharedInstance.updateStatus(status)
    
  }
  
  func newBlankPage() {
    UIGraphicsBeginPDFPageWithInfo(CGRect(x: 0, y: 0, width: self.width, height: self.height), nil)
    self.drawBottomImage()
    
  }
  
  func newNumberedPage(_ currentPage: Int) {
    UIGraphicsBeginPDFPageWithInfo(CGRect(x: 0, y: 0, width: self.width, height: self.height), nil)
    
    self.drawFooter(currentPage)
    let status = "Creating page \(currentPage)"
    Manager.sharedInstance.updateStatus(status)
    
  }
  
  func drawHeader(_ page: Int, area: Area, project: Project) {
    
    let headerFontSize: CGFloat = 12
    let areaFontSize: CGFloat = 12
    let topContainer: CGFloat = 0.25 * PDFPage.dpi
    
    let headerSpacing: CGFloat = headerFontSize * 0.1
    
    let largestWidth = 8.5 * PDFPage.dpi - self.rightMargin - self.leftMargin
    
    
    // projectTitle
    let titleString = project.nonEmptyProjectTitle.uppercased() as NSString
    let font = PDFPage.reportLightFontOfSize(headerFontSize)
    let attributes = [
      NSAttributedStringKey.font: font,
      NSAttributedStringKey.foregroundColor: PDFTitlePageColor
    ]
    
    let stringRect = CGRect(x: self.leftMargin, y: topContainer, width: largestWidth, height: 2.4 * headerFontSize)
    titleString.draw(in: stringRect, withAttributes: attributes)
    
    let areaString = area.title.uppercased() as NSString
    let areaFont = PDFPage.reportLightFontOfSize(areaFontSize)
    let areaAttributes = [
      NSAttributedStringKey.font: areaFont,
      NSAttributedStringKey.foregroundColor: PDFSubtitleColor
    ]
    
    let areaRect = CGRect(x: self.leftMargin, y: topContainer + 2.4 * headerFontSize + headerSpacing, width: largestWidth, height: areaFontSize * 1.2)
    areaString.draw(in: areaRect, withAttributes: areaAttributes)
    
  }
  
  func drawFooter(_ page: Int) {
    
    let pageString = ( "Page " + String(page) ) as NSString
    let font = PDFPage.reportFontOfSize(9)
    let attributes = [
      NSAttributedStringKey.font: font,
      NSAttributedStringKey.foregroundColor: UIColor(netHex: 0x777777)
    ]
    let clippedSize = pageString.size(withAttributes: attributes)
    
    let stringRect = CGRect(x: self.marginWidth - clippedSize.width + self.leftMargin, y: self.height - self.bottomMargin + 6, width: clippedSize.width, height: clippedSize.height)
    
    pageString.draw(in: stringRect, withAttributes: attributes)
    
    
  }
  
  func drawBottomImage() {
    
    let image = self.resizeImage(UIImage(named: "report-footer-logo")!, maxHeight: self.bottomMargin - 20, maxWidth:3 * 72)
    let rect = CGRect(x: self.leftMargin, y: self.height - self.bottomMargin + 6, width: image.size.width, height: image.size.height)
    image.draw(in: rect)
    
  }
  
  func resizeImage(_ image: UIImage, maxHeight: CGFloat, maxWidth: CGFloat) -> UIImage {
    
    let hScale = maxHeight / image.size.height
    let wScale = maxWidth / image.size.width
    let scale = min(hScale, wScale)
    
    let newWidth = image.size.width * scale
    let newHeight = image.size.height * scale
    
    UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, 300/72)
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }
  
}
