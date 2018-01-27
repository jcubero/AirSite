//
//  IssueViewCache.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-02-08.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit


class IssueViewCache {
  

  // to change to in the future
  // var issueViews: Array<WeakContainer<IssueView>> = []
  var issueViews: [IssueView] = []
  var arrowViews: [ArrowHandleView] = []
  
  let issueImageCache: IssueImageCache
  
  
  weak var parentView: UIView!
  weak var acv: AreaViewController!
  weak var arrowView: UIView!
  
  var lastAdded: IssueView?
  
  var used: [IssueView] {
    get {
      return self.issueViews.filter({ $0.used })
    }
  }
  
  var usedArrows: [ArrowHandleView] {
    get {
      return self.arrowViews.filter({$0.used })
    }
  }

  
  var count: Int {
    get {
      return self.used.count
    }
  }
  
  var movingIssue: Issue? {
    get {
      for view in self.used {
        if view.isMoving {
          return view.issue
        }
      }
      return nil
    }
  }
  
  init(withParentView: UIView, andAVC: AreaViewController, andArrowView: UIView) {
    
    self.parentView = withParentView
    self.acv = andAVC
    self.arrowView = andArrowView
    self.issueImageCache = IssueImageCache(project: self.acv.project)
    
  }
  
  
  func addIssue(_ project: Project, issue: Issue, area: AreaViewController, areaRect: CGRect, zoom: CGFloat, originalSize: CGSize) -> IssueView {
    
    var view: IssueView!
    
    if let issueView = self.issueViews.filter({ $0.used == false }).first {
      view = issueView
      
    } else {
      let issueView = IssueView(project: project, imageCache: self.issueImageCache)
      self.issueViews.append(issueView)
      self.parentView.addSubview(issueView)
      view = issueView
    }
    
    view.updateIssueWithProject(project, issue: issue, area: area, areaRect: areaRect, zoom: zoom, originalSize: originalSize)
    view.isHidden = false
    self.lastAdded = view
    
    // arrows
    var arrowView: ArrowHandleView!
    if let v = self.arrowViews.filter({ $0.used == false }).first {
      arrowView = v
      
    } else {
      let v = ArrowHandleView(area: self.acv)
      self.arrowViews.append(v)
      self.arrowView.addSubview(v)
      arrowView = v
    }
    
    arrowView.loadWithIssue(issue, areaRect: areaRect, zoom: zoom, originalSize: originalSize)
    arrowView.isHidden = false
    arrowView.used = true
    
    
    return view
  }
  
  
  func removeAllIssues() {
    
    for view in self.issueViews {
      
      view.isHidden = true
      view.used = false
    }
    
    for view in self.arrowViews {
      view.isHidden = true
      view.used = false
    }
    
  }
  
  func findIssueViewWithIssue(_ issue: Issue) -> IssueView? {
    
    for view in self.used {
      if view.issue == issue {
        return view
      }
    }
    
    return nil
    
  }
  
  func removeLastAddedIssue() {
    
    self.lastAdded?.isHidden = true
    self.lastAdded?.used = false
    
    if let l = self.lastAdded {
      let issue = l.issue
      
      if let arrowView = self.usedArrows.filter( {$0.issue == issue }).first {
        arrowView.isHidden = true
        arrowView.used = false
        
      }
    }
  }
  
  
  func removeViewWithIssue(_ issue: Issue) {
    
    for view in self.used {
      if view.issue == issue {
        view.isHidden = true
        view.used = false
        view.issue = nil
      }
    }
    
    for view in self.usedArrows {
      if view.issue == issue {
        view.isHidden = true
        view.used = false
        view.issue = nil
      }
    }
    
  }
  
  
  func redrawIssueLighterOrDarker() {
    
    var viewToMoveToTop: UIView?
    for view in self.used {
      if self.acv.drawLighter && !self.acv.darkerIssue(view.issue) {
        view.imageView.alpha = 0.3
        view.strokeView.alpha = 0.3
      } else {
        view.imageView.alpha = 1.0
        view.strokeView.alpha = 1.0
        if self.acv.drawLighter {
          viewToMoveToTop = view
        }
      }
    }
    
    if let v = viewToMoveToTop {
      self.parentView.bringSubview(toFront: v)
    }
    
  }
  
  func hideIssues() {
    for issue in self.used {
      issue.isHidden = true
    }
    
    for issue in self.usedArrows {
      issue.isHidden = true
    }
    
  }
  
  func showIssues() {
    for issue in self.used {
      issue.isHidden = false
    }
    
    for issue in self.usedArrows {
      issue.isHidden = false
    }
  }
  
  func updateIssueLocations(_ areaRect: CGRect, areaZoom: CGFloat) {
    
    for issue in self.used {
      issue.updateLocation(areaRect, zoom: areaZoom)
    }
    
    for arrow in self.usedArrows {
      arrow.updateLocation(areaRect, zoom: areaZoom)
    }
    
  }
  
  func updateIssueLabels(_ onlyIssue: Issue? = nil) {
    
    for issue in self.used {
      if onlyIssue != nil {
        if onlyIssue == issue.issue {
          issue.renderImageAndColorForTag(issue.issue)
        }
      } else {
        issue.renderImageAndColorForTag(issue.issue)
      }
    }
  }
  
  func arrowViewForIssue(_ issue: Issue) -> ArrowHandleView? {
    
    for view in self.usedArrows {
      if view.issue == issue {
        return view
      }
    }
    
    return nil
    
  }
  
}
