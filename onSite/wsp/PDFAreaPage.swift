//
//  PDFAreaPage.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-03-14.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation

extension PDFExport {
  
  func renderArea(_ area: Area, page: PDFPage){
   
    page.newPage(area, project: self.project, currentPage: self.currentPage)
    self.currentPage += 1

    let context = UIGraphicsGetCurrentContext()
    let areaImage = area.image!

    var predicate = NSPredicate(format: "area = %@", area)
    if let p = self.filterPredicate {
      predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, p])
    }
    
    let issues = Issue.mr_findAllSorted(by: "createdDate", ascending: true, with: predicate) as! [Issue]
    
    var hasLegend = true
    if issues.count == 0 {
      hasLegend = true
    }
    
    if self.project.colorLevel == nil && self.project.shapeLevel == nil {
      hasLegend = true
    }
    
    let legendWidth: CGFloat = hasLegend ? 2 * 72 : 0
    let legendMargin: CGFloat = 30
    let imageMargin: CGFloat = 15
    let maxImageWidth = page.marginWidth - legendWidth - legendMargin - (2 * imageMargin)

    let image = self.resizeImage(areaImage, maxHeight: page.marginHeight, maxWidth: maxImageWidth)
    let legendX = page.leftMargin + page.marginWidth - legendWidth - 5
    let legendRect = CGRect(x: legendX, y: page.topMargin, width: legendWidth, height: page.marginHeight)
    
    let imageOriginX = page.leftMargin + (page.marginWidth -  legendWidth - image.size.width) / 2
    let imageOriginY = page.topMargin + (page.marginHeight - image.size.height) / 2
    image.draw(at: CGPoint(x: imageOriginX, y: imageOriginY))
    
    let strokePageRect = CGRect(x: page.leftMargin, y: page.topMargin, width: page.marginWidth, height: page.marginHeight)
    
    context?.setStrokeColor(UIColor.black.cgColor)
    context?.setLineWidth(1.0)
    context?.stroke(strokePageRect)
    if hasLegend {

        let myMutablePath:CGMutablePath = CGMutablePath()
        myMutablePath.move(to: CGPoint(x: legendX - imageMargin, y: page.topMargin))
        myMutablePath.addLine(to: CGPoint(x: legendX - imageMargin, y: page.topMargin + page.marginHeight))
//      CGPathMoveToPoint(myMutablePath, nil, legendX - imageMargin, page.topMargin)
//      CGPathAddLineToPoint(myMutablePath, nil, legendX - imageMargin, page.topMargin + page.marginHeight)
      context?.addPath(myMutablePath);
      context?.strokePath()
      
    }

    var count: Int = 0;
    let scaleFactor = image.size.width / areaImage.size.width
    
    let pointAdjust:CGFloat = 0
    
    for issue in issues {
      
      if let positions = issue.positions?.allObjects as? [Position] {
        for position in positions {
          
          if position.hasArrow != nil && position.hasArrow!.boolValue {
            var x: CGFloat = CGFloat(position.markerX!.floatValue)
            var y: CGFloat = CGFloat(position.markerY!.floatValue)
            let point = CGPoint(x: x * scaleFactor + imageOriginX + pointAdjust, y: y * scaleFactor + imageOriginY + pointAdjust)
            
            x = CGFloat(position.x!.floatValue)
            y = CGFloat(position.y!.floatValue)
            let markerPoint = CGPoint(x: x * scaleFactor + imageOriginX, y: y * scaleFactor + imageOriginY)
            
            let arrow =  UIBezierPath.bezierPathWithArrowFromPoint(startPoint: point, endPoint: markerPoint, tailWidth: 1, headWidth: 6, headLength: 6)
            issue.color.setFill()
            arrow.fill()
          }
        }
      }
    }
    
    for issue in issues {
      if let positions = issue.positions?.allObjects as? [Position] {
        count += 1
        for position in positions {
          
          let x: CGFloat = CGFloat(position.markerX!.floatValue)
          let y: CGFloat = CGFloat(position.markerY!.floatValue)
          let point = CGPoint(x: x * scaleFactor + imageOriginX + pointAdjust, y: y * scaleFactor + imageOriginY + pointAdjust)
          issue.drawIssueLabelAtPoint(point, ofSize: nil)
        }
      }
    }
    
    
    if hasLegend {
      self.renderLegend(area, position: legendRect, page: page)
    }
    
  }
  
  func renderLegend(_ area: Area, position: CGRect, page: PDFPage) {
    
    let itemHeight:CGFloat = 18
    
    let fontSize: CGFloat = 10
    var topSpace: CGFloat = 10
    
    var headerFontSize: CGFloat = 12
    if self.exportSettings.size == .eleven {
      headerFontSize = 18
      topSpace = 15
    }
    
    
    let separateColorRun: Bool = self.project.shapeLevel == self.project.colorLevel ? false : true

    var uniqueShapeTags: [Tag] = []
    var uniqueColorTags: [Tag] = []
    if let level = self.project.shapeLevel {

      var predicate = NSPredicate(format: "any issueTags.issue.area = %@ and level = %@", area, level)
      if let p = self.tagFilterPredicate {
        predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, p])
      }
      
      
      uniqueShapeTags = Tag.mr_findAllSorted(by: "title", ascending: true, with: predicate, in: self.currentManagedObjectContext) as! [Tag]
      
      var seenShapes: [String] = []
      var seenTags: [String] = []
      var reallyUnique : [Tag] = []
      
      for tag in uniqueShapeTags {
        if seenShapes.contains(tag.shapeValue()) && seenTags.contains(tag.nonEmptyTitle) {
          continue
        } else {
          seenShapes.append(tag.shapeValue())
          seenTags.append(tag.nonEmptyTitle)
          reallyUnique.append(tag)
        }
      }
      
      uniqueShapeTags = reallyUnique

    }

    if let level = self.project.colorLevel, separateColorRun {
      var predicate = NSPredicate(format: "any issueTags.issue.area = %@ and level = %@", area, level)
      if let p = self.tagFilterPredicate {
        predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, p])
      }

      uniqueColorTags = Tag.mr_findAllSorted(by: "title", ascending: true, with: predicate, in: self.currentManagedObjectContext) as! [Tag]

      var seenColors: [String] = []
      var seenTags: [String] = []
      var reallyUnique : [Tag] = []
      
      for tag in uniqueColorTags {
        if seenColors.contains(tag.colorString) && seenTags.contains(tag.nonEmptyTitle) {
          continue
        } else {
          seenColors.append(tag.colorString)
          seenTags.append(tag.nonEmptyTitle)
          reallyUnique.append(tag)
        }
      }
      uniqueColorTags = reallyUnique
    }
    
   
    let totalItems = uniqueShapeTags.count + uniqueColorTags.count + 2 + (separateColorRun ? 1 : 0)

    let totalItemHeight:CGFloat = CGFloat(totalItems) * itemHeight
    
    if totalItemHeight > position.height {
      page.newPage(area, project: self.project, currentPage: self.currentPage)
      self.currentPage += 1
    }

    var rect = CGRect(x: position.origin.x - 10, y: position.origin.y + 5, width: position.width, height: itemHeight)
