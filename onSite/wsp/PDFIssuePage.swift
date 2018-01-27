//
//  PDFIssuePage.swift
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
  
  func renderComments(_ area: Area, page: PDFPage) {
    
    var predicate = NSPredicate(format: "area = %@", area)
    
    if let p = self.filterPredicate {
      predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, p])
    }
    
    var issues = Issue.mr_findAllSorted(by: "createdDate", ascending: true, with: predicate, in: currentManagedObjectContext) as! [Issue]
    
    issues = issues.sorted { (a, b) -> Bool in
      let aInt = Int(a.issueNumber!)
      let bInt = Int(b.issueNumber!)
      if(aInt == bInt) {
        return a.issueUserLabel < b.issueUserLabel
      }
      return aInt < bInt
    }
    
    if issues.count > 0 {
      
      page.newPage(area, project: self.project, currentPage: self.currentPage)
      self.currentPage += 1
      var top = page.topMargin
      
      var count: Int = 0;
      for issue in issues {
        count += 1
        top = self.renderIssue(issue, y: top, count: count, page: page)
      }
    }
  }
 
  func renderIssue(_ issue: Issue, y: CGFloat, count: Int, page: PDFPage) -> CGFloat {
    var y = y
    
    let shapeFontSize: CGFloat = 22
    let margins:CGFloat = 0.25 * shapeFontSize
    let textMargin: CGFloat = 2
    
    // set date format to yyyy-mm-dd
    
    let area = issue.area!
    
    
    if y + shapeFontSize + margins > page.topMargin + page.marginHeight {
      page.newPage(area, project: self.project, currentPage: self.currentPage)
      y = page.topMargin
      self.currentPage += 1
    }
    
    var availableY = page.height - y - page.bottomMargin
    
    // icon
    var x = page.leftMargin
    issue.drawIssueLabelAtPoint(CGPoint(x: x + (shapeFontSize/2), y: y + (shapeFontSize/2)), ofSize: shapeFontSize * 0.75)
    x += shapeFontSize + margins
    
    // main category
    let initialY: CGFloat = y
    
    let categoryHeight: CGFloat = shapeFontSize * 0.425
    let mainCategory = String(issue.topLevelTagTitle) as NSString
    var textAttributes = self.attributesWithFont(PDFPage.reportFontOfSize(categoryHeight * 0.75), alignment: .left)
    textAttributes[NSAttributedStringKey.foregroundColor] = UIColor(netHex: 0x595d5e)
    var unboundedSize = CGSize(width: page.width - page.leftMargin - x, height: availableY - categoryHeight)
    var boundedSize = mainCategory.boundingRect(with: unboundedSize, options: .usesLineFragmentOrigin, attributes: textAttributes, context: nil)
    boundedSize.origin = CGPoint(x: x, y: y)
    mainCategory.draw(in: boundedSize, withAttributes: textAttributes)
    availableY -= boundedSize.size.height + textMargin
    
    var dateY = y
    y += boundedSize.size.height + textMargin
    let middleDateY: CGFloat = boundedSize.size.height + 1
    
    
    // issue date
    let username = issue.user == nil ? "" : issue.user!.username! + " - "
    let issueDate: NSString = (username + issue.createdDateFormatted) as NSString
    var dateX = page.leftMargin + page.marginWidth
    textAttributes = self.attributesWithFont(PDFPage.reportFontOfSize(categoryHeight * 0.8 * 0.6), alignment: .left)
    textAttributes[NSAttributedStringKey.foregroundColor] = UIColor(netHex: 0x666666)
    unboundedSize = CGSize(width: page.width - page.leftMargin - dateX, height: availableY - categoryHeight)
    boundedSize = issueDate.boundingRect(with: unboundedSize, options: .usesLineFragmentOrigin, attributes: textAttributes, context: nil)
    dateY += (middleDateY - boundedSize.size.height) / 2
    dateX -= boundedSize.size.width
    boundedSize.origin = CGPoint(x: dateX, y: dateY)
    issueDate.draw(in: boundedSize, withAttributes: textAttributes)
    
    
    // secondary category
    
    let secCategoryHeight: CGFloat = categoryHeight * 0.8
    let secCategory = String(issue.formattedChildTitle) as NSString
    textAttributes = self.attributesWithFont(PDFPage.reportFontOfSize(secCategoryHeight * 0.75), alignment: .left)
    textAttributes[NSAttributedStringKey.foregroundColor] = UIColor(netHex: 0x595d5e)
    unboundedSize = CGSize(width: page.width - page.leftMargin - x, height: availableY - secCategoryHeight)
    boundedSize = secCategory.boundingRect(with: unboundedSize, options: .usesLineFragmentOrigin, attributes: textAttributes, context: nil)
    boundedSize.origin = CGPoint(x: x, y: y)
    secCategory.draw(in: boundedSize, withAttributes: textAttributes)
    availableY -= boundedSize.size.height + textMargin
    y += boundedSize.size.height + textMargin
    
    
    // comments
    var commentAttributes = self.attributesWithFont(PDFPage.reportFontOfSize(secCategoryHeight * 0.8), alignment: .left)
    commentAttributes[NSAttributedStringKey.foregroundColor] = UIColor(netHex: 0x333333)
    var dateAttributes = self.attributesWithFont(PDFPage.reportFontOfSize(secCategoryHeight * 0.6), alignment: .right)
    dateAttributes[NSAttributedStringKey.foregroundColor] = UIColor(netHex: 0x666666)
    
    var commentY: CGFloat = 0
    
    let comments = Comment.mr_find(byAttribute: "issue", withValue: issue, andOrderBy: "createdDate", ascending: true, in: self.currentManagedObjectContext) as! [Comment]
    var imageSequence = 1
    for comment in comments {
      
      if let commentTitle = comment.title {
        if commentTitle == "" {
          continue
        }
        let nsComment = commentTitle as NSString
        
        y += secCategoryHeight * 0.7
        
        let metaMargin: CGFloat = 5
        let remainingWidth = page.width - page.leftMargin - x
        let commentWidth = CGFloat(floor(2 * remainingWidth / 3))
        let metaWidth = remainingWidth - commentWidth - metaMargin
        
        unboundedSize = CGSize(width: commentWidth, height: availableY - commentY)
        boundedSize = nsComment.boundingRect(with: unboundedSize, options: .usesLineFragmentOrigin, attributes: commentAttributes, context: nil)
        
        boundedSize.origin = CGPoint(x: x, y: y)
        nsComment.draw(in: CGRect(origin: boundedSize.origin, size: unboundedSize), withAttributes: commentAttributes)
        
        
        var prefix = "Comment"
        if comment.imageFile != nil {
          prefix = comment.sequenceName(imageSequence)
          imageSequence += 1
          
        }
        
        var prepend = prefix + " - "
        if let user = comment.user, let username = user.username {
          prepend += username + " - "
        }
        let date = (prepend + comment.createdDateFormatted) as NSString
        
        let metaUnboundedSize = CGSize(width: metaWidth, height: availableY - commentY)
        var metaBoundedSize = date.boundingRect(with: metaUnboundedSize, options: .usesLineFragmentOrigin, attributes: dateAttributes, context: nil)
        
        metaBoundedSize.origin = CGPoint(x: x + commentWidth + metaMargin, y: y)
        date.draw(in: CGRect(origin: metaBoundedSize.origin, size: metaUnboundedSize), withAttributes: dateAttributes)
        
        
        let maxHeight = max(boundedSize.size.height, metaBoundedSize.size.height)
        commentY += maxHeight + margins
        y += maxHeight
        availableY -= maxHeight + textMargin
        
      }
      
    }
    
    y += margins
    
    if y - initialY < shapeFontSize + 2 * margins {
      y = initialY + shapeFontSize + margins
    }
    
    self.drawLine(CGPoint(x: page.leftMargin, y: y), term: CGPoint(x: page.width - page.rightMargin, y: y), width: 1, color: UIColor(netHex: 0xbdbdbd))
    y += margins
    
    
    return y
  }
  
}
