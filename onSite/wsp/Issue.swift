//
//  Issue.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-07-31.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord
import PromiseKit

@objc(Issue)

class Issue: SyncableModel {
  
  // properties
  @NSManaged var issueNumber: String?
 
  // relationships
  @NSManaged var issueTags: NSSet?
  @NSManaged var area: Area?
  @NSManaged var positions: NSSet?
  @NSManaged var comments: NSSet?
  @NSManaged var user: User?

  @NSManaged func addIssueTags(_ issueTags: NSSet)
  @NSManaged func removeIssueTags(_ issueTags: NSSet)
  
  @NSManaged var locked: Project?
  @NSManaged var copied: Project?

  var issueTagHash: Int {
    let caches = Manager.sharedInstance.caches
    if let hash = caches?.getIssueTagHash(self) {
      return hash
    } else {
//      let predicate = NSPredicate(format: "any issueTags.issue = %@", self)
//      let tags = Tag.MR_findAllSortedBy("level.level", ascending: true, withPredicate: predicate) as! [Tag]
      let tags = (issueTags!.allObjects as! [IssueTag]).map { $0.tag! }

      let stringHash = tags.map { $0.localId }
      let hash =  stringHash.joined(separator: "").hash
      caches?.setIssueTagHash(self, hash: hash)
      return hash
    }
  }

  var issueTag: String {
    get {
      if self.hasUserToAppend {
        return "\(self.issueUserLabel)\(self.issueNumber!)"
        
      } else {
        return self.issueNumber!
      }
    }
  }
  
  var hasUserToAppend: Bool {
    get {
      if let area = self.area, let project = area.project {
        return project.hasUserToAppend
      }
      return true
    }
  }
  
  var issueUserLabel: String {
    get {
      if let area = self.area, let project = area.project, let user = self.user {
        
        let pred = NSPredicate(format: "project = %@ and user = %@", project, user)
        if let projectUser = ProjectUser.mr_findFirst(with: pred) {
          return projectUser.label
        }
      }
      return ""
    }
  }
  
  
  var userId: String {
    get {
      if let user = self.user, let area = self.area, let project = area.project {
        let pred = NSPredicate(format: "project = %@ and user = %@", project, user)
        if let projectUser = ProjectUser.mr_findFirst(with: pred) {
          return projectUser.label
        }
      }
      return ""
    }
  }
  
  var tagsCollection: TagCollection {
    get {
      return TagCollection(withIssue: self, andProject: self.area!.project!)
    } set {
      let localSet = self.mutableSetValue(forKey: "issueTags")
      localSet.removeAllObjects()
      localSet.addObjects(from: newValue.issueTags)
      IssueTag.removeOrphanedIssueTags()
      // invalidate the hash
      let caches = Manager.sharedInstance.caches
      caches?.invalidateIssueTagHash(self)


    }
  }
  
  
  var color: UIColor {
    get {
      return self.tagsCollection.color
    }
  }
  var shape : String {
    get {
      return self.tagsCollection.shape
      
    }
  }
    
  var topLevelTagTitle : String {
    get {
      return self.tagsCollection.topLevelTagTitle
    }
  }
  
  var formattedChildTitle : String {
    get {
      return self.tagsCollection.formattedChildTitle
    }
  }
  
  var formattedChildTitleWithNewLines : String {
    get {
      return self.tagsCollection.formattedChildTitleWithNewLines
    }
  }
  
  var formattedTagsList: String {
    get {
      return "\(self.topLevelTagTitle) — \(self.formattedChildTitle)"
    }
  }
  
  
  var topLevelTag : Tag? {
    get {
      return self.tagsCollection.topLevelTag
    }
  }
  
  var hasArrow: Bool {
    get {
      for position in self.positions!.allObjects as! [Position] {
        if position.hasArrow!.boolValue {
          return true
        }
      }
      return false
      
    }
  }
  
  func removeArrow() {
    
    guard let positions = self.positions else {
      return
    }
    
    for position in positions.allObjects as! [Position] {
      position.hasArrow = NSNumber(value: false as Bool)
    }
    
  }
  
  func copyFromTagCollection(_ tags: TagCollection) {
    
    for issueTag in tags.issueTags {
      
      let n = IssueTag.mr_createEntity()!
      n.setModified()
      n.tag = issueTag.tag
      n.input = issueTag.input
      n.issue = self
    }
  }

