//
//  DragViewCache.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-03-02.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
import CoreData

class DragViewCache : NSObject, NSFetchedResultsControllerDelegate {
  
  weak var issueImageCache: IssueImageCache!
  var allAreasFrc: NSFetchedResultsController<NSFetchRequestResult>?
  weak var pillRackBackground: UIView!
  
  weak var newPill: DragView!
  var previousPills: [DragView]!
  
  var recentlyUsed: [DragView] {
    get {
      return self.previousPills.filter( {$0.mode == DragViewMode.recentlyUsed && $0.inUse })
    }
  }
  
  var copied: [DragView] {
    get {
      return self.previousPills.filter( {$0.mode == DragViewMode.copied && $0.inUse })
    }
  }
  
  var locked: [DragView] {
    get {
      return self.previousPills.filter( {$0.mode == DragViewMode.locked && $0.inUse })
    }
  }
  
  weak var parentView: UIView!
  weak var acv: AreaViewController!
  
  let issuePadding: CGFloat = 10
  
  init(withParentView: UIView, andAVC: AreaViewController, andImageCache: IssueImageCache) {
    
    self.parentView = withParentView
    self.acv = andAVC
    self.issueImageCache = andImageCache
    
    self.pillRackBackground = self.acv.pillRackBackgroundView
    self.previousPills = []
    
    super.init()
    
    
    self.fetchAllIssuesForProject()
  }
  
  func fetchAllIssuesForProject() {
    let req = NSFetchRequest<NSFetchRequestResult>(entityName: "Issue")
    let sort = NSSortDescriptor(key: "createdDate", ascending: false)
    req.predicate = NSPredicate(format: "area.project = %@", self.acv.project)
    req.sortDescriptors = [sort]
    self.allAreasFrc = NSFetchedResultsController( fetchRequest: req,
      managedObjectContext: NSManagedObjectContext.mr_default(),
      sectionNameKeyPath: nil,
      cacheName: nil)
    self.allAreasFrc?.delegate = self
    do {
      try self.allAreasFrc?.performFetch()
    } catch _ as NSError {
      Config.error("Couldn't perform fetch request")
    }
  }
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    
    var savedLockedCenters: [Issue: CGPoint] = [:]
    var savedCopiedCenters: [Issue: CGPoint] = [:]
    
    for dv in self.locked {
      savedLockedCenters[dv.aTag!] = dv.center
    }
    
    for dv in self.copied {
      savedCopiedCenters[dv.aTag!] = dv.center
    }
    
    self.updateAnchors()
    
    for dv in self.locked {
      if let prevCenter = savedLockedCenters[dv.aTag!] {
        self.slideDragView(dv, fromCenter: prevCenter)
        
      } else {
        for ru in self.recentlyUsed {
          if ru.aTag == dv.aTag {
            self.slideDragView(dv, fromCenter: ru.center)
          }
        }
      }
    }
    
