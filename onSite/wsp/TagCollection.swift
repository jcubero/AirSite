//
//  TagsCollection.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-12-14.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import Foundation
import CoreData


class TagCollection {
  
  fileprivate var _disconnected: [IssueTag] = []
  
  var issueTags: [IssueTag] {
    get {
      return self._disconnected
    }
  }
  
  var project: Project!
  var poppedTag: Tag?
  
  var savedInputTag: Tag?
  var savedInput: String?

  // edit stuff
  var editMode: Bool = false
  var editLevelStack: [Level]?
  var editLevelPointer: Int = 0
  var editLevelPointerStack: [Int]?
  var editLastIssueInput: IssueTag?


  init(withIssue: Issue?, andProject: Project) {
    if let i = withIssue {
      self._disconnected = i.issueTags?.allObjects as! [IssueTag]
    }
    self.project = andProject
    
  }
  
  
  var hasShapeAndColor : Bool {
    get {
      if self.issueTags.index(where: { $0.tag!.level.isColorLevel.boolValue }) != nil &&
        self.issueTags.index(where: { $0.tag!.level.isShapeLevel.boolValue })  != nil {
          return true
      } else {
        return false
      }
    }
  }
  
  var color: UIColor {
    get {
      if let indexOfItemWithColor = self.issueTags.index(where: { $0.tag!.level.isColorLevel.boolValue }) {
        let tag = self.issueTags[indexOfItemWithColor].tag!
        return tag.colorValue()
      } else {
        return Tag.defaultColor()
      }
      
    }
  }
  var shape : String {
    get {
      if let indexOfItemWithShape = self.issueTags.index(where: { $0.tag!.level.isShapeLevel.boolValue }) {
        let tag = self.issueTags[indexOfItemWithShape].tag!
        return tag.shapeValue()
      } else {
        return Tag.defaultImage()
      }
    }
  }
  
  
  var topLevelTagTitle : String {
    get {
      if let item = self.sorted.first {
        return item.title
      }
      return ""
    }
  }
  
  var topLevelTagAttributedTitle: NSAttributedString {
    get {
      if let item = self.sorted.first {
        return item.attributedTitle
      }
      let empty = NSAttributedString(string: "")
      return empty
    }
    
  }
  
  var formattedChildAttributedTitle: NSAttributedString {
    get {
      let title = NSMutableAttributedString(string: "")
      var children = self.sorted
      if children.count > 1 {
        children.remove(at: 0)
       
        for child in children {
          if child.shouldHideTag { continue }
          if title.length == 0 {
            title.append(child.attributedTitle)
          } else {
            let marker = NSAttributedString(string: " — ")
            title.append(marker)
            title.append(child.attributedTitle)
          }
        }
      }
      return title
    }
    
  }
  
  var formattedChildTitle : String {
    get {
      var title: String = ""
      var children = self.sorted
      if children.count > 1 {
        children.remove(at: 0)
       
        for child in children {
          if child.shouldHideTag { continue }
          if title == "" {
            title = child.title
          } else {
            title = "\(title) — \(child.title)"
          }
        }
      }
      return title
    }
  }
  
  var formattedChildTitleWithNewLines : String {
    get {
      var title: String = ""
      var children = self.sorted
      if children.count > 1 {
        children.remove(at: 0)
       
        for child in children {
          if child.shouldHideTag { continue }
          if title == "" {
            title = "— \(child.title)"
          } else {
            title = "\(title)\n— \(child.title)"
          }
        }
      }
      return title
    }
  }
  
  var topLevelTag : Tag? {
    get {
      return self.sorted.first?.tag
    }
  }
  
  var lastTag: Tag? {
    get {
      if issueTags.count > 0 {
        return self.sorted.last!.tag!
      } else {
        return nil
      }
    }
  }
  
  var lastLevel: Level? {
    get {
      if let tag = self.lastTag {
        return tag.level
      } else {
        return nil
      }
    }
  }
  
