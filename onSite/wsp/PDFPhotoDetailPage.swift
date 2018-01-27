//
//  PDFPhotoDetailPage.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-08-16.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation



extension PDFExport {

  

  func renderPhotoDetailPage(_ page: PDFPage) {
    
    var predicate = NSPredicate(format: "area.project = %@", project)
    if let p = self.filterPredicate {
      predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, p])
    }
    
    
    var issues = Issue.mr_findAllSorted(by: "issueNumber", ascending: true, with: predicate, in: self.currentManagedObjectContext) as! [Issue]
    if issues.count == 0 {
      return
    }
    
    var y: CGFloat = 0
    var minHeight: CGFloat = 0
    var firstItem = true

    issues.sort { (i1, i2) -> Bool in
      guard let num1 = i1.issueNumber else {
        return false
      }
      guard let num2 = i2.issueNumber else {
        return false
      }
      guard let n1 = Int(num1) else {
        return false
      }
      guard let n2 = Int(num2) else {
        return false
      }
      
      return n1 < n2
    }
    
    for issue in issues {
      
      let commentPredicate = NSPredicate(format: "issue = %@ and imageFile != nil", issue)
      
      guard let comments = Comment.mr_findAllSorted(by: "createdDate", ascending: true, with: commentPredicate, in: self.currentManagedObjectContext) as? [Comment] else {
        Config.error()
        continue
      }
      
      for (index, comment) in comments.enumerated() {
        
        if firstItem {
          y = self.drawNewDetailPage(page)
          minHeight = CGFloat(floor((page.height - y - (3 * self.detailItemMargin) - page.bottomMargin) / 3))
          firstItem = false
        }
        
        let minIssueRect = CGRect(x: page.leftMargin, y: y + detailItemMargin, width: page.marginWidth, height: minHeight)
        y = self.drawPhotoDetail(comment, withIndex: index + 1, inRect: minIssueRect, usingPage: page)
        
      }
    }
  }
  
  
  
  
  func drawPhotoDetail(_ comment: Comment, withIndex: Int, inRect: CGRect, usingPage page: PDFPage) -> CGFloat {
    
    var rect = inRect
    
    if inRect.origin.y + inRect.size.height > page.height - page.bottomMargin {
      rect.origin.y = self.drawNewDetailPage(page) + detailItemMargin
    }
    
    let leftWidth = CGFloat(floor(rect.width / 2) + 20)
    let height: CGFloat = 30
    
    let tagTitleRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: leftWidth / 2, height: height)
    self.drawDetailItem(tagTitleRect, title: "No:", value: comment.sequenceName(withIndex), alignment: .left)
    
    let photoDateRect = CGRect(x: rect.origin.x + leftWidth / 2, y: rect.origin.y, width: leftWidth / 2, height: height)
    var y = self.drawDetailItem(photoDateRect, title: "Date:", value: comment.createdDateFormatted, alignment: .left)
    
    let planName = CGRect(x: rect.origin.x, y: y, width: leftWidth, height: height)
    y = self.drawDetailItem(planName, title: "Plan:", value: comment.issue!.area!.title, alignment: .left)
    
    
    var tagRect = CGRect(x: rect.origin.x, y: y, width: leftWidth, height: height)
    
    var maxHeight: CGFloat = page.height - y - page.bottomMargin
    var remaining = ""
    (y, remaining) = self.drawDetailVariableItem(tagRect, title: "Description:", value: comment.issue!.formattedTagsList, maxHeight: maxHeight)
    tagRect.size.height = tagRect.origin.y - y
    self.outlineRect(tagRect)
    
    
    var drawImage = true
    if remaining != ""  || (page.height - y - page.bottomMargin) < height {
      
      rect.size.height = y - rect.origin.y
      self.drawImageInDetailPage(rect, leftWidth: leftWidth, comment: comment)
      drawImage = false
      
      rect.origin.y = self.drawNewDetailPage(page) + detailItemMargin
      y = rect.origin.y
      maxHeight = page.height - y - page.bottomMargin
      rect = CGRect(x: rect.origin.x, y: y, width: rect.width, height: height)
      
      if remaining != "" {
        tagRect = rect
        tagRect.size.width = leftWidth
        (y, _) = self.drawDetailVariableItem(tagRect, title: "Description (continué):", value: remaining, maxHeight: maxHeight)
        
        tagRect.size.height = tagRect.origin.y - y
        self.outlineRect(tagRect)
      }
      
    }
    
    let minHeight = max(rect.size.height - (y - rect.origin.y), height)
    var commentRect = CGRect(x: rect.origin.x, y: y, width: leftWidth, height: minHeight)
    let comments = comment.title == nil ? "" : comment.title!
    
    maxHeight = page.height - y - page.bottomMargin
    remaining = ""
    (y, remaining) = self.drawDetailVariableItem(commentRect, title: "Commentaires:", value: comments, maxHeight: maxHeight)
    
    rect.size.height = y - rect.origin.y
    
    
    // see if we should take the rest of the page
    if page.height - page.bottomMargin - (rect.origin.y + rect.height) - detailItemMargin < inRect.height {
      rect.size.height = page.height - page.bottomMargin - rect.origin.y
    }
    
    commentRect.size.height = rect.size.height - (commentRect.origin.y - rect.origin.y)
    self.outlineRect(commentRect)
    
    
    // draw the image
    if drawImage {
      self.drawImageInDetailPage(rect, leftWidth: leftWidth, comment: comment)
      
    } else {
      
      let sideRect = CGRect(x: rect.origin.x + leftWidth, y: rect.origin.y, width: rect.size.width - leftWidth, height: y - rect.origin.y)
      self.outlineRect(sideRect)
      
    }
    
    if remaining != "" {
      rect.origin.y = self.drawNewDetailPage(page) + detailItemMargin
      y = rect.origin.y
      maxHeight = page.height - y - page.bottomMargin
      
      var continuedRect = CGRect(x: rect.origin.x, y: y, width: leftWidth, height: height)
      
      (y, _) = self.drawDetailVariableItem(continuedRect, title: "Commentaires (continué):", value: remaining, maxHeight: maxHeight)
      continuedRect.size.height = y - continuedRect.origin.y
      self.outlineRect(continuedRect)
      
      let sideRect = CGRect(x: rect.origin.x + leftWidth, y: rect.origin.y, width: rect.size.width - leftWidth, height: y - rect.origin.y)
      self.outlineRect(sideRect)
      
      rect.size.height = y - rect.origin.y
      
    }
    
    
    return rect.origin.y + rect.size.height
  }
  
  func drawImageInDetailPage(_ rect: CGRect, leftWidth: CGFloat, comment: Comment)  {
    
    let imageRect = CGRect(x: rect.origin.x + leftWidth, y: rect.origin.y, width: rect.size.width - leftWidth, height: rect.size.height)
    self.outlineRect(imageRect)
    
    let imageDrawRect = imageRect.insetBy(dx: self.detailItemMargin, dy: self.detailItemMargin)
    
    guard let commentImage = comment.image else {
      Config.warn("Trying to draw comment in photo detail page with no image")
      return
    }
    let image = comment.resizeImage(commentImage, maxHeight: imageDrawRect.height, maxWidth: imageDrawRect.width, scaleFactor: 300 / PDFPage.dpi)
    
    let newRect = CGRect(origin: CGPoint(x: imageDrawRect.origin.x + (imageDrawRect.width - image.size.width) / 2, y: imageDrawRect.origin.y + (imageDrawRect.height - image.size.height) / 2), size: image.size)
    
    image.draw(in: newRect)
    
  }
  
  
  func drawNewDetailPage(_ page: PDFPage) -> CGFloat {
    
    page.newNumberedPage(self.currentPage)
    self.currentPage += 1
    
    return self.drawDetailHeader(page)
    
    
  }
  
  
  func drawDetailHeader(_ page: PDFPage) -> CGFloat {
    
    let height: CGFloat = 30
    
    let titleRect = CGRect(x: page.leftMargin, y: page.topMargin, width: page.marginWidth, height: height)
    self.drawDetailHeaderTitle(titleRect)
    
    var top = titleRect.origin.y + titleRect.size.height
    let outline = CGRect(x: page.leftMargin, y: top, width: page.marginWidth, height: 2)
    self.outlineRect(outline)
    
    top = outline.origin.y + outline.size.height
    
    let projectRect = CGRect(x: page.leftMargin, y: top, width: page.marginWidth / 2, height: height)

    self.outlineRect(CGRect(x: page.leftMargin, y: top, width: page.marginWidth, height: height))
    self.drawDetailItemNoRect(projectRect, title: nil, value: project.nonEmptyProjectTitle, alignment: .left)
    
    var left = projectRect.origin.x + projectRect.size.width
    let contractRect = CGRect(x: left, y: top, width: page.marginWidth / 2, height: height)

    var text = project.subtitle
    if text == "" {
      text = project.projectNumber
    } else if project.projectNumber != "" {
      text += " - \(project.projectNumber)"
    }
    top = self.drawDetailItemNoRect(contractRect, title: nil, value: text, alignment: .left)
    

    text = project.buildingName
    if text == "" {
      text = project.buildingAddress
    } else if project.buildingAddress != "" {
      text += " - \(project.buildingAddress)"
    }


    left = projectRect.origin.x
    let descRect = CGRect(x: left, y: top, width: page.marginWidth, height: height)
    self.drawDetailItem(descRect, title: nil, value: text, alignment: .left)
    
    return descRect.origin.y + descRect.size.height
    
    
  }
  
  func drawDetailHeaderTitle(_ rect: CGRect) {
    
    let height = rect.height
    let textRect = rect.insetBy(dx: height / 3, dy: height / 3)
    
    self.outlineRect(rect)
    
    let clientFontSize = height * 0.2
    let textAttributes = self.attributesWithFont(PDFPage.reportBoldFontOfSize(clientFontSize + 2), alignment: .left)
    let clientName  = project.documentType.uppercased()
    let unboundedSize = textRect.size
    var boundedSize = clientName.boundingRect(with: unboundedSize, options: .usesLineFragmentOrigin, attributes: textAttributes, context: nil)
    boundedSize.origin = textRect.origin
    boundedSize.origin.y = textRect.origin.y + (textRect.height - clientFontSize) / 2
    clientName.draw(in: boundedSize, withAttributes: textAttributes)
    

  }
  


  func drawDetailItem(_ rect: CGRect, title: String?, value: String, alignment: NSTextAlignment) -> CGFloat {
    
    self.outlineRect(rect)
    return drawDetailItemNoRect(rect, title: title, value: value, alignment: alignment)
    
  }

  func drawDetailItemNoRect(_ rect: CGRect, title: String?, value: String, alignment: NSTextAlignment) -> CGFloat {

    let valueSize: CGFloat = 8
    let titleSize: CGFloat = 4
    
    let topMargin: CGFloat = 5
    let leftMargin: CGFloat = 5
    
    let titleInset = rect.insetBy(dx: topMargin, dy: leftMargin)

    var verticalAdjust: CGFloat = 0

    if let title = title {
      let titleAttributes = self.attributesWithFont(PDFPage.reportFontOfSize(titleSize), alignment: .left)
        title.uppercased().draw(in: titleInset, withAttributes: titleAttributes)
      verticalAdjust = 2
    }

    var valueInset = titleInset
    valueInset.size.height = valueSize * 2.5
    let valueAttributes = self.attributesWithFont(PDFPage.reportFontOfSize(valueSize), alignment: alignment)
    let size = (value as NSString).boundingRect(with: valueInset.size, options: .usesLineFragmentOrigin, attributes: valueAttributes, context: nil)

    valueInset.origin.y = valueInset.origin.y + (valueInset.size.height - size.height) / 2 + verticalAdjust
    value.draw(in: valueInset, withAttributes: valueAttributes)
    
    return rect.origin.y + rect.size.height

  }

  func drawDetailVariableItem(_ rect: CGRect, title: String, value: String, maxHeight: CGFloat) -> (CGFloat, String) {
    
    var rect = rect
    let valueSize: CGFloat = 8
    let titleSize: CGFloat = 4
    
    let topMargin: CGFloat = 5
    let leftMargin: CGFloat = 5
    
    let titleInset = rect.insetBy(dx: topMargin, dy: leftMargin)
    let titleAttributes = self.attributesWithFont(PDFPage.reportFontOfSize(titleSize), alignment: .left)
    title.uppercased().draw(in: titleInset, withAttributes: titleAttributes)
    
    let valueTop = titleInset.origin.y + 2 * titleSize
    
    var v = value.strip()
    var r = ""
    
    let valueAttributes = self.attributesWithFont(PDFPage.reportFontOfSize(valueSize), alignment: .left)
    var valueInset = titleInset
    var unboundedSize = valueInset.size
    unboundedSize.height = CGFloat.greatestFiniteMagnitude
    var boundedSize = v.boundingRect(with: unboundedSize, options: .usesLineFragmentOrigin, attributes: valueAttributes, context: nil)
    
    
    while boundedSize.height > (maxHeight - (valueTop - rect.origin.y))  {
      var valueArray = v.characters.split{$0 == " "}.map(String.init)
      
      if valueArray.count == 0 {
        boundedSize.size.height = 0
        v = ""
        break
      }
      
      let last = valueArray.removeLast()
      
      r = "\(last) \(r)"
      v = valueArray.joined(separator: " ")
      boundedSize = v.boundingRect(with: unboundedSize, options: .usesLineFragmentOrigin, attributes: valueAttributes, context: nil)
      
    }
    
    
    valueInset.origin.y = valueTop
    valueInset.size.height = boundedSize.height
    
    v.draw(in: valueInset, withAttributes: valueAttributes)
    
    rect.size.height = max(valueInset.origin.y - rect.origin.y + valueInset.size.height + topMargin, rect.size.height)
    
    return (rect.origin.y + rect.size.height, r)
    
  }
  
  func outlineRect(_ rect: CGRect) {
    
    self.drawLine(rect.origin, term: CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y), width: 1.0, color: UIColor.black)
    self.drawLine(rect.origin, term: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height), width: 1.0, color: UIColor.black)
    self.drawLine(CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height), term: CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y + rect.height), width: 1.0, color: UIColor.black)
    self.drawLine(CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y), term: CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y + rect.height), width: 1.0, color: UIColor.black)
    
  }
  


}