//    var rect = CGRectMake(position.origin.x, position.origin.y + (position.height - totalItemHeight)/2, position.width, itemHeight)

    // title
    let title = "LÉGENDE" as NSString
    var textAttributes = self.attributesWithFont(
      PDFPage.reportFontOfSize(headerFontSize), alignment: .left)
    textAttributes[NSAttributedStringKey.foregroundColor] = UIColor.black
    title.draw(in: rect, withAttributes: textAttributes)
    rect.origin.y += headerFontSize + topSpace
    
    // legend
    textAttributes = self.attributesWithFont(PDFPage.reportLightFontOfSize(fontSize), alignment: .left)
    textAttributes[NSAttributedStringKey.foregroundColor] = UIColor.black

    let sortedShapeTags = uniqueShapeTags.sorted { $0.title!.localizedCaseInsensitiveCompare($1.title!) == ComparisonResult.orderedAscending }
    rect = self.renderArrayOfTags(sortedShapeTags, rect: rect, fontSize: fontSize, itemHeight: itemHeight, page: page)

    if separateColorRun {
      rect.origin.y += itemHeight
    }

    let sortedColorTags = uniqueColorTags.sorted { $0.title!.localizedCaseInsensitiveCompare($1.title!) == ComparisonResult.orderedAscending }
    rect = self.renderArrayOfTags(sortedColorTags, rect: rect, fontSize: fontSize, itemHeight: itemHeight, page: page)
    
    
    let context = UIGraphicsGetCurrentContext()
    context?.setStrokeColor(UIColor.black.cgColor)
    context?.setLineWidth(1.0)
    
    let myMutablePath:CGMutablePath = CGMutablePath()
    myMutablePath.move(to: CGPoint(x: position.origin.x - 15, y: rect.origin.y))
    myMutablePath.addLine(to: CGPoint(x: position.origin.x + position.width + 5, y: rect.origin.y))
    
