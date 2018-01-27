//
//  Projects.swift
//  wsp
//
//  Created by Jon Harding on 2015-07-29.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

class ProjectSplitView: UISplitViewController, UIGestureRecognizerDelegate {
  
  var project: Project!

  weak var pages: PagesViewController!
  weak var nav: Nav!
  weak var container: ProjectContainerViewController!

  var navHidden: Bool = false {
    didSet {
      self.container.calculateFrames()
    }
  }

  var shouldNavHide: Bool = false

  var activeArea: Area? {
    didSet {
      self.pages.loadArea()
      self.container.updateTitle()
    }
  }
  
  var activeIssue: Issue? {
    didSet {
      if activeIssue == nil {
        self.container.removeHamburger()
        if shouldNavHide && !navHidden {
          toggleNav()
        }
      } else {
        self.container.addHamburger()
        if navHidden {
          toggleNav()
        }
      }

      self.nav.updateComments()
      self.pages.updateActiveIssue()
    }
  }
  
  var activeForm: Form? {
    didSet {
      self.pages.loadForm()
    }
  }

  var firstLoad = true

  override func viewDidLoad() {
    self.project.filter = Filter()
    
    let master = self.viewControllers[0] as! NavNavigationController
    master.myDelegate = self
    self.nav = master.viewControllers[0] as! Nav
    self.nav.project = self.project
    self.nav.rootView = self
    self.project.filter.delegates.addDelegate(self.nav)

    self.pages = self.viewControllers[1] as! PagesViewController
    self.pages.rootView = self
    self.pages.delegate = self
    self.pages.project = self.project!

    let swipeFromLeft = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(ProjectSplitView.handleSwipeFromLeft(_:)))
    swipeFromLeft.delegate = self
    swipeFromLeft.edges = .left
    view.addGestureRecognizer(swipeFromLeft)
    
    self.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
    self.presentsWithGesture = false
    
    
    self.preferredPrimaryColumnWidthFraction = 0.3125
    self.maximumPrimaryColumnWidth = 320
    self.minimumPrimaryColumnWidth = 300
    
  }

  deinit {
    self.project.filter = nil
  }

  override func viewDidAppear(_ animated: Bool) {

    if firstLoad {
      firstLoad = false
      self.pages.load()
      self.project.filter.delegates.addDelegate(self.pages)
      self.nav.selectFirstArea()
    }

  }
  
  func updateActiveIssueLabel() {
    if let issue = self.activeIssue {
      self.pages.updateActiveIssueLabel()
      self.nav.commentsView.loadComments(issue)
    }
  }
  
  override var preferredStatusBarStyle : UIStatusBarStyle {
    return UIStatusBarStyle.lightContent
  }
  
  func hideComments() {
    self.activeIssue = nil
  }
}

extension ProjectSplitView {
  
  @objc func handleSwipeFromLeft(_ rec: UISwipeGestureRecognizer) {
    self.showNav()
  }
  
  func handleSwipeFromRight(_ rec: UISwipeGestureRecognizer) {
    self.hideNav()
  }
  
  func showNav() {
    self.shouldNavHide = false
    if self.navHidden {
      self.toggleNav()
    }
  }
  
}

extension ProjectSplitView: NavNavigationControllerDelegate {
  func hideNav() {
    self.shouldNavHide = true

    if !self.navHidden {
      self.toggleNav()
    }
  }
}

extension ProjectSplitView: PagesViewControllerDelegate {
  func toggleNav() {
    
    self.pages.navModeWillChange()
    var displayMode: UISplitViewControllerDisplayMode?
    
    var interfaceTransition: (()->())?
    
    if self.navHidden {
      self.navHidden = false
      displayMode = UISplitViewControllerDisplayMode.allVisible
      interfaceTransition = {
        self.pages.navDidShow()
      }
    } else {
      self.navHidden = true
      displayMode = UISplitViewControllerDisplayMode.primaryHidden
      interfaceTransition = {
        self.pages.navDidHide()
      }
    }
    UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: { [unowned self] in
      self.preferredDisplayMode = displayMode!
      interfaceTransition?()
      }, completion: { [unowned self] finished in
        self.pages.navModeDidChange()
    })
  }
}