    for dv in self.copied {
      if let prevCenter = savedCopiedCenters[dv.aTag!] {
        self.slideDragView(dv, fromCenter: prevCenter)
        
      } else {
        guard let iv = self.acv.issueViewCache.findIssueViewWithIssue(dv.aTag!) else {
          continue
        }
        self.slideDragView(dv, fromCenter: iv.center)
        
      }
    }
    
  }
  
  func slideDragView(_ dv: DragView, fromCenter: CGPoint) {
    
    let origCenter = dv.center
    dv.center = fromCenter
    
    if fromCenter == origCenter {
      return
    }
    
    UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
      dv.center = origCenter
    }, completion: { finished in })
    
  }
  
  func updateAnchors() {
    
    if self.allAreasFrc == nil { return }
    
    // Do not clear anchors while one is in use.
    if self.acv.activeIssue != nil { return }
    
    self.clearAnchors()
    self.updateNewPill()
    

    let numberOfRecentIssues = 4
    self.updateLockedCopiedAndRecentConstraints(numberOfRecentIssues)
    self.loadLockedAndCopiedIssues()

    var tagsDict: [Int: Issue] = [:]
    var entries: [Int] = []
    for issue in self.allAreasFrc!.fetchedObjects as! [Issue] {
      let hash = issue.issueTagHash
      if tagsDict[hash] == nil {
        tagsDict[hash] = issue
        entries.append(hash)
      }
    }

    let maxAnchor = min(numberOfRecentIssues, tagsDict.count)
    if tagsDict.count > 0 {
      self.acv.recentlyUsedLabel.isHidden = false
      for i in 0...maxAnchor - 1 {
        self.addRecentDragForIssue(tagsDict[entries[i]]!, numbered: i)
      }
    } else {
      self.acv.recentlyUsedLabel.isHidden = true
    }
    
  }

  func loadLockedAndCopiedIssues() {

    if let lockedIssues = self.acv.project.lockedIssues {
      for (idx, issue) in lockedIssues.enumerated() {
        self.addLockedDragForIssue(issue as! Issue, numbered: idx)
      }
    }
    
    if let copiedIssues = self.acv.project.copiedIssues {
      for (idx, issue) in copiedIssues.enumerated() {
        self.addCopiedDragForIssue(issue as! Issue, numbered: idx)
      }
    }

  }

  func updateLockedCopiedAndRecentConstraints(_ numberOfRecentIssues: Int) {

    let numberOfLockedIssues = self.acv.project.lockedIssues!.count == 0 ? 0 : 3
    let numberOfCopiedIssues = self.acv.project.copiedIssues!.count == 0 ? 0 : 3

    // calculate constraints
    self.acv.recentlyUsedTrailingSpace.constant =
      (self.issuePadding * 4 + Config.draggingHandleSize) +
      CGFloat(numberOfRecentIssues) * (Config.speedrackSize + self.issuePadding)
    
    if numberOfLockedIssues == 0 {
      self.acv.lockedLabelTrailingSpace.constant = self.acv.recentlyUsedTrailingSpace.constant
    } else {
      self.acv.lockedLabelTrailingSpace.constant =
        self.acv.recentlyUsedTrailingSpace.constant +
        CGFloat(numberOfLockedIssues) * (Config.speedrackSize + self.issuePadding) +
        3 * self.issuePadding
      
    }
    
    self.acv.copiedLabelTrailingSpace.constant =
      self.acv.lockedLabelTrailingSpace.constant +
      CGFloat(numberOfCopiedIssues) * (Config.speedrackSize + self.issuePadding) +
      3 * self.issuePadding
    
    self.acv.lockedLabel.isHidden = numberOfLockedIssues == 0 ? true : false
    self.acv.copiedLabel.isHidden = numberOfCopiedIssues == 0 ? true : false
    
    self.acv.lockedLabel.needsUpdateConstraints()
    self.acv.copiedLabel.needsUpdateConstraints()
    self.acv.recentlyUsedLabel.needsUpdateConstraints()

  }

  
  func clearAnchors() {
    
    for dv in self.previousPills {
      dv.inUse = false
      dv.isHidden = true
    }
  }
  
  func updateNewPill() {
    
    let issueSize: CGFloat = Config.draggingHandleSize
    let yOffset: CGFloat = (74 - issueSize) / 2
    
    let pos: CGFloat =  -(issueSize + self.issuePadding)
    let point = CGPoint(x: self.acv.view.frame.width + pos, y: self.acv.view.frame.height - issueSize - yOffset)
    
    if let dv = self.newPill {
      dv.reset()
      dv.remakeFrame(point)
      dv.mode = .new
      
    } else {
      
      let dv = DragView(project: self.acv.project, tag: nil, anchor: point, imageCache: self.issueImageCache)
      dv.areaViewController = self.acv
      self.parentView.addSubview(dv)
      self.newPill = dv
      dv.mode = .new
    
    }
    
  }
  
  func addRecentDragForIssue(_ issue: Issue, numbered: Int) {
    
    let point = self.calculatePositionUsingRightMargin(self.acv.recentlyUsedTrailingSpace.constant, numbered: numbered)
    let dv = self.loadOrCreateNewDragView(issue, point: point)
    dv.mode = .recentlyUsed

  }
  
  func addLockedDragForIssue(_ issue: Issue, numbered: Int) {
    
    let point = self.calculatePositionUsingRightMargin(self.acv.lockedLabelTrailingSpace.constant, numbered: numbered)
    let dv = self.loadOrCreateNewDragView(issue, point: point)
    dv.mode = .locked
    
  }
  
  func addCopiedDragForIssue(_ issue: Issue, numbered: Int) {
    
    let point = self.calculatePositionUsingRightMargin(self.acv.copiedLabelTrailingSpace.constant, numbered: numbered)
    let dv = self.loadOrCreateNewDragView(issue, point: point)
    dv.mode = .copied
    
  }
  
  func calculatePositionUsingRightMargin(_ margin: CGFloat, numbered: Int) -> CGPoint {
    
    let initialXPosition: CGFloat = self.acv.view.frame.width - margin
    let issueSize: CGFloat = Config.speedrackSize
    let yOffset: CGFloat = (74 - Config.draggingHandleSize) / 2
    
    let pos = CGFloat(numbered) * (issueSize + self.issuePadding) + initialXPosition
    return CGPoint(x: pos, y: self.acv.view.frame.height - issueSize - yOffset)
  }
  
  
  func loadOrCreateNewDragView(_ issue: Issue, point: CGPoint) -> DragView {
    
    if let dv = self.previousPills.filter({$0.inUse == false }).first {
      
      dv.reset()
      dv.remakeFrame(point)
      dv.resetWithNewIssue(issue)
      dv.inUse = true
      dv.isHidden = false
      return dv
      
    } else {
      let dv = DragView(project: self.acv.project, tag: issue, anchor: point, imageCache: self.issueImageCache)
      dv.areaViewController = self.acv
      self.parentView.addSubview(dv)
      self.previousPills.append(dv)
      return dv
    }
  }
  
  func hideViews() {
    self.parentView.isHidden = true
    
  }
  
  func showViews() {
    self.parentView.isHidden = false
    
  }
  
 
  func redrawDragHiddenOrNot() {
    
    
    if self.acv.hideDragIssues {
      self.acv.pillRackBackgroundView.isHidden = true
      
    } else {
      self.acv.pillRackBackgroundView.isHidden = false
      
    }
    
    for view in self.parentView.subviews {
      if let drag = view as? DragView {
        
        if drag.inUse == false {
          continue
        }
        
        if self.acv.hideDragIssues {
          
          if drag.isDragging == true  && self.acv.drag != drag {
            drag.dragDidCancel()
          }
          
          if drag.isDragging == true {
            drag.isHidden = false
          } else {
            drag.isHidden = true
          }
          
        } else {
          drag.isHidden = false
        }
      }
    }
  }
}
