//
//  IssueTag.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-12-14.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord
import PromiseKit


@objc(IssueTag)

class IssueTag: SyncableModel {
  
  // properties
  @NSManaged var input: String?
 
  // relationships
  @NSManaged var issue: Issue?
  @NSManaged var tag: Tag?

  override class func registerSyncableData(_ converter: RemoteDataConverter) {
    
    converter.registerRemoteData("input", remote: "input", type: .String)
    converter.registerRemoteData("tag", remote: "tag", type: .Relationship, entity: "Tag")
    
  }
 
  var title: String {
    get {
      guard let tag = self.tag else {
        Config.error("Invalid IssueTag")
        return ""
      }
      
      if tag.isInputType {
        guard let title = tag.title else {
          Config.error("Invalid IssueTag")
          return ""
        }
        
        guard let input = self.input else {
          return title
        }
        
        var replacement = Tag.TagTitleInput
        if tag.type == .NumericInput {
          replacement = Tag.TagTitleNumericInput
        }
        
        return title.replacingOccurrences(of: replacement, with: input)
        
      }
      
      return tag.nonEmptyTitle
    }
  }
  
  var attributedTitle: NSAttributedString {
    get {
      let empty = NSAttributedString(string: "")
      guard let tag = self.tag else {
        Config.error("Invalid IssueTag")
        return empty
      }
      
      if tag.isInputType {
        guard let title = tag.title else {
          Config.error("Invalid IssueTag")
          return empty
        }
        
        guard let input = self.input else {
          return tag.nonEmptyAttributedTitle
        }
        
        var replacement = Tag.TagTitleInput
        if tag.type == .NumericInput {
          replacement = Tag.TagTitleNumericInput
        }
        
        return NSAttributedString(string: title.replacingOccurrences(of: replacement, with: input))
        
      }
      
      return tag.nonEmptyAttributedTitle
    }
    
  }

  var shouldHideTag: Bool {
    guard let tag = self.tag else {
      Config.error("Invalid IssueTag")
      return true
    }
    return tag.shouldHideTag
  }
  
  static func removeOrphanedIssueTags() {
   
    let predicate = NSPredicate(format: "issue = nil or tag = nil")
    for issueTag in IssueTag.mr_findAll(with: predicate)! {
      issueTag.mr_deleteEntity()
    }
    
  }
  
  
}
