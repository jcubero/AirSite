//
//  Photos.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-07-30.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit
import CoreData

class Photos: Page, UICollectionViewDelegate, UICollectionViewDataSource, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
  
  var frc: NSFetchedResultsController<NSFetchRequestResult>!
  weak var pages: PagesViewController!
  var filter: Filter {
    return self.pages.project.filter
  }
  
  var area: Area? {
    get {
      return self.pages.area
    }
  }
  
  
  @IBOutlet weak var emptyPhotoView: UIView!
  
  @IBOutlet weak var collectionView: UICollectionView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.pos = 2
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.fetch()
  }
  
  func fetch() {
    
    let req = NSFetchRequest<NSFetchRequestResult>(entityName: "Comment")
    let primarySortDescriptor = NSSortDescriptor(key: "createdDate", ascending: true)
    
    var pred = NSPredicate(format: "issue.area.project = %@ and imageFile != nil ", self.pages.project)
    
    if let area = self.area {
      let areaPred = NSPredicate(format: "issue.area = %@", area)
      pred = NSCompoundPredicate(andPredicateWithSubpredicates: [pred, areaPred])
    }
    
    if let filter = self.filter.commentPredicate {
      let cp = NSCompoundPredicate(andPredicateWithSubpredicates: [filter, pred])
      req.predicate = cp
    } else {
      req.predicate = pred
    }
    
    req.sortDescriptors = [primarySortDescriptor]
    self.frc = NSFetchedResultsController( fetchRequest: req,
      managedObjectContext: NSManagedObjectContext.mr_default(),
      sectionNameKeyPath: nil,
      cacheName: nil)
    frc.delegate = self
    do {
      try frc.performFetch()
    
      if let sections = self.frc.sections {
        let currentSection = sections[0]
        if currentSection.numberOfObjects > 0 {
          self.emptyPhotoView?.isHidden = true
        } else {
          self.emptyPhotoView?.isHidden = false
        }
      } else {
        self.emptyPhotoView?.isHidden = false
      }
      
    
      if self.collectionView != nil {
        self.collectionView.reloadData()
      }
    } catch  {
      Config.error("Couldn't fetch")
    }
  }
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    if let sections = self.frc?.sections {
      return sections.count
    }
    
    return 0
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
    if let sections = self.frc.sections {
      let currentSection = sections[section] 
      return currentSection.numberOfObjects
    }
    
    return 0
    
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotosCollectionViewCell", for: indexPath) as! PhotosCollectionViewCell
    
    let comment = self.frc.object(at: indexPath) as! Comment
    cell.imageView?.hnk_setImageFromFile(comment.imagePath!.path)
    
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let comment = self.frc.object(at: indexPath) as! Comment
    self.createPageViewController(comment)
//    self.pages.showCommentImage(comment)
  }
  
  
  func createPageViewController(_ comment: Comment) {
    
    let controller = PhotosPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    
    controller.dataSource = self
    controller.delegate = self
    controller.setViewControllers([self.createViewControllerWithComment(comment)], direction: .forward, animated: false, completion: nil)
    controller.modalPresentationStyle = .custom
    
    
    self.present(controller, animated: true, completion: nil)
    
    
  }
  
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    
    let comment = (viewController as!  CommentImageViewController).comment
    guard let currentIndexPath = self.frc.indexPath(forObject: comment!) else { return nil }
   
    if currentIndexPath.item == 0 { return nil }
    let nextIndexPath = IndexPath(item: currentIndexPath.item - 1, section: currentIndexPath.section)
    
    let nextCommet = self.frc.object(at: nextIndexPath) as! Comment
    return self.createViewControllerWithComment(nextCommet)
    
  }
  
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    
    
    let comment = (viewController as! CommentImageViewController).comment
    guard let currentIndexPath = self.frc.indexPath(forObject: comment!) else { return nil }
    
    let nextIndexPath = IndexPath(item: currentIndexPath.item + 1, section: currentIndexPath.section)
    if nextIndexPath.item >=  self.frc.fetchedObjects!.count { return nil }
    
    let nextCommet = self.frc.object(at: nextIndexPath) as! Comment
    return self.createViewControllerWithComment(nextCommet)
    
  }
  
  
  func createViewControllerWithComment(_ comment: Comment) -> UIViewController {
    
    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    let vc = storyboard.instantiateViewController(withIdentifier: "CommentImageViewController") as! CommentImageViewController
    vc.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    vc.comment = comment
    vc.delegate = self
    vc.inPageViewController = true
    return vc
    
  }
  
}


extension Photos: NSFetchedResultsControllerDelegate {
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    if self.collectionView != nil {
      self.collectionView.reloadData()
    }
  }
}


extension Photos: CommentImageViewControllerDelegate {

  func didPressIssuetLabel(_ issue: Issue) {

    self.pages.jumpToIssueOnMap(issue)

  }

}