  var nextLevel: Level? {
    get {

      if editMode {
        guard let levels = editLevelStack else {
          Config.error()
          return nil
        }
        if editLevelPointer == 0 {
          return levels.first
        }

        // go down the levels on the stack to see if theyre valid
        var pointer = editLevelPointer
        while levels.count > pointer {
          
          let nextLevel = levels[pointer]
          
          var parentTag: Tag?
          if nextLevel.isTreeLevel.boolValue {
            guard let parentLevel = nextLevel.parent else {
              Config.error("No parent defined!")
              return nil
            }
            parentTag = self.findTagWithLevel(parentLevel)
            
          }

          switch nextLevel.levelAction(parentTag) {
          case .skip:
            pointer += 1
            continue
          case .end:
            return nil
          case .process:
            return nextLevel
          }
        }
        
        return nil
      }
      
      if self.lastLevel == nil {
        // first level
        return Level.getOrCreateLevelForProject(self.project, level: 0)
      }
      
      var currentLevel: Level? = self.lastLevel
      
      while let lastLevel = currentLevel {
        
        if let nextLevel = lastLevel.nextLevel {
          
          var parentTag: Tag?
          if nextLevel.isTreeLevel.boolValue {
            guard let parentLevel = nextLevel.parent else {
              Config.error("No parent defined!")
              return nil
            }
            parentTag = self.findTagWithLevel(parentLevel)
            
          }
          switch nextLevel.levelAction(parentTag) {
          case .skip:
            currentLevel = nextLevel
            continue
          case .end:
            return nil
          case .process:
            return nextLevel
          }
        } else {
          // there is no level past this one
          return nil
        }
      }
      
      return nil
    }
  }
  
  var sorted : [IssueTag] {
    get {
      return self.issueTags.sorted { $0.tag!.level.level.int32Value < $1.tag!.level.level.int32Value }
    }
  }
  
