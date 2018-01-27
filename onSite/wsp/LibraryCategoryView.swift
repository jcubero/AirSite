//
//  LibraryCategoryView.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-08-01.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit
import CoreData

protocol LibraryCategoryDelegate: class {
  func tagDidChange()
  func tagDidSet()
  func showCategory(_ forward: Bool)
  func didCancel()
}

class LibraryCategoryView: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource {
  
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var myTitle: UILabel!
  @IBOutlet weak var titleImage: UIImageView!
  @IBOutlet weak var titleConstraint: NSLayoutConstraint!

  var imageCache: IssueImageCache!
  
  var height: CGFloat = 0
  var topMargin: CGFloat = 44
  
  var tagsCollection: TagCollection!
  var tags: [Tag]!
  
  var frc: NSFetchedResultsController<NSFetchRequestResult>!
  weak var delegate: LibraryCategoryDelegate?
  
  var mode: LibraryPopoverMode = .select

  let tagInputHeight:CGFloat = 64
  let tagRegularHeight:CGFloat = 44
  
  let tagLibraryCacheName = "TagLibraryCache"
  
  override func viewDidLoad() {
    super.viewDidLoad()

    renderUpperBar()
    fetchTags()
    adjustHeightToMatchNumberOfTags()

    self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 1))
    
  }

  func renderUpperBar() {

    let currentLevel = self.tagsCollection.nextLevel!
    
    if currentLevel.title != nil && currentLevel.title!.characters.count != 0 {
      self.myTitle.text = currentLevel.title
    } else {
      self.myTitle.text = self.tagsCollection.tagPreviousToLevel(currentLevel)?.title
    }
    
    if self.tagsCollection.hasShapeAndColor {
      self.titleImage.isHidden = false
      self.titleImage.image = UIImage(named: self.tagsCollection.shape)
      self.titleImage.fillWithColor(self.tagsCollection.color)
      self.titleConstraint.constant = 38
    } else {
      self.titleImage.isHidden = true
      self.titleConstraint.constant = 8
    }


  }

  func fetchTags() {
    let req = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
    
    let primarySortDescriptor = NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))
    req.sortDescriptors = [primarySortDescriptor]


    var predicate = self.tagsCollection.libraryPredicate
    
    if mode == .filterTag || mode == .filterTree {
      let filterPred = NSPredicate(format: "issueTags.@count != 0")
      predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, filterPred])
    }
    
    req.predicate = predicate

    NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: self.tagLibraryCacheName)

    self.frc = NSFetchedResultsController( fetchRequest: req, managedObjectContext: NSManagedObjectContext.mr_default(), sectionNameKeyPath: nil, cacheName: self.tagLibraryCacheName)

    frc.delegate = self
    do {
      try frc.performFetch()
    } catch {
      Config.error("Couldn't perform fetch")
    }
    
    // Add current tag to top of the list
    self.tags = self.frc.fetchedObjects as! [Tag]
    if let currentTag = self.tagsCollection.poppedTag {
      let currentTags = [currentTag] as [Tag]
      self.tags = currentTags + self.tags
    }

  }

  func adjustHeightToMatchNumberOfTags() {

    // adjust height to match number of tags
    for tag in self.tags! {
      if tag.isInputType {
        self.height += self.tagInputHeight
        
      } else {
        self.height +=  self.tagRegularHeight
        
      }
    }
    self.height += self.topMargin
    
    var contentSize = self.preferredContentSize
    contentSize.height = self.height
    self.presentingViewController!.presentedViewController!.preferredContentSize = contentSize

  }
  
  override func viewDidAppear(_ animated: Bool) {
    
    super.viewDidAppear(animated)
    
    
    if self.frc.fetchedObjects?.count == 1 {
      let first = IndexPath(row: 0, section: 0)
      let item = self.tags[0]
      
      if item.isInputType {
        let cell = self.tableView.cellForRow(at: first) as! LibraryInputViewCell
        cell.enableEdit()
      }
      
    }
    
  }
  
  
  @IBAction func cancel(_ sender: AnyObject) {
    if self.tagsCollection.pop() == nil {
      self.delegate?.didCancel()
    } else {
      self.delegate?.showCategory(false)
    }
    
  }
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    self.tableView.reloadData()
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.tags!.count
  }
  
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let tag = self.tags[indexPath.row]
    
    if tag.isInputType {

      let cell = tableView.dequeueReusableCell(withIdentifier: "SelectInputCell", for: indexPath) as! LibraryInputViewCell
      configureCell(cell, withTag: tag)
      if tag == self.tagsCollection.savedInputTag {
        cell.previousInput = self.tagsCollection.savedInput
      }
      return cell

    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: "SelectTagsCell", for: indexPath) as! LibraryTableViewCell
      configureCell(cell, withTag: tag)
      return cell
      
    }
    
  }

  func configureCell(_ cell: LibraryBaseCell, withTag tag: Tag) {

    cell.imageCache = self.imageCache
    cell.mode = mode
    cell.item = tag
    cell.backgroundColor = UIColor.clear
    if tag == self.tagsCollection.poppedTag {
      cell.setAsCurrent()
    }
    
    if self.tagsCollection.nextLevelExistsSupposing(tag) && mode != .filterTag {
      cell.showAccessory(true)
    } else {
      cell.showAccessory(false)
    }
    
    cell.delegate = self

  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
   
    let tag = self.tags[indexPath.row]
    
    if tag.isInputType {
      return self.tagInputHeight

    } else {
      return self.tagRegularHeight
    }
    
  }
  
  func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {

    if mode == .filterTag {
      return false
    } else if  mode == .filterTree {
      let data = self.tags[indexPath.row]
      return data.level.nextLevelExists
    }
    return true
    
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    let data = self.tags[indexPath.row]
    
    self.tagsCollection.push(data)
    self.moveOn()
    
  }

  func moveOn() {
    if self.tagsCollection.missingTagInformation {
      self.delegate?.showCategory(true)
    } else {
      self.delegate?.tagDidSet()
    }


  }
  
  
}

extension LibraryCategoryView: LibraryInputViewCellDelegate {
  
  func filterByTag(_ tag: Tag) {
    self.tagsCollection.push(tag)
    self.delegate?.tagDidSet()
    
  }
  
  func tagInputSet(_ tag: Tag, input: String) {
    if let issueTag = self.tagsCollection.push(tag) {
      issueTag.input = input
    } else {
      Config.error()
    }

    self.moveOn()
    
  }
  
}
