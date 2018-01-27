//
//  PDFCoverPage.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-03-14.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation

extension PDFExport {
  
  func renderSecondPage(_ page: PDFPage) {
    self.drawCoverPage(page, withImage: false)
  }
  
  func renderCoverPage(_ page: PDFPage) {
    
    self.drawCoverPage(page, withImage: true)
    
  }
  
  func drawCoverPage(_ page: PDFPage, withImage: Bool) {
  
    page.newBlankPage()
    
    let green = PDFTitlePageColor
    
    let image = self.renderRightImage(withImage)
    image.draw(in: CGRect(x: 0, y: 175, width: image.size.width / 300 * 72 ,  height: image.size.height / 300 * 72))
    
    var location = CGPoint(x: 275, y: 175)
    var maxWidth: CGFloat = 293
    var height: CGFloat = 0
    
    height = self.drawText(self.project.nonEmptyProjectTitle.uppercased(), usingFontSize: 18, atLocation: location, maxLines: 3, maxWidth: maxWidth, bold: false, color: green)
    var margin: CGFloat = 6
    location.y += height + margin
    
    height = self.drawText(self.project.client.uppercased(), usingFontSize: 14, atLocation: location, maxLines: 3, maxWidth: maxWidth, bold: false, color: green)
    margin = 4
    location.y += height + margin
    
    self.drawText(self.project.subtitle, usingFontSize: 10, atLocation: location, maxLines: 1, maxWidth: maxWidth, bold: true)
    
    
    
    location = CGPoint(x: 275, y: 330)
    
    height = self.drawText(self.project.buildingName.uppercased(), usingFontSize: 14, atLocation: location, maxLines: 2, maxWidth: maxWidth, bold: true)
    margin = 4
    location.y += height + margin
    
    self.drawText(self.project.buildingAddress, usingFontSize: 10, atLocation: location, maxLines: 2, maxWidth: maxWidth, bold: true)
    
    
    maxWidth = 298
    location = CGPoint(x: 270, y: 389)
    
    height = self.drawText(self.project.documentType, usingFontSize: 10, atLocation: location, maxLines: 1, maxWidth: maxWidth, bold: true)
    margin = 10
    location.y += height + margin
    height = self.drawText("Projet No: " + self.project.projectNumber, usingFontSize: 10, atLocation: location, maxLines: 1, maxWidth: maxWidth, bold: false)
    margin = 0
    location.y += height + margin
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    var date = dateFormatter.string(from: Date()) as NSString
    if let d = self.project.date {
      date = d as NSString
    }
    height = self.drawText("Date: " + (date as String), usingFontSize: 10, atLocation: location, maxLines: 1, maxWidth: maxWidth, bold: false)
    margin = 0
    location.y += height + margin
    self.drawText("Préparé par: " + self.project.userNameForReport, usingFontSize: 10, atLocation: location, maxLines: 1, maxWidth: maxWidth, bold: false)
    
    
    location = CGPoint(x: 270, y: 533)
    height = self.drawText(self.project.userCompanyForReport, usingFontSize: 10, atLocation: location, maxLines: 1, maxWidth: maxWidth, bold: true)
    margin = 0
    location.y += height + margin
    height = self.drawText(self.project.userCompanyAddress1, usingFontSize: 10, atLocation: location, maxLines: 1, maxWidth: maxWidth, bold: false)
    location.y += height + margin
    height = self.drawText(self.project.userCompanyAddress2, usingFontSize: 10, atLocation: location, maxLines: 1, maxWidth: maxWidth, bold: false)
    margin = 10
    location.y += height + margin
    height = self.drawText("Téléphone: " + self.project.userCompanyPhone, usingFontSize: 10, atLocation: location, maxLines: 1, maxWidth: maxWidth, bold: false)
    margin = 0
    location.y += height + margin
    height = self.drawText("Télécopieur: " + self.project.userCompanyFax, usingFontSize: 10, atLocation: location, maxLines: 1, maxWidth: maxWidth, bold: false)
    location.y += height + margin
    height = self.drawText(self.project.userCompanyEmail, usingFontSize: 10, atLocation: location, maxLines: 1, maxWidth: maxWidth, bold: false)
    location.y += height + margin
    
    
    let context = UIGraphicsGetCurrentContext()
    
    context?.setLineWidth(0.7)
    context?.beginPath()
    
    context?.setStrokeColor(green.cgColor)
    context?.move(to: CGPoint(x: 270, y: 525))
    context?.addLine(to: CGPoint(x: 276, y: 525))
    context?.strokePath()
    
    
    
    if let image = self.project.buildingImage {
      self.drawBottomRightImage(page, image: image)
    } else {
      let image = UIImage(named: "Logo")!
      self.drawBottomRightImage(page, image: image)
      
    }
    
  }
  
  
  