  func copyCommentsFromIssue(_ issue: Issue) {
    
    for comment in issue.comments?.allObjects as! [Comment] {
      
      let newComment = Comment.mr_createEntity()!
      newComment.title = comment.title
      newComment.areaX = comment.areaX
      newComment.areaY = comment.areaY
      newComment.areaWidth = comment.areaWidth
      newComment.areaHeight = comment.areaHeight
      
      newComment.commentType = comment.commentType
      
      newComment.cropData = comment.cropData
      newComment.rotationData = comment.rotationData
      
      newComment.issue = self
      newComment.user = comment.user
      newComment.imageData = comment.imageData
      newComment.originalImageData = comment.originalImageData
      
    }
    
    Manager.sharedInstance.saveCurrentState(nil)
    
  }
  
  
  func remove(andRenumber renumber: Bool, cb: @escaping () -> ()) {
    
    if renumber {
      Issue.renumberIssuesRemovingIssue(self)
    }
    
    self.area!.project!.deleteProjectEntity(self)
    Manager.sharedInstance.saveCurrentState(cb)
    
  }


  override class func registerSyncableData(_ converter: RemoteDataConverter) {
  
    converter.registerRemoteData("issueNumber", remote: "issue_number", type: .String)
    
    converter.registerRemoteData("user", remote: "user", type: .User)
    
    converter.registerRemoteData("positions", remote: "positions", type: .Entities, entity: "Position")
    converter.registerRemoteData("comments", remote: "comments", type: .Entities, entity: "Comment", unit: .Separate)
    converter.registerRemoteData("issueTags", remote: "issue_tags", type: .Entities, entity: "IssueTag")
    
  }
  
  
  
  
  static func renumberIssuesRemovingIssue(_ removedIssue: Issue) {
    
    // re-order them by consecutively per user
    if removedIssue.area == nil || removedIssue.user == nil {
      Config.error("Area and user should never be nil!")
      return
    }
    
    let currentIssueNumber = Int(removedIssue.issueNumber!)!
    let predicate = NSPredicate(format: "area.project = %@ and user = %@", removedIssue.area!.project!, removedIssue.user!)
    let issues = Issue.mr_findAll(with: predicate) as! [Issue]
    
    
    for issue in issues {
      if issue == removedIssue {
        continue
      }
      if issue.issueNumber != nil && Int(issue.issueNumber!) != nil {
        let i = Int(issue.issueNumber!)!
        if i > currentIssueNumber {
          issue.issueNumber = String(i - 1)
          issue.setModified()
        }
      }
    }
   
  }
  
  func renumberIssue(_ num: Int) {
    
    if self.area == nil || self.user == nil {
      Config.error("Area and user should never be nil!")
      return
    }
    
    let predicate = NSPredicate(format: "area.project = %@ and user = %@", self.area!.project!, self.user!)
    let issues = Issue.mr_findAll(with: predicate) as! [Issue]
    
    for issue in issues {
      if issue.issueNumber != nil && Int(issue.issueNumber!) != nil {
        let i = Int(issue.issueNumber!)!
        if i >= num {
          issue.issueNumber = String(i + 1)
          issue.setModified()
        }
      }
    }
    
    self.issueNumber = String(num)
    self.setModified()
   
    Manager.sharedInstance.saveCurrentState(nil)
    
  }
  
  
  static func getNextIssueNumberForProject(_ project: Project, user:User = Manager.sharedInstance.getCurrentUser()) -> String {
    
    let nums = Issue.getIssueNumberArrayForProject(project, user: user)
    if nums.count == 0 {
      return "1"
    } else {
      let maxNum = nums.max()! + 1
      for i in 1...maxNum {
        if !nums.contains(i) {
          return String(i)
        }
      }
      return String(maxNum)
    }
  }
 
  func isLastestIssue() -> Bool {
    
    // prevent a clash and assume there are others
    if self.area == nil || self.user == nil {
      Config.error("Area and user should never be nil!")
      return false
    }
    
    let nums = Issue.getIssueNumberArrayForProject(self.area!.project!, user: self.user!)
    
    if nums.count > 0 {
      let top = nums.max()!
     
      if String(top) == self.issueNumber! {
        return true
      }
    } else {
      //wierd
      Config.error("Could not find any issues where there should have been.")
    }
    
    return false
    
  }
  
