//
//  UsersTableViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-08-05.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import Foundation

import UIKit
import CoreData



class UsersTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
  let manager = Manager.sharedInstance
  let cache: String = "ProjectUsersCache"
  var project : Project!
  
  var search: String = "" { didSet { self.updateFetchRequest() } }
  var scope: Int = 0 { didSet { self.updateFetchRequest() } }
  
  @IBOutlet weak var tableView: UITableView!
 
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let usersFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        let primarySortDescriptor = NSSortDescriptor(key: "username", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        
        usersFetchRequest.predicate = self.currentPredicate;
        usersFetchRequest.sortDescriptors = [primarySortDescriptor]
        
        let frc = NSFetchedResultsController( fetchRequest: usersFetchRequest,
                                              managedObjectContext: NSManagedObjectContext.mr_default(),
                                              sectionNameKeyPath: nil,
                                              cacheName: self.cache)
        
        frc.delegate = self
        
        return frc
    
    }()
  
  var currentPredicate: NSPredicate? {
    get {
      
      // first delete the cache before mutating the predicate. Else: crash :(
      // seems like an apple bug!
      NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: cache)
      
      if self.search.characters.count == 0 {
        if self.scope == 1 {
          return NSPredicate(format: "any projects.project = %@ ", self.project)
        }
        return nil
      } else {
        if self.scope == 1 {
          return NSPredicate(format: "(username contains[cd] %@) and any projects.project = %@ ", self.search, self.project)
        }
        return NSPredicate(format: "(username contains[cd] %@)", self.search)
      }
    }
  }
  
  override func viewDidLoad() {
    
    if let vc = self.parent?.parent as? EditProjectTabBarController {
      self.project = vc.project
    }
    
    do {
     try self.fetchedResultsController.performFetch()
    } catch _ as NSError {
      Config.error("Couldn't fetch")
    }
    self.tableView.tableFooterView = UIView()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    Manager.sharedInstance.saveCurrentState(nil)
  }
  
  func updateFetchRequest() {
    
    var error: NSError? = nil
    let predicate = self.currentPredicate
    
    self.fetchedResultsController.fetchRequest.predicate = predicate
    do {
      try self.fetchedResultsController.performFetch()
    } catch let error1 as NSError {
      error = error1
    }
    
    if let _ = error {
      Config.error("Something went wrong when fetching tags")
    }
    self.tableView.reloadData()
    
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    
    if let sections = self.fetchedResultsController.sections {
      return sections.count
    }
    
    return 0
    
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    if let sections = self.fetchedResultsController.sections {
      let currentSection = sections[section] 
      return currentSection.numberOfObjects
    }
    
    return 0
  }
  
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = self.tableView.dequeueReusableCell(withIdentifier: "EditProjectUsersCell", for: indexPath)  as! EditUsersTableViewCell
    let user = self.fetchedResultsController.object(at: indexPath) as! User
    
    cell.setUser(user, project: project)
    return cell
    
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    let user = self.fetchedResultsController.object(at: indexPath) as! User
    let projectUser = ProjectUser.getOrCreateUserForProject(self.project, user: user)
    let cell = tableView.cellForRow(at: indexPath) as! EditUsersTableViewCell
    
    if projectUser.active.boolValue && cell.touchSide == .right {
      self.loadInputFieldForUser(projectUser, cancel: {
        
      })
      
    } else {
      
      projectUser.active = projectUser.active.boolValue as NSNumber
      self.project.resetUserLogic()

      if projectUser.active.boolValue && projectUser.label == "" {
        
        self.loadInputFieldForUser(projectUser, cancel: {
          projectUser.active = false
          self.project.resetUserLogic()
        })
        
      } else {
        self.tableView.reloadData()
      }
    }
    
  }
  
  func loadInputFieldForUser(_ projectUser: ProjectUser, cancel: @escaping ()->()) {
    
    var inputTextField: UITextField!
    
    let actionSheetController: UIAlertController = UIAlertController(title: NSLocalizedString("User Label", comment: "User Label"), message: "", preferredStyle: .alert)
    
    actionSheetController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel) { action -> Void in
      cancel()
      
      self.tableView.reloadData()
      
      })
    actionSheetController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default) { action -> Void in
      projectUser.label = inputTextField.text!
      self.tableView.reloadData()
      })
    
    actionSheetController.addTextField { textField -> Void in
      inputTextField = textField
      inputTextField.text = projectUser.label
      inputTextField.addTarget(self, action: #selector(UsersTableViewController.textChanged(_:)), for: .editingChanged)
    }
    
    (actionSheetController.actions[1] as UIAlertAction).isEnabled = projectUser.label != ""
    
    self.present(actionSheetController, animated: true, completion: nil)
    
  }
  
  
  @objc func textChanged(_ sender:AnyObject) {
    let tf = sender as! UITextField
    var resp : UIResponder = tf
    while !(resp is UIAlertController) { resp = resp.next! }
    let alert = resp as! UIAlertController
    (alert.actions[1] as UIAlertAction).isEnabled = (tf.text != "")
  }
  
  
}

extension UsersTableViewController: NSFetchedResultsControllerDelegate {
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    self.tableView.reloadData()
  }
}


extension UsersTableViewController: UISearchBarDelegate {
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    
    self.search = searchText
    
  }
  
  func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
    
    self.scope = selectedScope
    
  }
  
}
