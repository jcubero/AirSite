//
//  EditLibraryParentViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-01-15.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit
import CoreData

protocol EditLibraryParentDelegate: class {
  func selectTag(_ tag: Tag)
  func pushNewLevel(_ tag: Tag)
}


class TagsInLevels {
  
  var tagsAtLevel: [Level : [Tag]]
  var targetLevel: Level
  var inNullState: Bool = true
  
  
  init(targetLevel: Level) {
    
    self.targetLevel = targetLevel
    
    guard self.targetLevel.isTreeLevel.boolValue else {
      self.tagsAtLevel = [:]
      Config.error("TagsInLevels called on non-tree level.")
      return
      
    }
    
    self.tagsAtLevel = [:]
    
    var child = self.targetLevel
    while let parent = child.parent {
      
      let levelPred = self.tagPredicate(parent)
      if let tags = self.tagsAtLevel[child] {
        
        if tags.count == 0 {
          self.tagsAtLevel[parent] = []
          
        } else {
          let childPred = NSPredicate(format: "any children in %@", tags)
          
          let newTags = self.fetchTagsWithPredicate(NSCompoundPredicate(andPredicateWithSubpredicates: [levelPred, childPred]))
          self.tagsAtLevel[parent] = newTags
          
        }
        
      } else {
        let newTags = self.fetchTagsWithPredicate(levelPred)
        self.tagsAtLevel[parent] = newTags
        if newTags.count > 0 {
          self.inNullState = false
        }
        
      }
      child = parent
      
    }
    
  }
  
  func fetchTagsWithPredicate(_ predicate: NSPredicate) -> [Tag] {
    
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
    let sortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
    
    fetchRequest.predicate = predicate
    fetchRequest.sortDescriptors = [sortDescriptor]
    
    do {
      let tags = try NSManagedObjectContext.mr_default().fetch(fetchRequest) as! [Tag]
      return tags
    } catch {
      Config.error("Couldn't fetch!")
      return []
    }
  }
 
  func tagPredicate(_ level: Level)  -> NSPredicate {
   return NSPredicate(format: "level = %@ and title !=[c] %@", level, Tag.TagTitleEnd)
  }
  
  
  func getTagsForLevel(_ level: Level, withOwner: Tag?) -> [Tag] {
    
    guard let tags = self.tagsAtLevel[level] else {
      return []
    }
    
    return tags.filter { (tag:Tag) -> Bool in
      return tag.parent == withOwner
    }
    
  }
  
}

class EditLibraryParentViewController: UITableViewController {
  
  
  var ownerItem: Tag?
  let tagCache: String = "ParentTagList"
  var targetLevel: Level!
  
  weak var delegate: EditLibraryParentDelegate?
  
  var tagsInLevels: TagsInLevels!
  var currentTags: [Tag]!
  var currentLevel: Level!
  
  var isSingleLevel: Bool = false
  var firstRun: Bool = true
  
  var currentIndexPath: IndexPath?
  
  var isAtFinalLevel: Bool {
    get {
      return self.currentLevel == self.targetLevel.parent
    }
  }
  
  func fetch() {
    
    self.currentTags = self.tagsInLevels.getTagsForLevel(self.currentLevel, withOwner: self.ownerItem)
    
  }
  
  override func viewDidLoad() {
    
    super.viewDidLoad()
    self.navigationController?.setNavigationBarHidden(true, animated: false)
    
    self.fetch()
    self.tableView.tableFooterView = UIView()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    
    super.viewWillAppear(animated)
    
    if self.isAtFinalLevel && self.isSingleLevel  && self.currentTags.count > 0 && self.firstRun {
      let first = IndexPath(row: 0, section: 0)
      self.tableView.selectRow(at: first, animated: false, scrollPosition: .none)
      self.tableView(self.tableView, didSelectRowAt: first)
    }
    
    if !self.firstRun && self.isAtFinalLevel {
      if let indexPath = self.currentIndexPath {
        self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        self.tableView(self.tableView, didSelectRowAt: indexPath)
      }
    }
    
    self.firstRun = false
    
  }
  
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    return self.currentTags.count
    
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
    
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = self.tableView.dequeueReusableCell(withIdentifier: "EditTagsCell", for: indexPath) as! EditTagsCell
    let item = self.currentTags[indexPath.row]
    
    cell.item = item
    
    if self.isAtFinalLevel {
      cell.accessoryType = .none
    } else {
      cell.accessoryType = .disclosureIndicator
    }
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    let item = self.currentTags[indexPath.row]
    
    self.currentIndexPath = indexPath
    
    if self.isAtFinalLevel {
      self.delegate?.selectTag(item)
      
    } else {
      
      let tableviewcontroller = self.storyboard?.instantiateViewController(withIdentifier: "EditLibraryParentViewController") as! EditLibraryParentViewController
      tableviewcontroller.currentLevel = self.targetLevel.levelAfterLevel(self.currentLevel)
      tableviewcontroller.ownerItem = item
      tableviewcontroller.targetLevel = self.targetLevel
      tableviewcontroller.delegate = self.delegate
      tableviewcontroller.isSingleLevel = self.isSingleLevel
      tableviewcontroller.tagsInLevels = self.tagsInLevels
      
      self.delegate?.pushNewLevel(item)
      
      self.navigationController?.pushViewController(tableviewcontroller, animated: true)
      
    }
    
  }
  

}

extension EditLibraryParentViewController: NSFetchedResultsControllerDelegate {
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    self.tableView.reloadData()
    
  }
}
