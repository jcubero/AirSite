//
//  ProjectListViewController.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-08-24.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import CoreData
import MagicalRecord
import CryptoSwift


protocol ProjectListDelegate: class {
  func returnSelf() -> UIViewController
  func endEditing()
  func newProject()
}

protocol ProjectListMenuDelegate: class {
  func sort(_ sortby: String, ascending: Bool, sortByRow: Int)
}

class ProjectListViewController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate {
  
  let manager = Manager.sharedInstance
  let cache: String = "ProjectListCache"
  
  var selectedRow: IndexPath?
  var sortByRow: Int = 2
  
  // var currentPopover: UIPopoverController?
  
  
  @IBOutlet weak var tableView: UITableView!
  
  @IBOutlet weak var addIcon: UIButton!
  @IBOutlet weak var importIcon: UIButton!
  @IBOutlet weak var syncIcon: UIButton!
  
  @IBOutlet weak var invisibleAnchor: UIView!
  @IBOutlet weak var emptyState: UIView!
  
  var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
  
  var logoutAction: UIAlertAction?
  
  var currentPredicate: NSPredicate? {
    get {
      NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: self.cache)
      return nil
    }
  }
  
  func fetch(_ sortby: String, ascending: Bool) {
    let projectFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Project")
    var primarySortDescriptor: NSSortDescriptor!
    
    if sortby == "title" {
      primarySortDescriptor = NSSortDescriptor(key: sortby, ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
    } else {
      primarySortDescriptor = NSSortDescriptor(key: sortby, ascending: false)
    }
    
    projectFetchRequest.sortDescriptors = [primarySortDescriptor]
    projectFetchRequest.predicate = self.currentPredicate
    self.fetchedResultsController = NSFetchedResultsController( fetchRequest: projectFetchRequest,
      managedObjectContext: NSManagedObjectContext.mr_default(),
      sectionNameKeyPath: nil,
      cacheName: self.cache)
    self.fetchedResultsController!.delegate = self
    do {
      try self.fetchedResultsController!.performFetch()
      self.reload()
    } catch {
      Config.error("Couldn not perform fetch")
    }
  }
  
  override func viewDidLoad() {
    
    super.viewDidLoad()
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.syncIcon.isHidden = true
    
    self.fetch("createdDate", ascending: true)
    
    if let nav = self.navigationController?.navigationBar {
      nav.barTintColor = UIColor.wspNeutral()
      nav.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
      let titleString = NSLocalizedString("Project List", comment: "Project List")
      self.title = titleString
    }
    
    self.automaticallyAdjustsScrollViewInsets = false
    self.tableView.rowHeight = 88
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 140, 0)
    
    // self.tableView.tableFooterView = UIView()
    
    self.addIcon.addShadow()
    self.importIcon.addShadow()
    self.syncIcon.addShadow()
    NotificationCenter.default.addObserver(self, selector: #selector(ProjectListViewController.onDatabaseReload), name: NSNotification.Name(rawValue: Config.databaseReloadNotification), object: nil)
    
  }
  
  @objc func backButtonClicked(_ sender: UIBarButtonItem) {
    
    let warning = NSLocalizedString("Warning", comment: "Warning")
    let titleString = NSLocalizedString("Logging out will permanently delete ALL projects from this tablet. It is highly recommended to export ALL projects to ensure that no data is lost.\n\nIf you have already exported all your projects, confirm that you have understood that all projects will be deleted by typing in your password below.", comment: "Logout warning.")
    let alert = UIAlertController(title: warning, message: titleString, preferredStyle: UIAlertControllerStyle.alert)
    
    alert.addTextField() { textField in
      textField.placeholder = NSLocalizedString("Enter your password", comment: "Enter your password")
      textField.isSecureTextEntry = true
      textField.addTarget(self, action: #selector(ProjectListViewController.checkForValidPassword(_:)), for: UIControlEvents.editingChanged)
    }
    
    let cancelString = NSLocalizedString("Cancel", comment: "Cancel")
    alert.addAction(UIAlertAction(title: cancelString, style: .cancel, handler: { action in
      
    }))
    
    let removeString = NSLocalizedString("Log Out", comment: "Log Out")
    
    logoutAction = UIAlertAction(title: removeString, style: .destructive, handler: { action in
      self.manager.user.logout()
      self.navigationController?.popToRootViewController(animated: true)
    })
    logoutAction?.isEnabled = false
    alert.addAction(logoutAction!)
    
    self.present(alert, animated: true, completion: nil)
  
  }
  
  @objc func checkForValidPassword(_ textField: UITextField) {
   
    let pass = textField.text!
    
    if let password = Manager.sharedInstance.getCurrentUser().password {
      logoutAction?.isEnabled = Config.networkConfig.authenticate(password, db: pass)
    } else {
      Config.error()
    }
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(true)
    self.navigationController?.navigationBar.isHidden = false
    
    // hide default navigation bar button item
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.hidesBackButton = true;
    let backButton = UIButton(type: UIButtonType.custom)
    backButton.setTitle(NSLocalizedString("Log Out", comment: "Log Out"), for: UIControlState())
    backButton.titleLabel?.textAlignment = NSTextAlignment.left
    backButton.setImage(UIImage(named:"ic_chevron_left_white_48pt"), for: UIControlState())
    backButton.setImage(UIImage(named:"ic_chevron_left_white_48pt"), for: UIControlState.selected)
    backButton.setImage(UIImage(named:"ic_chevron_left_white_48pt"), for: UIControlState.highlighted)
    backButton.titleEdgeInsets = UIEdgeInsetsMake(0, -70, 0, 0)
    backButton.imageEdgeInsets = UIEdgeInsetsMake(0, -44, 0, 0)
    backButton.sizeToFit()
    backButton.addTarget(self, action: #selector(ProjectListViewController.backButtonClicked(_:)), for: UIControlEvents.touchUpInside)
    let leftBarButtonItem: UIBarButtonItem = UIBarButtonItem(customView: backButton)
    self.navigationItem.setLeftBarButton(leftBarButtonItem, animated: false)
    
    Manager.sharedInstance.sendScreenView("Project List")
    
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc func onDatabaseReload() {
    self.fetch("title", ascending: true)
    
  }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if let sections = self.fetchedResultsController!.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "ProjectListCell", for: indexPath) as! ProjectListCell
        let project = self.fetchedResultsController!.object(at: indexPath) as! Project
        
        cell.project = project
        
        return cell

    }
  
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath){
        self.selectedRow = indexPath
        self.performSegue(withIdentifier: "EditProject", sender: nil)
    }
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    self.tableView.endUpdates()
    emptyState.isHidden = fetchedResultsController!.fetchedObjects!.count > 0
  }

  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    self.tableView.beginUpdates()
  }


  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

    switch type {

    case .insert:
      guard let ip = newIndexPath else {
        Config.error()
        return
      }
      self.tableView.insertRows(at: [ip], with: .fade)
    case .delete:
      guard let ip = indexPath else {
        Config.error()
        return
      }
      self.tableView.deleteRows(at: [ip], with: .fade)

    case .update:
      guard let ip = indexPath else {
        Config.error()
        return
      }
      self.tableView.reloadRows(at: [ip], with: .none)

    case .move:
      guard let ip = indexPath else {
        Config.error()
        return
      }

      guard let nip = newIndexPath else {
        Config.error()
        return
      }

      self.tableView.deleteRows(at: [ip], with: .fade)
      self.tableView.insertRows(at: [nip], with: .fade)
    }

  }


  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "EditProject" {
      
      let project = self.fetchedResultsController!.object(at: IndexPath(row: self.selectedRow!.row, section: 0)) as! Project
      let editViewController = segue.destination as! EditProjectTabBarController
      editViewController.project = project
      
    } else if segue.identifier == "AddProject" {
      
      let project =  Project.create(nil)
      
      let editViewController = segue.destination as! EditProjectTabBarController
      
      editViewController.project = project
      
    }  else if segue.identifier == "ProjectListMenu" {
      
      let projectListMenuTableViewController = segue.destination as! ProjectListMenuTableViewController
      projectListMenuTableViewController.delegate = self as ProjectListMenuDelegate
      projectListMenuTableViewController.setCheckmark(self.sortByRow)
      let dest = projectListMenuTableViewController.popoverPresentationController!.sourceView!.bounds
      projectListMenuTableViewController.popoverPresentationController?.sourceRect = dest
      
      
    } else if segue.identifier == "ProjectListExport" {
      
      let listExporter = segue.destination as! ProjectListExportTableViewController
      listExporter.popoverPresentationController?.sourceRect = listExporter.popoverPresentationController!.sourceView!.bounds
      listExporter.project = sender as! Project
      listExporter.delegate = self as ProjectListDelegate
      
    } else if segue.identifier == "ProjectListImport" {
      
      let projectListExport = segue.destination as! UINavigationController
      projectListExport.popoverPresentationController?.sourceRect = projectListExport.popoverPresentationController!.sourceView!.bounds
      let listExporter = projectListExport.visibleViewController as! ProjectListImportTableViewController
      listExporter.delegate = self as ProjectListDelegate
      
    }
  
  }
  
