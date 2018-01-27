//
//  PDFPhotoPage.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-03-14.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}



extension PDFExport {
  
  
  func renderImages(_ area: Area, page: PDFPage) {
    
    var numPerRow: CGFloat = 1
    var numPerCol:CGFloat = 2
    
    if self.exportSettings.photoPageOrientation == .portrait {
      switch self.exportSettings.photoPageCount {
      case 2:
        numPerRow = 1
        numPerCol = 2
      case 6:
        numPerRow = 2
        numPerCol = 3
      case 9:
        numPerRow = 3
        numPerCol = 3
      case 12:
        numPerRow = 3
        numPerCol = 4
      default:
        numPerRow = 1
        numPerCol = 1
      }
    } else if self.exportSettings.photoPageOrientation == .landscape {
      switch self.exportSettings.photoPageCount {
      case 1:
        numPerRow = 1
        numPerCol = 1
      case 4:
        numPerRow = 2
        numPerCol = 2
      case 9:
        numPerRow = 3
        numPerCol = 3
      case 12:
        numPerRow = 4
        numPerCol = 3
      default:
        numPerRow = 1
        numPerCol = 1
      }
    }
    
    let ratio: CGFloat = 3 / 4
    let minMargin: CGFloat = Config.forcePillPageAspectRation ?   Config.pillMetadataHeight :  0
    
    let maxWidth:CGFloat = ((page.marginWidth  + minMargin) / numPerRow)
    let maxHeight:CGFloat = (page.marginHeight / numPerCol)
   
    // maximize for height
    var height = maxHeight - minMargin
    var width = height / ratio
    var heightMargin = minMargin
    var initialWidthMargin: CGFloat = 0
    var widthMargin = (page.marginWidth - width) / 2
    
    if numPerRow > 1 {
      widthMargin = (page.marginWidth - (numPerRow * width)) / (numPerRow - 1)
    } else {
      initialWidthMargin = (page.marginWidth - width) / 2
    }
    
    var forceWidth = false
    if widthMargin < 0 {
      forceWidth = true
    }
    
    // maximize for width
    if forceWidth || (maxWidth > maxHeight * ratio
      && ((maxWidth * ratio + minMargin) * numPerCol) < page.marginHeight) {
      width = maxWidth - minMargin
      height = maxWidth * ratio
      widthMargin = minMargin
      heightMargin = (page.marginHeight - (numPerCol * height)) / numPerCol
    }
    
    
    // ignore all above
    width = maxWidth
    height = maxHeight
    heightMargin = 0
    widthMargin = 0
    initialWidthMargin = 0
    
    var predicate = NSPredicate(format: "area = %@", area)
    
    if let p = self.filterPredicate {
      predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, p])
    }
    
    var issues = Issue.mr_findAllSorted(by: "createdDate", ascending: true, with: predicate) as! [Issue]
    
    issues = issues.sorted { (a, b) -> Bool in
      let aInt = Int(a.issueNumber!)
      let bInt = Int(b.issueNumber!)
      if(aInt == bInt) {
        return a.issueUserLabel < b.issueUserLabel
      }
      return aInt < bInt
    }
    
    
    
    if issues.count == 0 {
      return
    }
   
    var photoComments: [Comment] = []
    
    for issue in issues {
      if let comments = issue.comments {
        for comment in comments.allObjects as! [Comment] {
          if comment.image != nil {
            photoComments.append(comment)
          }
        }
      }
    }
    
    if photoComments.count == 0 {
      return
    }
  
    var size = CGSize(width: width, height: height)
    if Config.forcePillPageAspectRation {
      size = CGSize(width: width, height: height + Config.pillMetadataHeight)
    }
    var row: CGFloat = 999
    var col: CGFloat = 999
    
    for comment in photoComments {
      autoreleasepool() {
        if row > numPerRow {
          col += 1
          row = 1
        }
        
        if col > numPerCol {
          page.newPage(area, project: self.project, currentPage: self.currentPage)
          self.currentPage += 1
          row = 1
          col = 1
        }
        
        if let commentImage = comment.renderCommentPhotoWithPill(size, usePercentage: false, scaleFactor: 3) {
          let x = page.leftMargin + initialWidthMargin + CGFloat(row - 1) * (width + widthMargin) - row
          let y = page.topMargin + CGFloat(col - 1) * (height + heightMargin) - col
          let rect = CGRect(origin: CGPoint(x: x, y: y), size: size)
          commentImage.draw(in: rect)
          row += 1
        }
      }
    }
    
  }
  
  
}
