//
//  Level.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-10-21.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord
import PromiseKit

enum LevelAction {
  case process, skip, end
}

@objc(Level)

class Level: SyncableModel {


  // properties
  @NSManaged var isColorLevel: NSNumber
  @NSManaged var title: String?
  @NSManaged var level: NSNumber
  @NSManaged var isTreeLevel: NSNumber
  @NSManaged var isShapeLevel: NSNumber
 
  // relationships
  @NSManaged var project: Project
  @NSManaged var tags: NSSet?
  @NSManaged var parent: Level?
  @NSManaged var children: NSSet?
  
  override class func registerSyncableData(_ converter: RemoteDataConverter) {
  
    converter.registerRemoteData("title", remote: "title", type: .String)
    converter.registerRemoteData("level", remote: "level_int", type: .Integer)
    converter.registerRemoteData("isColorLevel", remote: "is_color", type: .Boolean)
    converter.registerRemoteData("isTreeLevel", remote: "is_tree", type: .Boolean)
    converter.registerRemoteData("isShapeLevel", remote: "is_shape_level", type: .Boolean)
    
    converter.registerRemoteData("tags", remote: "tags", type: .Entities, entity: "Tag", unit: .Separate)
    
    converter.registerRemoteData("parent", remote: "parent", type: .Relationship, entity: "Level")
    
    
  }
  
  var isTopLevel: Bool {
    get {
      return self.level.int32Value == 0 ? true : false
    }
  }
  
  var nonEmptyTitle: String {
    get {
      var title = "Untitled Category \(level.int32Value)"
      if let t = self.title {
        if t != "" {
          title = t
        }
      }
      return title
    }
  }
  
  var hasShapes: Bool { get { return self.isShapeLevel.boolValue } }
  
  var hasColors: Bool { get { return self.isColorLevel.boolValue } }
  
  var nextLevelExists: Bool {
    get {
      let nextLevel = self.level.int32Value + 1
      
      let predicate = NSPredicate(format: "project = %@ and level = %@", self.project, NSNumber(value: Int(nextLevel)))
      if let _ = Level.mr_findFirst(with: predicate) {
        return true
      } else {
        return false
      }
    }
    
  }
  
  var nextLevel: Level? {
    get {
      let nextLevel = self.level.int32Value + 1
      let predicate = NSPredicate(format: "project = %@ and level = %@", self.project, NSNumber(value: Int(nextLevel)))
      return Level.mr_findFirst(with: predicate)
    }
    
  }
  
  var previousLevel: Level? {
    get {
      if self.level.int32Value == 0 {
        return nil
      }
      let nextLevel = self.level.int32Value - 1
      let predicate = NSPredicate(format: "project = %@ and level = %@", self.project, NSNumber(value: Int(nextLevel)))
      return Level.mr_findFirst(with: predicate)
    }
    
  }
  
  var topParent: Level? {
    get {
      if self.isTreeLevel.boolValue {
        guard var parent = self.parent else {
          Config.error("Tree level defined with no parent!")
          return nil
        }
        while (parent.isTreeLevel.boolValue) {
          guard let p = parent.parent else {
            Config.error("Tree level defined with no parent!")
            return nil
          }
          parent = p
        }
        
        return parent
        
      } else {
        return nil
        
      }
    }
  }
  
  func characterColumn(_ inContext: NSManagedObjectContext? = nil) -> String {
    
    let context = inContext == nil ? NSManagedObjectContext.mr_default() : inContext!
    
    let levels = Level.mr_findAll(with: NSPredicate(format: "level <= %@ and project = %@", self.level, self.project), in: context) as! [Level]
    
    var count: Int = 0
    for level in levels {
      if level.isColorLevel.boolValue {
        count += 1
      }
      
      if level.isShapeLevel.boolValue {
        count += 1
      }
      count += 1
    }
    
    return BRAColumn.columnName(forColumnIndex: count)
    
  }
  
  
  func makeThisAColorLevel() {
    let predicate = NSPredicate(format: "project = %@", self.project)
    let levelsForProject = Level.mr_findAll(with: predicate) as! [Level]
    
    for level in levelsForProject {
      level.isColorLevel = false
    }
    
    self.isColorLevel = true
    Manager.sharedInstance.saveCurrentState(nil)
  
  }
  
