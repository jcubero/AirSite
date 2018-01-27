//
//  SelectProjectTableViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-08-21.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit
import CoreData

protocol SelectProjectDelegate {
  func selectProject(_: Project)
}


class SelectProjectTableViewController: UITableViewController {

  var currentProject: Project? = nil
  var delegate: SelectProjectDelegate? = nil
  
  lazy var fetchedResultsController: NSFetchedResultsController = { () -> NSFetchedResultsController<NSFetchRequestResult> in 
    
    let areaFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Project")
    let primarySortDescriptor = NSSortDescriptor(key: "title", ascending: true)
    if let project = self.currentProject {
      let predicate = NSPredicate(format: "self != %@", project)
      areaFetchRequest.predicate = predicate
    }
    
    areaFetchRequest.sortDescriptors = [primarySortDescriptor]
    
    let frc = NSFetchedResultsController( fetchRequest: areaFetchRequest,
      managedObjectContext: NSManagedObjectContext.mr_default(),
      sectionNameKeyPath: nil,
      cacheName: nil)
    
    frc.delegate = self
    
    return frc
    }()       
  
  
  override func viewDidLoad() {
    do {
      try self.fetchedResultsController.performFetch()
    } catch {
      Config.error("Couldn't fetch results!")
    }
    
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    if let sections = self.fetchedResultsController.sections {
      return sections.count
    }
    
    return 0
    
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    if let sections = self.fetchedResultsController.sections {
      let currentSection = sections[section] 
      return currentSection.numberOfObjects
    }
    
    return 0
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = self.tableView.dequeueReusableCell(withIdentifier: "SelectProjectCell", for: indexPath) 
    let project = self.fetchedResultsController.object(at: indexPath) as! Project
    
    cell.textLabel?.text = project.nonEmptyProjectTitle
    
    return cell
  }
  
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let project = self.fetchedResultsController.object(at: indexPath) as! Project
    
    self.delegate?.selectProject(project)
    
    self.dismiss(animated: true, completion: nil)
  }
  
  
}


extension SelectProjectTableViewController: NSFetchedResultsControllerDelegate {
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    self.tableView.reloadData()
    
  }
}

