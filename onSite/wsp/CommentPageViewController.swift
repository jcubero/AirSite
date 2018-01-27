//
//  CommentPageViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2017-01-30.
//  Copyright © 2017 Ubriety. All rights reserved.
//

import UIKit


class CommentPageViewController: NSObject,  UIPageViewControllerDelegate, UIPageViewControllerDataSource {

  weak var parent: PagesViewController?

  var comments: [Comment] = []

  func createWithComment(_ comment: Comment, withComments: [Comment]) {

    self.comments = withComments

    let controller = PhotosPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    
    controller.dataSource = self
    controller.delegate = self
    controller.setViewControllers([self.createViewControllerWithComment(comment)], direction: .forward, animated: false, completion: nil)
    controller.modalPresentationStyle = .custom

    parent?.present(controller, animated: true, completion: nil)


  }

  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    
    let comment = (viewController as! CommentImageViewController).comment
    guard let currentIndexPath = self.comments.index(of: comment!) else {
      Config.error()
      return nil
    }
    
    if currentIndexPath == 0 { return nil }
    let nextIndexPath = currentIndexPath - 1
    
    let nextCommet = comments[nextIndexPath]
    return self.createViewControllerWithComment(nextCommet)
    
  }
  
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    
    
    let comment = (viewController as! CommentImageViewController).comment
    guard let currentIndexPath = self.comments.index(of: comment!) else {
      Config.error()
      return nil
    }
    
    let nextIndexPath = currentIndexPath + 1
    if nextIndexPath >= comments.count { return nil }
    
    let nextCommet = comments[nextIndexPath]
    return self.createViewControllerWithComment(nextCommet)
    
  }
  
  
  func createViewControllerWithComment(_ comment: Comment) -> UIViewController {
    
    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    let vc = storyboard.instantiateViewController(withIdentifier: "CommentImageViewController") as! CommentImageViewController
    vc.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    vc.comment = comment
    vc.delegate = parent
    vc.inPageViewController = true
    return vc
    
  }


}