  func drawText(_ input: String, usingFontSize: CGFloat, atLocation: CGPoint, maxLines: Int, maxWidth: CGFloat, bold: Bool, color: UIColor = UIColor.black) -> CGFloat {
    
    let string = input as NSString
    
    var font = PDFPage.reportFontOfSize(usingFontSize)
    if bold {
      font = PDFPage.reportBoldFontOfSize(usingFontSize)
    }
    
    var attributes = self.attributesWithFont(font, alignment: .left)
    attributes[NSAttributedStringKey.foregroundColor] = color
    let unboundedSize = CGSize(width: maxWidth, height: 1.5 * CGFloat(maxLines) * usingFontSize)
    let boundedTitleSize = string.boundingRect(with: unboundedSize, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
    
    string.draw(in: CGRect(origin: atLocation, size: unboundedSize), withAttributes: attributes)
    
    return boundedTitleSize.height
    
  }
  
  func renderRightImage(_ usingImage: Bool) -> UIImage {
    
    let topImage = self.fillImageWithColor("top-report-mask", color: PDFTitlePageColor)
    let topImageRect = CGRect(origin: CGPoint(x: 0, y: 0), size: topImage.size)
    
    var bottomImage: UIImage!
    if let image = self.project.image, usingImage {
      bottomImage = self.fillImageWithImage("bottom-report-mask", fillingImage: image)
    } else {
      bottomImage = self.fillImageWithColor("bottom-report-mask", color: PDFSubtitleColor)
    }
    let bottomImageRect = CGRect(origin: CGPoint(x: 0, y: 831), size: bottomImage.size)
    
    
    let rect = CGRect(x: 0, y: 0, width: 912, height: 1831)
    
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
    let context = UIGraphicsGetCurrentContext()
    
   
    context?.draw(topImage.cgImage!, in: topImageRect)
    context?.setBlendMode(CGBlendMode.multiply)
    context?.draw(bottomImage.cgImage!, in: bottomImageRect)
    
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return img!
    
  }
  
  
  func drawBottomRightImage(_ page: PDFPage, image: UIImage) {
    
    let image = self.resizeImage(image, maxHeight: page.bottomMargin - 20, maxWidth:3 * 72)
    let rect = CGRect(x: page.width - page.rightMargin - image.size.width, y: page.height - page.bottomMargin + 6, width: image.size.width, height: image.size.height)
    image.draw(in: rect)
    
  }
  
  
  
  func fillImageWithColor(_ imageName: String, color: UIColor) -> UIImage {
    
    let image = UIImage(named: imageName)!
    
    let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
    let context = UIGraphicsGetCurrentContext()
    
    context?.clip(to: rect, mask: image.cgImage!)
    context?.setFillColor(color.cgColor)
    context?.fill(rect)
    
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return img!
  }
  
  
  func fillImageWithImage(_ imageName: String, fillingImage: UIImage) -> UIImage {
    
    let image = UIImage(named: imageName)!
    
    let resizedImage = self.resizeImage(fillingImage, minHeight: image.size.height, minWidth: image.size.width)
    
    var adjustWidth: CGFloat = 0
    if resizedImage.size.width > image.size.width {
      adjustWidth = (resizedImage.size.width - image.size.width) / 2
    }
    var adjustHeight: CGFloat = 0
    if resizedImage.size.height > image.size.height {
      adjustHeight = (resizedImage.size.height - image.size.height) / 2
    }
    
    let resizeImageRect = CGRect(origin: CGPoint(x: -adjustWidth, y: -adjustHeight), size: resizedImage.size)
    
    let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
    let context = UIGraphicsGetCurrentContext()
    
    context?.clip(to: rect, mask: image.cgImage!)
    
    context?.draw(resizedImage.cgImage!, in: resizeImageRect)
    
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return img!
  }
  
  
}