//    CGPathMoveToPoint(myMutablePath, nil, position.origin.x - 15, rect.origin.y)
//    CGPathAddLineToPoint(myMutablePath, nil, position.origin.x + position.width + 5, rect.origin.y)
    context?.addPath(myMutablePath);
    context?.strokePath()
    
    
    var image: UIImage!
    if let i = self.project.buildingImage {
      image = i
    } else {
      image = UIImage(named: "Legend Logo")
    }
    
    image = self.resizeImage(image, maxHeight: page.height - page.bottomMargin - rect.origin.y, maxWidth:rect.width)
    let margin = (rect.width - image.size.width + 10) / 2
    rect = CGRect(x: rect.origin.x + margin, y: page.height - page.bottomMargin - image.size.height - margin, width: image.size.width, height: image.size.height)
    image.draw(in: rect)
    
    
    let mutPath:CGMutablePath = CGMutablePath()
    let boxtop = page.height - page.bottomMargin - image.size.height - 3 * margin
    mutPath.move(to: CGPoint(x: position.origin.x - 15, y: boxtop))
    mutPath.addLine(to: CGPoint(x: position.origin.x + position.width + 5, y: boxtop))
    
//    CGPathMoveToPoint(mutPath, nil, position.origin.x - 15, boxtop)
//    CGPathAddLineToPoint(mutPath, nil, position.origin.x + position.width + 5, boxtop)
    context?.addPath(mutPath)
    context?.strokePath()
    
    
  }
  
  
  func renderArrayOfTags(_ tags: [Tag], rect: CGRect, fontSize: CGFloat, itemHeight: CGFloat, page: PDFPage) -> CGRect {
    
    var rect = rect
    
    let imageSize: CGFloat = 12
    let imageRightMargin = fontSize
   
    var topText: String = ""
    if let first = tags.first {
      let level = first.level
      
      if level.isShapeLevel.boolValue  && level.isColorLevel.boolValue {
        topText = "FORMES & COULEURS"
        
      } else if level.isShapeLevel.boolValue {
        topText = "FORMES"
        
      } else if level.isColorLevel.boolValue {
        topText = "COULEURS"
      }
      let fontSizeIncrease: CGFloat = 2
      var textAttributes = self.attributesWithFont(PDFPage.reportLightFontOfSize(fontSize + fontSizeIncrease), alignment: .left)
        textAttributes[NSAttributedStringKey.foregroundColor] = UIColor.black
      
      let titleRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: fontSize + fontSizeIncrease)
      (topText as NSString).draw(in: titleRect, withAttributes: textAttributes)
      rect.origin.y += itemHeight
      
      
    }
    
    var textAttributes = self.attributesWithFont(PDFPage.reportLightFontOfSize(fontSize), alignment: .left)
    textAttributes[NSAttributedStringKey.foregroundColor] = UIColor.black
    
    for tag in tags {
      let shape = tag.shapeValue()
      let color = tag.colorValue()
      var shapeImage: UIImage!
      
      if tag.level.isShapeLevel.boolValue  && tag.level.isColorLevel.boolValue {
        shapeImage = self.fillImageWithColor(UIImage(named:shape)!, color: color)
        
      } else if tag.level.isShapeLevel.boolValue {
        shapeImage = self.fillImageWithColor(UIImage(named:shape)!, color: UIColor.black)
        
      } else if tag.level.isColorLevel.boolValue {
        shapeImage = self.fillImageWithColor(UIImage(named:Tag.NoShapeImage)!, color: color)
        
      }
    
      let imageRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: imageSize, height: imageSize)
      shapeImage?.draw(in: imageRect)
      
      let title = NSMutableAttributedString(attributedString: tag.nonEmptyAttributedTitle)
      title.addAttributes(textAttributes, range: NSMakeRange(0, title.length))
      
      let titleRect = CGRect(x: rect.origin.x + imageSize + imageRightMargin, y: rect.origin.y, width: rect.size.width - imageSize - imageRightMargin, height: fontSize)
      let unboundedSize = CGSize(width: titleRect.width, height: CGFloat.greatestFiniteMagnitude)
      var boundingRect = title.boundingRect(with: unboundedSize, options: .usesLineFragmentOrigin, context: nil)
      boundingRect.origin = titleRect.origin
      
      title.draw(in: boundingRect)
      
      rect.origin.y += boundingRect.height + 5
      
    }
    return rect
  }
  
  
}
