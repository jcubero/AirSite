//
//  LibraryPopover.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-08-01.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

protocol CategoryPopoverDelegate: class {
  
  func tagDidCancel()
  func tagDidSet(_ tagCollection: TagCollection)
  func tagDidChange(_ tagCollection: TagCollection?)
  func filterByTag(_ tagCollection: TagCollection)
  func filterByAggregate(_ filter: AggregateFilter)

}


enum LibraryPopoverMode {
  case select, edit, filterTree, filterTag
}


class LibraryPopover: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
  
  var project: Project!
  var pageViewController: UIPageViewController!
  var tagCollection: TagCollection!
  var sourceIssue: Issue?
  
  weak var delegate: CategoryPopoverDelegate?

  var mode: LibraryPopoverMode = .select
  var imageCache: IssueImageCache!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    if mode == .edit && tagCollection == nil {
      Config.error("Cannot edit a nil collection.")
      return
    }
    
    if self.tagCollection == nil {
      self.tagCollection = TagCollection(withIssue: nil, andProject: self.project)
    }

    if mode == .edit || mode == .filterTag {
      self.showLevels(true)
    } else {
      self.showCategory(true)
    }


  }

  func showLevels(_ forward: Bool) {

    let storyboard = UIStoryboard(name: "Library", bundle: nil)
    let page = storyboard.instantiateViewController(withIdentifier: "LibraryLevelView") as! LibraryLevelView
    page.delegate = self
    page.imageCache = self.imageCache
    page.tagCollection = self.tagCollection
    page.project = project
    page.mode = mode

    var direction = UIPageViewControllerNavigationDirection.forward
    if forward == false {
      direction = UIPageViewControllerNavigationDirection.reverse
    }

    self.pageViewController.setViewControllers([page], direction: direction, animated: true, completion: nil)

  }

  
  func showCategory(_ forward: Bool) {
    
    let storyboard = UIStoryboard(name: "Library", bundle: nil)
    let page = storyboard.instantiateViewController(withIdentifier: "LibraryCategoryView") as! LibraryCategoryView
    page.delegate = self
    page.mode = mode
    page.imageCache = self.imageCache
    
    page.tagsCollection = self.tagCollection
    
    var direction = UIPageViewControllerNavigationDirection.forward
    if forward == false {
      direction = UIPageViewControllerNavigationDirection.reverse
    }
    
    self.pageViewController.setViewControllers([page], direction: direction, animated: true, completion: nil)
    
  }

  func showAggregatedCategory(_ level: Level) {
    
    let storyboard = UIStoryboard(name: "Library", bundle: nil)
    let page = storyboard.instantiateViewController(withIdentifier: "LibraryAggregateCategoryView") as! LibraryAggregateCategoryView
    page.delegate = self
    page.imageCache = self.imageCache
    page.level = level
    page.filter = project.filter
    
    let direction = UIPageViewControllerNavigationDirection.forward

    self.pageViewController.setViewControllers([page], direction: direction, animated: true, completion: nil)
    
  }


  func cloneTagsFromSourceIssue() {
    guard let issue = self.sourceIssue else {
      Config.error()
      return
    }
    self.tagCollection = issue.tagsCollection
    self.tagCollection.clone()

  }

  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if self.tagCollection.missingTagInformation {
      self.delegate?.tagDidCancel()
    } 
  }
  
  @IBAction func dismiss(_ sender: AnyObject) {
    self.didCancel()
  }

  func didCancel() {

    if mode == .filterTag {
      self.showLevels(false)
      return
    }

    if tagCollection.editMode {

      self.cloneTagsFromSourceIssue()
      self.showLevels(false)
      return
    }

    self.dismiss(animated: true, completion: nil)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let vc = segue.destination as? UIPageViewController {
      self.pageViewController = vc
    }
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    return nil
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    return nil
  }
  
}

extension LibraryPopover: LibraryCategoryDelegate, LibraryAggregateDelegate {
  
  func tagDidChange() {
    self.delegate?.tagDidChange(tagCollection)
  }
  
  func tagDidSet() {
    self.dismiss(animated: true, completion: { () -> Void in
      if self.mode == .filterTree {
        self.delegate?.filterByTag(self.tagCollection)
      } else {
        self.delegate?.tagDidSet(self.tagCollection)
      }
    })
  }

  func didFilterByString(_ filter: AggregateFilter) {
    self.delegate?.filterByAggregate(filter)
//    self.dismissViewControllerAnimated(true, completion: { () -> Void in
//      self.delegate?.filterByAggregate(filter)
//    })
  }
  
}





extension LibraryPopover: LibraryLevelDelegate {

  func didSelectLevel(_ level: Level) {
    if mode == .filterTag {
      self.showAggregatedCategory(level)
    } else {
      self.tagCollection.startEditModeWithLevel(level)
      self.showCategory(true)

    }


  }


}