  func makeThisAShapeLevel() {
    let predicate = NSPredicate(format: "project = %@", self.project)
    let levelsForProject = Level.mr_findAll(with: predicate) as! [Level]
    
    for level in levelsForProject {
      level.isShapeLevel = false
    }
    
    self.isShapeLevel = true
    Manager.sharedInstance.saveCurrentState(nil)
  
  }
  
  func levelAfterLevel(_ level: Level) -> Level? {
    
    if self.isTreeLevel.boolValue {
      var parent = self.parent!
      if parent == level {
        return self
      }
      while (parent.isTreeLevel.boolValue) {
        if parent.parent! == level {
          return parent
        }
        parent = parent.parent!
        
      }
      return parent
      
    } else {
      return nil
      
    }
    
  }
  
  func hasInput(_ parent: Tag?) ->  Bool {
    
    let predicate = NSPredicate(format: "level = %@", self)
    let formatPred = NSPredicate(format: "typeString ==[c] %@ || typeString ==[c] %@", TagType.NumericInput.rawValue, TagType.Input.rawValue)
    
    if self.isTreeLevel.boolValue && !self.isTopLevel {
      if let tag = parent {
        let pred = NSPredicate(format: "parent = %@", tag)
        return Tag.mr_countOfEntities(with: NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, formatPred, pred])) == 0 ? false : true
      } else {
        Config.error("Parent must always be set for tree-level tags")
        return true
      }
      
    } else {
      return Tag.mr_countOfEntities(with: NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, formatPred])) == 0 ? false : true
    }
    
  }
  
  
  func createNextLevelWithTree(_ hasTree: Bool, basedOnLevel: Level?) -> Level {
    
    let nextLevel = self.level.int32Value + 1
    let predicate = NSPredicate(format: "project = %@ and level = %@", self.project, NSNumber(value: Int(nextLevel)))
    
    if let _ = Level.mr_findFirst(with: predicate) {
      Config.error("Next level already exists!")
      abort()
    }
    
    let level = Level.createLevelForProject(self.project, level: Int(nextLevel))
    
    if hasTree && basedOnLevel == nil {
      Config.error("Cannot create a tree level with no parent")
    }
    
    level.isTreeLevel = hasTree as NSNumber
    level.parent = basedOnLevel
    
    
    
    return level
    
  }
  
  
  func levelAction(_ withParent: Tag?) -> LevelAction {

    let caches = Manager.sharedInstance.caches

    if let action = caches?.getLevelAction(self, tag: withParent) {
      return action
    }


    var action: LevelAction!

    var pred = NSPredicate(format: "level = %@", self)
    if self.isTreeLevel.boolValue {
      
      
      var parentPred: NSPredicate!
      if let parent = withParent {
        parentPred = NSPredicate(format: "parent = %@", parent)
      } else {
        parentPred = NSPredicate(format: "parent = nil")
      }
      pred = NSCompoundPredicate(andPredicateWithSubpredicates: [pred, parentPred])
    }
    
    let tagCount = Tag.mr_numberOfEntities(with: pred)
    
    if tagCount == 0 {
      action = .skip
    } else {

      pred = NSCompoundPredicate(andPredicateWithSubpredicates: [pred, Tag.endPredicate])
      let tagEndCount = Tag.mr_numberOfEntities(with: pred)
      
      if tagEndCount == 0 {
        action = .process
      } else {
        action = .end
      }
    }
    
    caches?.setLevelAction(self, tag: withParent, action: action)
    return action
    
  }
  
  func setLevelAction(_ action: LevelAction, withParent: Tag?) {
    
    // add end tag
    if action == .end {
      var parent: Tag?
      if self.isTreeLevel.boolValue {
        guard let p = withParent else {
          Config.error("Parent undefined!")
          return
        }
        parent = p
      }
      
      let endTag = Tag.mr_createEntity()!
      endTag.setModified()
      endTag.title = Tag.TagTitleEnd
      endTag.parent = parent
      endTag.level = self
    } else {
      
      // remove end tags
      
      var pred = NSPredicate(format: "level = %@", self)
      if self.isTreeLevel.boolValue {
        guard let parent = withParent else {
          Config.error("Parent undefined!")
          return
        }
        let parentPred = NSPredicate(format: "parent = %@", parent)
        pred = NSCompoundPredicate(andPredicateWithSubpredicates: [pred, parentPred])
      }
      
      pred = NSCompoundPredicate(andPredicateWithSubpredicates: [pred, Tag.endPredicate])
      
      let endTags = Tag.mr_findAll(with: pred) as! [Tag]
      for tag in endTags {
        self.project.deleteProjectEntity(tag)
      }
      
    }
    
  }
  
  func getRemovalConcequences() -> String {
    
    let count = self.recursivelyProcessChildren(self, t: 0) { (level: Level, count: Int) -> Int in
      return count + 1
    }
    
    var prevSingular: String = "This action will remove this level."
    var prevPlural: String! = "This action will remove this level, "
    if count > 1 {
      let noun = count == 2 ? "level" : "levels"
      prevSingular = prevPlural + "and \(count - 1) dependent \(noun)."
      prevPlural = prevPlural + "\(count - 1) dependent \(noun), "
    }
    
    let tagCount = self.recursivelyProcessChildren(self, t: 0) { (level: Level, count: Int) -> Int in
      return count + level.tags!.allObjects.count
    }
    let noun = tagCount == 1 ? "tag" : "tags"
    if tagCount > 0 {
      prevSingular = prevPlural +  " and \(tagCount) \(noun)."
      prevPlural = prevPlural +  "\(tagCount) \(noun), "
    }
    
    let issueCount = self.recursivelyProcessChildren(self, t: 0) { (level: Level, count: Int) -> Int in
      var isc = 0
      for tag in level.tags!.allObjects as! [Tag] {
        isc += tag.issueTags!.count
      }
      return count + isc
    }
    if issueCount > 0 {
      let mod = tagCount == 1 ? "this" : "these"
      prevSingular = prevPlural + "and remove \(mod) \(noun) from \(issueCount) observations."
    }
    
    return prevSingular
    
  }
  
  func recursivelyProcessChildren<T>(_ parent: Level, t: T, fn: ((Level, T) -> T)) -> T {
    var t = t
    
    t = fn(parent, t)
  
    for child in parent.children?.allObjects as! [Level] {
      t = self.recursivelyProcessChildren(child, t: t, fn: fn)
      
    }
    return t
    
  }
  
  
  func delete() {
    let project = self.project
    project.deleteProjectEntity(self)
    
    
    // renumber levels
    
    let levels = Level.mr_find(byAttribute: "project", withValue: project, andOrderBy: "level", ascending: true) as! [Level]
    var i = 0
    for level in levels {
        level.level = NSNumber(integerLiteral: i)
      i += 1
    }
  }
  
  static func getOrCreateLevelForProject(_ project: Project, level: Int, inContext: NSManagedObjectContext? = nil) -> Level {
    
    let context = inContext == nil ? NSManagedObjectContext.mr_default() : inContext!
    
    let predicate = NSPredicate(format: "project = %@ and level = %@", project, NSNumber(value: level as Int))
    if let level = Level.mr_findFirst(with: predicate, in: context) {
      return level
    } else {
      return Level.createLevelForProject(project, level: level, inContext: context)
    }
  }
  
  static func createLevelForProject(_ project: Project, level: Int, inContext: NSManagedObjectContext? = nil) -> Level {
    
    let context = inContext == nil ? NSManagedObjectContext.mr_default() : inContext!
    
    let obj = Level.mr_createEntity(in: context)!
    obj.project = project
    obj.level = NSNumber(integerLiteral: level) //NSNumber(level)
    obj.setModified()
    
    return obj
    
  }
  
}