//  func tableView(_ tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath) {
//
//  }
  
  func reload() {
    DispatchQueue.main.async{
        self.tableView.reloadData()
    }
    emptyState.isHidden = fetchedResultsController!.fetchedObjects!.count > 0
  }
  
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    
    let syncString = NSLocalizedString("Sync", comment: "Sync")
    let sync = UITableViewRowAction(style: .normal, title: syncString) { (UITableViewRowAction, indexPath: IndexPath) -> Void in
      
      let project = self.fetchedResultsController!.object(at: IndexPath(row: indexPath.row, section: 0)) as! Project
      Manager.sharedInstance.syncProject(project) {
        Manager.sharedInstance.sendActionEvent("Sync Project", label: project.nonEmptyProjectTitle)
        self.tableView.setEditing(false, animated: true)
      }
      
    }
    sync.backgroundColor = UIColor.wspNeutral()
    
    let exportString = NSLocalizedString("Export", comment: "Export")
    let export = UITableViewRowAction(style: .normal, title: exportString) { (UITableViewRowAction, indexPath: IndexPath) -> Void in
      
      let project = self.fetchedResultsController!.object(at: IndexPath(row: indexPath.row, section: 0)) as! Project
      
      var frame = tableView.rectForRow(at: indexPath)
      frame = frame.offsetBy(dx: -tableView.contentOffset.x, dy: -tableView.contentOffset.y)
      frame.origin.y += 110
      
      let right = CGFloat(140)
      frame.origin.x =  frame.size.width - right
      frame.size.width = 100
      
      self.invisibleAnchor.center = frame.origin
      self.performSegue(withIdentifier: "ProjectListExport", sender: project)
      
    }
    export.backgroundColor = UIColor.wspNeutral()

    
    let cloneString = NSLocalizedString("Copy", comment: "Copy")
    let cloneRow = UITableViewRowAction(style: .normal, title: cloneString) { (UITableViewRowAction, indexPath: IndexPath) -> Void in
      
      self.selectedRow = indexPath
      
      let project = self.fetchedResultsController!.object(at: IndexPath(row: indexPath.row, section: 0)) as! Project
      
      let projectTitle = project.title
      let cloneAlertTitleString = NSLocalizedString("Copy", comment: "Copy")
      let cancelString = NSLocalizedString("Cancel", comment: "Cancel")
      let cloneAlertMessageString = NSLocalizedString("Please enter the name of the copied project", comment: "Project")
        let alert = UIAlertView(title: cloneAlertTitleString, message: cloneAlertMessageString, delegate: self, cancelButtonTitle: cancelString)
      
        alert.alertViewStyle = .plainTextInput
      
        alert.textField(at: 0)!.text = projectTitle + " "
      
        alert.addButton(withTitle: cloneAlertTitleString)
      
        alert.show()
    }
    
    cloneRow.backgroundColor = UIColor.wspNeutral()
    
    let removeString = NSLocalizedString("Delete", comment: "Delete")
    let unsink = UITableViewRowAction(style: .default, title: removeString) { (UITableViewRowAction, indexPath: IndexPath) -> Void in
      
      let project = self.fetchedResultsController!.object(at: IndexPath(row: indexPath.row, section: 0)) as! Project
      
      let titleString = NSLocalizedString("Delete project from this device?", comment: "Delete project from this device?")
      let alert = UIAlertController(title: titleString, message: "", preferredStyle: UIAlertControllerStyle.alert)
      
      let removeString = NSLocalizedString("Delete", comment: "Delete")
      alert.addAction(UIAlertAction(title: removeString, style: .destructive, handler: { action in
        Manager.sharedInstance.sendActionEvent("Delete Project", label: project.nonEmptyProjectTitle)
        project.removeWithFiles()
        self.manager.saveCurrentState(nil)
      }))
      
      let cancelString = NSLocalizedString("Cancel", comment: "Cancel")
      alert.addAction(UIAlertAction(title: cancelString, style: .default, handler: { action in
        
        alert.dismiss(animated: true, completion: nil)
      }))
      
      self.present(alert, animated: true, completion: nil)
      
            }
    
    if Manager.sharedInstance.features.sync {
      return [unsink, export, cloneRow, sync]
    } else {
      return [unsink, export, cloneRow]
    }
    
  }
  
  func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
    if buttonIndex == 1 {
      let project = self.fetchedResultsController!.object(at: IndexPath(row: self.selectedRow!.row, section: 0)) as! Project
      let projectTitle = alertView.textField(at: 0)!.text!
      
      do {
        let export = JSONExport(project: project)
        var exportJson = try export.exportForCloning(withTitle: projectTitle)
        
        
        var projectFiles: [FileStruct] = []
        if let img = project.imageFile, let exportable = img.exportableFileStruct {
          exportJson["image"].string = exportable.name
          projectFiles.append(exportable)
        }
        if let img = project.buildingImageFile, let exportable = img.exportableFileStruct {
          exportJson["building_image"].string = exportable.name
          projectFiles.append(exportable)
        }
        let jsonFile = FileStruct(url: nil, type: .JSON, blankWithData: try exportJson.rawData())
        projectFiles.append(jsonFile)
        
        let imp = JSONImport(files: projectFiles)
        imp.beginImport(false)
        
        Manager.sharedInstance.sendActionEvent("Clone Project", label: projectTitle)
        
        
      } catch {
        let errorString = NSLocalizedString("An error occured trying to copy the project.", comment: "An error occured trying to copy the project.")
        Manager.sharedInstance.showError(errorString)
        self.tableView.setEditing(false, animated: true)
        return
      }
      
      
    }
    
    self.tableView.setEditing(false, animated: true)
    
  }
  
  @IBAction func newProjectButtonPressed(_ sender: AnyObject) {
    self.newProject()
  }
  
  
}


extension ProjectListViewController: ProjectListMenuDelegate {
  
  func sort(_ sortby: String, ascending: Bool, sortByRow: Int) {
    self.sortByRow = sortByRow
    self.fetch(sortby, ascending: ascending)
  }
  
}

extension ProjectListViewController: ProjectListDelegate {
  func endEditing() {
    self.tableView.setEditing(false, animated: true)
  }
  func returnSelf() -> UIViewController {
    return self
  }
  func newProject() {
    self.performSegue(withIdentifier: "AddProject", sender: nil)
    Manager.sharedInstance.sendActionEvent("New Project", label: "")
  }
  
}