  static func getIssueNumberArrayForProject(_ project: Project, user: User?) -> [Int] {
    
    
    var predicate = NSPredicate(format: "area.project = %@", project)
    if let u = user {
      predicate = NSPredicate(format: "area.project = %@ and user = %@", project, u)
    }
    let issues = Issue.mr_findAll(with: predicate) as! [Issue]
    
    var nums: [Int] = []
    
    for issue in issues {
      if let num = issue.issueNumber {
        nums.append(Int(num)!)
      }
    }
    
    return nums
    
  }

  override func removeWithFiles() {

    guard let c = self.comments else {
      return
    }

    for comment in c.allObjects as! [Comment] {
      comment.removeWithFiles()
    }

    super.removeWithFiles()

  }
  
  
  func drawIssueLabelAtPoint(_ point: CGPoint, ofSize: CGFloat? = nil) {
    
    var pillSize: CGFloat = 40
    let project = self.area!.project!
    
    var letterLength = 0
    
    if Manager.sharedInstance.features.globalPillSizeAdjust {
      if let maxNum = Issue.getIssueNumberArrayForProject(project, user: nil).max() {
        letterLength = String(maxNum).count
        if self.hasUserToAppend {
          letterLength += 1
        }
      } else {
        Config.error("Impossible that there is no max for elemest of project")
        return
      }
    } else {
      
      letterLength = self.issueNumber!.count
      if self.hasUserToAppend {
        letterLength += 1
      }
      
    }
    
    
    let ps = project.pillSize.floatValue
    
    pillSize = CGFloat(ps) + 0.5
    
    // pillsize ranges from 0.5 to 1.5
    pillSize = (Config.minPillSize + (pillSize - 0.5) * (Config.maxPillSize - Config.minPillSize))
    
    var fontSize: CGFloat = pillSize / 5
    
    if ofSize != nil {
      pillSize = ofSize!
    }
    
    switch letterLength {
    case 1:
      fontSize = pillSize / 1.2
      
    case 2:
      fontSize = pillSize / 2
      
    case 3:
      fontSize = pillSize / 3
      
    case 4:
      fontSize = pillSize / 4
      
    case 5:
      fontSize = pillSize / 5 
      
    default:
      fontSize = pillSize / 6
      
    }
    
    let imageSize:CGFloat = pillSize / 2
    let strokeSize: CGFloat = imageSize + 1
    
    let shape = self.shape
    
    let imageRect = CGRect(x: point.x - imageSize, y: point.y - imageSize ,  width: imageSize*2, height: imageSize*2)
    let strokeRect = CGRect(x: point.x - strokeSize, y: point.y - strokeSize,  width: strokeSize*2, height: strokeSize*2)
    
    let strokeColor = UIColor.white
    let color = self.color
    let shapeImage = self.fillImageWithColor(UIImage(named: shape)!, color: color)
    let shapeStrokeImage = self.fillImageWithColor(UIImage(named: shape)!, color: strokeColor)
    
    shapeStrokeImage?.draw(in: strokeRect)
    shapeImage?.draw(in: imageRect)
    
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    
    var textAttributes: [NSAttributedStringKey: Any] = [NSAttributedStringKey(rawValue: NSAttributedStringKey.font.rawValue): UIFont.systemFont(ofSize: fontSize)]
    textAttributes[NSAttributedStringKey.paragraphStyle] = paragraphStyle
    textAttributes[NSAttributedStringKey.backgroundColor] = UIColor.clear
    textAttributes[NSAttributedStringKey.foregroundColor] = UIColor.white
    let text = String(self.issueTag) as NSString
    
    var textRect = CGRect(x: imageRect.origin.x,
      y: imageRect.origin.y + (imageSize - (fontSize/2)),
      width: imageSize*2, height: fontSize)
    
    let textSize = text.boundingRect(with: textRect.size, options: .usesFontLeading, attributes: textAttributes, context: nil)
    textRect.origin.y = textRect.origin.y +  (textRect.size.height - textSize.height) / 2
    text.draw(in: textRect, withAttributes: textAttributes)
    
  }
  
  func fillImageWithColor(_ image: UIImage, color: UIColor) -> UIImage? {
    
    let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()
    
    context?.clip(to: rect, mask: image.cgImage!)
    context?.setFillColor(color.cgColor)
    context?.fill(rect)
    
    
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    if img != nil {
      return UIImage(cgImage: (img?.cgImage!)!, scale: 1.0, orientation: .downMirrored)
    } else {
      Config.error("fillImageWithColorError")
      return nil
    }
  }
  
}
