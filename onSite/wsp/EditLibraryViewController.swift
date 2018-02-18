//
//  EditLibraryViewController.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-09-17.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit
import CoreData

class EditLibraryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
  @IBOutlet weak var importButton: UIButton!
  @IBOutlet weak var addButton: UIButton!
  
  
  @IBOutlet weak var skipOrEndView: UIView!
  @IBOutlet weak var skipOrEndLabel: UILabel!
  @IBOutlet weak var skipOrEndButton: UIButton!
 
  @IBOutlet weak var editLevelButton: UIButton!
  
  
  var project: Project!
  var manager: Manager = Manager.sharedInstance
  var currentLevel: Level!
  var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
  
  var ownerItem: Tag?
  let tagCache: String = "TagList"
  
  var fileManager: FileManager_?
  
  var currentLevelAction: LevelAction {
    get {
      var action: LevelAction = .process
      
      if self.currentLevel.isTreeLevel.boolValue {
        if let parent = self.ownerItem {
          action = self.currentLevel.levelAction(parent)
        }
      } else {
        action = self.currentLevel.levelAction(nil)
      }
      return action
      
    }
  }
  
  
  @IBOutlet weak var tv: UITableView!
  
  
  var currentPrdicate: NSPredicate? {
    get {
      NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: tagCache)
     
      let levelPred = NSPredicate(format: "level = %@", self.currentLevel)
      
      if self.currentLevel.isTreeLevel.boolValue {
        if self.currentLevel.level.int32Value == 0 {
          return levelPred
        } else {
          guard let parent = self.ownerItem else {
            return nil
          }
          let parentPred = NSPredicate(format: "parent = %@", parent)
          return NSCompoundPredicate(andPredicateWithSubpredicates: [levelPred, parentPred])
        }
      } else {
        return levelPred
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    if let vc = self.parent?.parent as? EditProjectTabBarController {
      self.project = vc.project
    }
    
    self.addButton.addShadow()
    if self.importButton != nil {
      self.importButton.addShadow()
    }
    
    self.tv.contentInset = UIEdgeInsetsMake(0, 0, 100, 0);
    self.tv.tableFooterView = UIView()
    
  }
  
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if self.currentLevel == nil {
      self.currentLevel = Level.getOrCreateLevelForProject(self.project, level: 0)
    }
    
    self.editLevelButton.setTitle(self.currentLevel!.nonEmptyTitle, for: UIControlState())
    
    if self.importButton != nil {
      if self.currentLevel.isTopLevel {
        self.importButton.isHidden = false
      } else {
        self.importButton.isHidden = true
      }
    }
    
   
    self.drawNextLevelBarButton()
    
    self.fetch()
    
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.fileManager = nil
    
  }

  
  func drawNextLevelBarButton() {
    
    var drawImage = false
    var title = NSLocalizedString("Add", comment:"Add")
    if let nextLevel = self.currentLevel.nextLevel {
      title = nextLevel.nonEmptyTitle
      drawImage = true
      
    }
    
    let button = UIButton(type: UIButtonType.custom)
    button.setTitle(title, for: UIControlState())
    button.titleLabel?.textAlignment = NSTextAlignment.left
    button.setTitleColor(UIColor.systemBlue(), for: UIControlState())
    
    if drawImage {
      let image = self.fillImageWithColor(UIImage(named:"ic_chevron_right_white_48pt")!, color: UIColor.systemBlue())
      button.setImage(image, for: UIControlState())
      button.setImage(image, for: UIControlState.selected)
      button.setImage(image, for: UIControlState.highlighted)
      button.titleEdgeInsets = UIEdgeInsetsMake(0, -70, 0, 0)
      button.imageEdgeInsets = UIEdgeInsetsMake(0, -44, 0, 0)
      button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0);
      button.titleLabel!.transform = CGAffineTransform(scaleX: -1.0, y: 1.0);
      button.imageView!.transform = CGAffineTransform(scaleX: -1.0, y: 1.0);
    }
    
    button.sizeToFit()
    button.addTarget(self, action: #selector(EditLibraryViewController.goToNextLevel), for: UIControlEvents.touchUpInside)
    let barButton = UIBarButtonItem(customView: button)
    self.navigationItem.setRightBarButton(barButton, animated: false)
    
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    super.prepare(for: segue, sender: sender)
    
    if (segue.identifier == "AddLevelItem") {
      let navController = segue.destination as! UINavigationController
      let shapePicker = navController.visibleViewController as! EditTagViewController
      shapePicker.level = self.currentLevel!
      shapePicker.project = self.project
      shapePicker.parentItem = self.ownerItem
      
    } else if (segue.identifier == "EditLevelItem") {
      let navController = segue.destination as! UINavigationController
      let shapePicker = navController.visibleViewController as! EditTagViewController
      shapePicker.level = self.currentLevel!
      shapePicker.levelItem = sender as? Tag
      shapePicker.project = self.project
      shapePicker.parentItem = self.ownerItem
      
    } else if (segue.identifier == "EditLevel") {
      let navController = segue.destination as! UINavigationController
      let vc = navController.visibleViewController as! EditLevelViewController
      vc.level = sender as? Level
      vc.levelNumber = self.currentLevel.level.intValue + 1
      vc.project = self.project
      vc.parentVC = self
      
    } else if (segue.identifier == "ImportTags") {
      let importNav = segue.destination as! UINavigationController
      let importTagsTableView = importNav.visibleViewController as! ImportTagsTableViewController
      importTagsTableView.project = self.project!
      importTagsTableView.callingVc = self
      importNav.popoverPresentationController?.sourceRect = importNav.popoverPresentationController!.sourceView!.bounds
      
    } else if (segue.identifier == "NextLevel") || (segue.identifier == "NextVariableLevel") {
      
      let editLibrary = segue.destination as! EditLibraryViewController
      editLibrary.project = self.project
      let nextLevel = self.currentLevel.level.int32Value + 1
      editLibrary.currentLevel = Level.getOrCreateLevelForProject(self.project, level: Int(nextLevel))
      
      // set the proper title
      let title = self.currentLevel.nonEmptyTitle
      
      self.navigationItem.title = title
      
    }
  
  }
    func importTags(_ files: [FileStruct])
    {
        self.importTagsFromFiles(files, cb: nil)

    }
    
  @IBAction func importButtonPressed(_ sender: AnyObject) {
  
    let countOfProject = Project.mr_countOfEntities()
      
    if countOfProject < 2 {
//      Manager.sharedInstance.startActivity(withMessage: "Importing Tags")

      self.fileManager = FileManager_(vc: self, forFileTypes: [.Excel])
        
        self.fileManager?.loadFilePicker(importTags)
      
    } else {
      self.performSegue(withIdentifier: "ImportTags", sender: self.importButton)
    }
  }
  
    
    
    
  func importTagsFromFiles(_ files: [FileStruct], cb: ((_ err: String?) -> ())?) {
    
    if files.count == 0 {
      let msg = NSLocalizedString("Invalid spreadsheet selected", comment: "")
      Manager.sharedInstance.showError(msg)
      cb?(msg)
      return
    }
    
    let file: FileStruct = files[0]
    
    guard let path = file.path else {
      let msg = NSLocalizedString("Invalid spreadsheet selected", comment: "")
      Manager.sharedInstance.showError(msg)
      cb?(msg)
      return
    }
    
    let excelExtractor = ExcelImport(excelFilePath: path)
    excelExtractor.importTags(intoProject: self.project) { error in
      if let err = error {
        Manager.sharedInstance.showError(err)
      } else {
        Manager.sharedInstance.stopActivity()
        
      }
      cb?(error)
      return
    }
    
  }
  
  @IBAction func toggleSkipOrEnd(_ sender: UIButton) {
    
    switch self.currentLevelAction {
    case .process:
      self.currentLevel.setLevelAction(.end, withParent: self.ownerItem)
      
    case .end:
      self.currentLevel.setLevelAction(.skip, withParent: self.ownerItem)
      
    case .skip:
      self.currentLevel.setLevelAction(.end, withParent: self.ownerItem)
      
    }
    
  }
  
  @IBAction func editLevel(_ sender: UIButton) {
    
    self.performSegue(withIdentifier: "EditLevel", sender: self.currentLevel!)
    
  }
  
  func finishEditingLevel(andGoToNextLevel gotoNext: Bool) {
    
    self.tv.reloadData()
    
    self.editLevelButton.setTitle(self.currentLevel!.nonEmptyTitle, for: UIControlState())
    
    self.drawNextLevelBarButton()
    
    if gotoNext {
      self.goToNextLevel()
    }
    
  }
  
  
  func levelHasBeenRemoved() {
    
    if self != self.navigationController?.viewControllers[0] {
      self.navigationController?.popViewController(animated: true)
    } else {
      
      self.currentLevel = Level.getOrCreateLevelForProject(self.project, level: 0)
      self.editLevelButton.setTitle(self.currentLevel!.nonEmptyTitle, for: UIControlState())
    
      self.drawNextLevelBarButton()
      self.fetch()
      
    }
    
    
  }
  
  func fetch() {
    
    guard let predicate = self.currentPrdicate else {
      Config.error();
      return
    }
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
    let primarySortDescriptor = NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
    
    fetchRequest.predicate = predicate
    fetchRequest.sortDescriptors = [primarySortDescriptor]
    
    self.fetchedResultsController = NSFetchedResultsController( fetchRequest: fetchRequest,
      managedObjectContext: NSManagedObjectContext.mr_default(),
      sectionNameKeyPath: nil,
      cacheName: self.tagCache)
    
    self.fetchedResultsController!.delegate = self
    
    do {
      try self.fetchedResultsController!.performFetch()
      self.tv.reloadData()
      self.processNewFetch()
    } catch {
      Config.error("Cound't fetch data")
    }
    
  }
  
  func processNewFetch() {

    Manager.sharedInstance.caches.invalidateLevelActions(forLevel: self.currentLevel)
    if self.currentLevel == nil || self.currentLevel.isDeleted {
      return
    }
   
    var endText = NSLocalizedString("Tag selection will end here.", comment: "Tag selection will end here.")
    var skipText = NSLocalizedString("Tag selection will skip this level.", comment: "Tag selection will skip this level.")
    
    if self.currentLevel.isTreeLevel.boolValue && self.ownerItem != nil {
      let tag = self.ownerItem!
      let endInsertion = NSLocalizedString("Tag selection will end here when %s is selected.", comment: "Tag selection will end here when %s is selected.")
      let skipInsertion = NSLocalizedString("Tag selection will skip this level when %s is selected.", comment: "Tag selection will skip this level when %s is selected.")
      endText = endInsertion.replacingOccurrences(of: "%s", with: "\"\(tag.nonEmptyTitle)\"")
      skipText = skipInsertion.replacingOccurrences(of: "%s", with: "\"\(tag.nonEmptyTitle)\"")
    }
    
    let addTagsText = NSLocalizedString("No tags. Click the plus to add one.", comment: "No tags. Click the plus to add one.")
    let endButton = NSLocalizedString("End on this level instead", comment: "End on this level instead")
    let skipButton = NSLocalizedString("Skip this level instead", comment: "Skip this level instead")

    switch self.currentLevelAction {
    case .process:
      self.skipOrEndView.isHidden = true
      
    case .end:
      self.skipOrEndView.isHidden = false
      self.skipOrEndButton.setTitle(skipButton, for: UIControlState())
      self.skipOrEndLabel.text = endText
      self.skipOrEndButton.isHidden = false
      
    case .skip:
      self.skipOrEndView.isHidden = false
      if self.currentLevel.nextLevelExists {
        self.skipOrEndButton.setTitle(endButton, for: UIControlState())
        self.skipOrEndLabel.text = skipText
        self.skipOrEndButton.isHidden = false
      } else {
        self.skipOrEndLabel.text = addTagsText
        self.skipOrEndButton.isHidden = true
      }
      
    }
    
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    if let sections = self.fetchedResultsController?.sections {
      return sections.count
    }
    return 0
    
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let sections = self.fetchedResultsController?.sections {
      let currentSection = sections[section] 
      return currentSection.numberOfObjects
    }
    return 0
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = self.tv.dequeueReusableCell(withIdentifier: "EditTagsCell", for: indexPath) as! EditTagsCell
    let item = self.fetchedResultsController!.object(at: indexPath) as! Tag
    
    cell.item = item
    cell.accessoryType = .none
    return cell
  }
  
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    
  }
  
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    
    let item = self.fetchedResultsController!.object(at: indexPath) as! Tag
    
    
    let removeString = NSLocalizedString("Remove", comment: "Remove")
    let remove = UITableViewRowAction(style: .default, title: removeString) { (UITableViewRowAction, indexPath: IndexPath) -> Void in
      
      
      var message = NSLocalizedString("Are you sure?", comment: "Are you sure?")
      let count = item.issueTags!.count
      
      if count > 0 {
        if count == 1 {
          message += " "
          message += NSLocalizedString("You will remove this tag from 1 observation.", comment: "You will remove this tag from 1 observation.")
        } else {
          message += " "
          let loc = NSLocalizedString("You will remove this tag from %s observation.", comment: "You will remove this tag from %s observation.")
          message += loc.replacingOccurrences(of: "%s", with: "\(count)")
        }
      }
      
      let alert = UIAlertController(title: NSLocalizedString("Delete Tag", comment: "Delete Tag"), message: message, preferredStyle: UIAlertControllerStyle.alert)
      alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .cancel, handler: { action in
        
        self.project.deleteProjectEntity(item)
        
        Manager.sharedInstance.saveCurrentState({ () -> () in
          self.dismiss(animated: true, completion: nil)
          tableView.setEditing(false, animated: true)
        })
      }))
      
      let cancelString = NSLocalizedString("Cancel", comment: "Cancel")
      alert.addAction(UIAlertAction(title: cancelString, style: .default, handler: { action in
        tableView.setEditing(false, animated: true)
      }))
      
      self.present(alert, animated: true, completion: nil)
    }
    
    return [remove]
  }
  
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    let item = self.fetchedResultsController!.object(at: indexPath) as! Tag
    
    self.performSegue(withIdentifier: "EditLevelItem", sender: item)
    
    self.tv.deselectRow(at: indexPath, animated: true)
    
    
  }

  
    @objc func goToNextLevel() {
    
    if self.currentLevel.nextLevelExists {
      if self.currentLevel.nextLevel!.isTreeLevel.boolValue {
        self.performSegue(withIdentifier: "NextVariableLevel", sender: nil)
        
      } else {
        self.performSegue(withIdentifier: "NextLevel", sender: nil)
      }
    } else {
      
      self.performSegue(withIdentifier: "EditLevel", sender: nil)
      
    }
  }
  
  func fillImageWithColor(_ image: UIImage, color: UIColor) -> UIImage {
    
    let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
    let context = UIGraphicsGetCurrentContext()
    
    context?.clip(to: rect, mask: image.cgImage!)
    context?.setFillColor(color.cgColor)
    context?.fill(rect)
    
    
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return img!
  }
  
}

extension EditLibraryViewController: NSFetchedResultsControllerDelegate {
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    if !self.project.isDeleted {
      self.tv.reloadData()
      self.processNewFetch()
      self.drawNextLevelBarButton()
      self.editLevelButton.setTitle(self.currentLevel!.nonEmptyTitle, for: UIControlState())
    }
    
  }
}
