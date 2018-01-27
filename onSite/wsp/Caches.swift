//
//  Caches.swift
//  wsp
//
//  Created by Filip Wolanski on 2017-01-27.
//  Copyright © 2017 Ubriety. All rights reserved.
//

import Foundation


class Caches {

  var levelActions: [String: [String:LevelAction]] = [:]
  var issueTagHashes: [String: Int] = [:]


  func getLevelAction(_ level: Level, tag: Tag?) -> LevelAction? {
    let levelId = level.localId
    var tagId = " "
    if let tag = tag {
      tagId = tag.localId
    }

    if levelActions[levelId] == nil {
      levelActions[levelId] = [:]
    }

    return levelActions[levelId]![tagId]
  }

  func setLevelAction(_ level: Level, tag: Tag?, action: LevelAction) {

    let levelId = level.localId

    var tagId = " "
    if let tag = tag {
      tagId = tag.localId
    }

    if levelActions[levelId] == nil {
      levelActions[levelId] = [:]
    }

    levelActions[levelId]![tagId] = action

  }

  func setIssueTagHash(_ issue: Issue, hash: Int) {
    issueTagHashes[issue.localId] = hash
  }

  func getIssueTagHash(_ issue: Issue) -> Int? {

    return issueTagHashes[issue.localId]

  }

  func invalidateIssueTagHash(_ issue: Issue) {
    let key = issue.localId

    if issueTagHashes[key] != nil {
      issueTagHashes.removeValue(forKey: key)
    }

  }

  func invalidateLevelActions(forLevel level: Level) {
    levelActions.removeValue(forKey: level.localId)
  }

}