  var libraryPredicate: NSPredicate {
    get {
      guard let nextLevel = self.nextLevel else {
        Config.error("Predicate called on non-level")
        return NSPredicate(format: "")
      }
      
      var pred = NSPredicate(format: "level = %@", nextLevel)
      
      
      if nextLevel.isTreeLevel.boolValue && !nextLevel.isTopLevel {
        let level = nextLevel.parent!
        guard let tag = self.findTagWithLevel(level) else {
          Config.error("No tag found matching parent in heigharchy")
          return pred
        }
        
        let addPred = NSPredicate(format: "parent = %@", tag)
        pred = NSCompoundPredicate(andPredicateWithSubpredicates: [pred, addPred])
      }
      
      if let p = self.poppedTag {
        let popPred = NSPredicate(format: "localUnique != %@", p.localId)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [pred, popPred])
      } else {
        return pred
      }
    }
  }
  
  
  var nextLevelExists: Bool {
    get {
      return self.nextLevel == nil ? false : true
    }
  }
  
  var allTags: [Tag] {
    get {
      var all: [Tag] = []
      for issue in self.issueTags {
        all.append(issue.tag!)
      }
      return all
    }
  }
  
  var issuesWithAllTags: [Issue] {
    get {
      var predicate = NSPredicate(format: "area.project = %@", self.project)
      for issueTag in self.issueTags {
        let comp = NSPredicate(format: "any issueTags.tag = %@", issueTag.tag!)
        predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, comp])
      }
      let sort = NSSortDescriptor(key: "issueNumber", ascending: false, selector: #selector(NSString.localizedStandardCompare(_:)))
      let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Issue")
      fr.predicate = predicate
      fr.sortDescriptors = [sort]
      do {
        let res = try NSManagedObjectContext.mr_default().fetch(fr) as! [Issue]
        return res
      } catch {
        return []
      }
    }
  }

  var allUsedLevels: [Level] {

    var levels: [Level] = []

    for issueTag in self.sorted {
      guard let tag = issueTag.tag else {
        Config.error()
        return levels
      }

      levels.append(tag.level)

    }

    return levels
  }

  
  func nextLevelExistsSupposing(_ tag: Tag) -> Bool {
    
    var currentLevel: Level? = tag.level
    
    while let lastLevel = currentLevel {
      
      if let nextLevel = lastLevel.nextLevel {
        
        var parentTag: Tag?
        if nextLevel.isTreeLevel.boolValue {
          guard let parentLevel = nextLevel.parent else {
            Config.error("No parent defined!")
            return false
          }
          
          if parentLevel == tag.level {
              parentTag = tag
          } else {
            parentTag = self.findTagWithLevel(parentLevel)
          }
          
        }
        switch nextLevel.levelAction(parentTag) {
        case .skip:
          currentLevel = nextLevel
          continue
        case .end:
          return false
        case .process:
          return true
        }
      } else {
        // there is no level past this one
        return false
      }
    }
    
    return false
  
  }
  
  func clone() {
   
    var tags: [IssueTag] = []
    
    for issueTag in self.issueTags {
      
      let n = IssueTag.mr_createEntity()!
      n.setModified()
      n.tag = issueTag.tag
      n.input = issueTag.input
      
      tags.append(n)
    }
    
    self._disconnected = tags
  }
  
  func hasSameTagsAs(_ tc: TagCollection) -> Bool {
    
    let s1 = Set(self.allTags)
    let s2 = Set(tc.allTags)
    
    return s1.symmetricDifference(s2).count == 0 ? true : false
    
  }
  
  func treeLevelHasChildTags(_ level: Level) -> Bool {
    
    if level.isTreeLevel.boolValue {
      guard let parent = level.parent else {
        Config.error("Parent undefined!")
        return false
      }
      
      guard let tag = self.findTagWithLevel(parent) else {
        Config.error("Child undefined!")
        return false
      }
      
      let numOfChildern = Tag.mr_countOfEntities(with: NSPredicate(format: "parent = %@ and level = %@ and title !=[c] %@", tag, level, Tag.TagTitleEnd))
      
      return numOfChildern != 0
      
    } else {
      Config.error("Not a tree level!")
      return false
    }
  }
  
  func treeLevelHasChildTagsThatTerminate(_ level: Level) -> Bool {
    
    if level.isTreeLevel.boolValue {
      guard let parent = level.parent else {
        Config.error("Parent undefined!")
        return false
      }
      
      guard let tag = self.findTagWithLevel(parent) else {
        Config.error("Child undefined!")
        return false
      }
      
      let numOfChildern = Tag.mr_countOfEntities(with: NSPredicate(format: "parent = %@ and level = %@ and title ==[c] %@", tag, level, Tag.TagTitleEnd))
      return numOfChildern != 0
      
    } else {
      Config.error("Not a tree level!")
      return false
    }
    
    
  }
  
  func findIssueTagWithLevel(_ level: Level) -> IssueTag? {
  
    for it in self._disconnected {
      guard let tag = it.tag else {
        Config.error("Found tag issue with tag!")
        return nil
      }
      
      if tag.level == level {
        return it
      }
    }
    return nil
  
  }
  
  func findTagWithLevel(_ level: Level) -> Tag? {

    if let issueTag =  self.findIssueTagWithLevel(level) {
      return issueTag.tag
    } else {
      return nil
    }
  }
  
  var missingTagInformation : Bool {
    get {
      return self.nextLevelExists
    }
    
  }


  func pop() -> Tag? {


    var lastObject: IssueTag?

    if editMode {
      if editLevelPointer == 0 || editLevelPointerStack?.count == 0 {
        return nil
      } else {

        guard let pointerStack = editLevelPointerStack else {
          Config.error()
          return nil
        }
        guard let stack = editLevelStack else {
          Config.error()
          return nil
        }

        editLevelPointer = pointerStack.last!
        editLevelPointerStack?.removeLast()
        let poppedLevel = stack[editLevelPointer]

        guard let issueTag = self.findIssueTagWithLevel(poppedLevel) else {
          Config.error("editLevelPointer: \(editLevelPointer), poppedLevel: \(poppedLevel.nonEmptyTitle)")
          return nil
        }
        lastObject = issueTag

      }
    } else {

      guard let lo = self.sorted.last else {
        return nil
      }
      
      lastObject = lo

    }


    if let lastObject = lastObject {
      self.poppedTag = nil
      
      
      if lastObject.tag!.isInputType {
        self.savedInputTag = lastObject.tag
        self.savedInput = lastObject.input
        
      } else {
        self.savedInputTag = nil
        self.savedInput = nil
        
      }

      self._disconnected.remove(at: self._disconnected.index(of: lastObject)!)
      
      lastObject.mr_deleteEntity()
      
      return lastObject.tag!
    } else {
      return nil
    }
       

  }


  func push(_ tag: Tag) -> IssueTag? {

    if editMode {

      // remove all possibly dependent issues from the stack
      if let poppedTag = self.poppedTag {
        self.removeDependentTagsWithTag(poppedTag)
      }


      editLevelPointerStack?.append(editLevelPointer)

      let currentLevel = tag.level
      guard let stack = self.editLevelStack else {
        Config.error()
        return nil
      }

      guard let index = stack.index(of: currentLevel) else {
        Config.error()
        return nil
      }
      editLevelPointer = index


    }

    self.poppedTag = nil


    let issueTag = IssueTag.mr_createEntity()!
    issueTag.setModified()
    issueTag.tag = tag
    
    self._disconnected.append(issueTag)

    if editMode {

      // augment the edit pointer to the next tag
      editLevelPointer += 1

      // jump levels if need be
      if let level = self.nextLevel, let stack = editLevelStack {
        guard let index = stack.index(where: { $0 == level }) else {
          Config.error()
          editMode = false
          return nil
        }
        editLevelPointer = index
      }

    }

    return issueTag

  }


  func removeDependentTagsWithTag(_ tag: Tag) {

    if let index = self._disconnected.index(where: { $0.tag == tag }) {
      let issueTag = self._disconnected[index]
      issueTag.mr_deleteEntity()
      
      self._disconnected.remove(at: index)
    }

    if let children = tag.level.children?.allObjects as? [Level], children.count > 0 {
      
      for child in children {
        
        if let index = self._disconnected.index(where: { $0.tag!.level == child })  {
          
          let issueTag = self._disconnected[index]
          self.removeDependentTagsWithTag(issueTag.tag!)
        }
        
      }
    }

  }

  func startEditModeWithLevel(_ level: Level) {

    self.editMode = true

    self.editLevelStack = []
    self.editLevelPointer = 0
    self.editLevelPointerStack = []
    self.populateEditLevelStackFromLevel(level)

    let set = Set(self.editLevelStack!)
    self.editLevelStack = Array(set)
    self.editLevelStack!.sort(by: { l1, l2 in
      l1.level.intValue < l2.level.intValue
    })

    guard let issueTag = self.findIssueTagWithLevel(level) else {
      Config.error()
      return
    }
    guard let tag = issueTag.tag else {
      Config.error()
      return
    }
    
    self.poppedTag = tag
    
    if tag.type == .Input || tag.type == .NumericInput {
      self.savedInputTag = tag
      self.savedInput = issueTag.input
    }


  }


  func populateEditLevelStackFromLevel(_ level: Level) {

    self.editLevelStack!.append(level)

    let children = Level.mr_findAllSorted(by: "level", ascending: true, with: NSPredicate(format: "parent = %@", level)) as! [Level]
    
    for child in children {
      self.populateEditLevelStackFromLevel(child)
    }
  }


  func tagPreviousToLevel(_ level: Level) -> Tag? {
    
    if level.level.int32Value == 0 {
      return nil
    } else {
      let sorted = self.sorted
      if let indexOfTag = sorted.index(where: {$0.tag!.level == level }) {
        if indexOfTag > 0 {
          let item = sorted[indexOfTag.advanced(by: 1)]
          return item.tag
        }
      } else {
        return nil
      }
    }
    return nil
    
  }
}


