//
//  EditForms.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-05-26.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
import CoreData

class EditForms: UIViewController , UITableViewDataSource, UITableViewDelegate  {

  let manager = Manager.sharedInstance
  var project : Project? = nil
  var newArea:Bool = false
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var addButton: UIButton!
  @IBOutlet weak var emptyState: UIView!
  
  @IBOutlet weak var reorderButton: UIBarButtonItem!
  var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
  fileprivate var fileManager: FileManager_?
  
  func fetch() {
    
    let areaFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Form")
    let predicate = NSPredicate(format: "project = %@", self.project!)
    let primarySortDescriptor = NSSortDescriptor(key: "order", ascending: true)
    
    areaFetchRequest.predicate = predicate;
    areaFetchRequest.sortDescriptors = [primarySortDescriptor]
    
    self.fetchedResultsController = NSFetchedResultsController( fetchRequest: areaFetchRequest,
      managedObjectContext: NSManagedObjectContext.mr_default(),
      sectionNameKeyPath: nil,
      cacheName: nil)
    self.fetchedResultsController!.delegate = self
    
    do {
      try self.fetchedResultsController!.performFetch()
      render()
    } catch {
      Config.error("Could not fetch results")
    }
    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.tableView.isEditing = false
    self.tableView.allowsMultipleSelectionDuringEditing = true
    
    if let vc = self.parent?.parent as? EditProjectTabBarController {
      self.project = vc.project
    }
    
    self.fetch()
    self.addButton.addShadow()
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 100, 0);
    self.tableView.tableFooterView = UIView()
  
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.fileManager = nil

  }
  
  func toggleEditing() -> Bool {
    
    self.tableView.isEditing  = !self.tableView.isEditing
    if self.tableView.isEditing {
      self.reorderButton.title = NSLocalizedString("Done", comment: "Done reordering areas")
    } else {
      self.reorderButton.title = NSLocalizedString("Reorder", comment: "Reorder areas")
    }
    
    return self.tableView.isEditing
  }
  
  
  
  @IBAction func onReorderPressed(_ sender: AnyObject) {
    
    self.toggleEditing()
    
  }
  
  // let fileManager:FileManager_!
    func importTags(_ files: [FileStruct])
    {
        if files.count == 1 {
            // load err up!
            let file = files[0]
            
            let form = Form.mr_createEntity()!
            form.project = self.project!
            form.setModified()
            form.title = file.name
            form.pdfData = file.data
            form.order = form.nextOrder as NSNumber
            
            self.manager.saveCurrentState(nil)
            
        } else {
            let errorString = NSLocalizedString("The form must be a PDF file", comment: "The form must be a PDF file")
            Manager.sharedInstance.showError(errorString)
        }
    }
    

    @IBAction func onImportPressed(_ sender: UIButton) {
        self.fileManager = FileManager_(vc: self, forFileTypes: [.PDF])
        self.fileManager?.loadFilePicker(importTags)
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
  
  func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
   
    let results = Form.mr_find(byAttribute: "project", withValue: project!, andOrderBy: "order", ascending: true) as! [Form]
    
    let areas : NSMutableArray = NSMutableArray(array: results)
    let area = areas.object(at: sourceIndexPath.row) as! Form
    areas.removeObject(at: sourceIndexPath.row) 
    areas.insert(area, at: destinationIndexPath.row)
    
    
    for i in 0 ..< areas.count {
      let area: Form = areas[i] as! Form
      
      if (area.order == i as NSNumber) { continue }
      
      area.order = i as NSNumber;
      area.setModified()
    }
    
    self.manager.saveCurrentState(nil)
    
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = self.tableView.dequeueReusableCell(withIdentifier: "EditFormsCell", for: indexPath) as! EditFormsTableViewCell
    let form = self.fetchedResultsController?.object(at: indexPath) as! Form
    
    cell.form = form
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    return true
  }
 
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
   
    let form = self.fetchedResultsController?.object(at: indexPath) as! Form
    let alert = UIAlertController(title: NSLocalizedString("Form Title", comment: "Form Title"), message: NSLocalizedString("Please enter the new form title.", comment: "Please enter the new form title."), preferredStyle: UIAlertControllerStyle.alert)

    alert.addTextField { textfield in
      textfield.text = form.title
      
    }
    
    alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.cancel, handler:{ (UIAlertAction) in
  
    }))

    alert.addAction(UIAlertAction(title: NSLocalizedString("Rename", comment: "Rename"), style: UIAlertActionStyle.default, handler:{ (UIAlertAction)in
      let text = alert.textFields![0].text!
      if text != "" {
        form.title = text
      }
      self.manager.saveCurrentState(nil)
    }))

    self.present(alert, animated: true, completion: nil)
    
    self.tableView.deselectRow(at: indexPath, animated: true)
  }
  
  
  
  
  
 func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    
    return true
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    
  }
 
  
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let form = self.fetchedResultsController?.object(at: indexPath) as! Form
    
    let removeString = NSLocalizedString("Remove", comment: "Remove")
    let remove = UITableViewRowAction(style: .default, title: removeString) { (UITableViewRowAction, indexPath: IndexPath) -> Void in
      
      let message = ""
      
      let titleString = NSLocalizedString("Remove this form from this project?", comment: "Remove this form from this project?")
      let alert = UIAlertController(title: titleString, message: message, preferredStyle: UIAlertControllerStyle.alert)
      
      let removeString = NSLocalizedString("Remove", comment: "Remove")
      alert.addAction(UIAlertAction(title: removeString, style: .destructive, handler: { action in
        self.project!.deleteProjectEntity(form)
        self.manager.saveCurrentState(nil)
      }))
      
      let cancelString = NSLocalizedString("Cancel", comment: "Cancel")
      alert.addAction(UIAlertAction(title: cancelString, style: .default, handler: { action in
        alert.dismiss(animated: true, completion: nil)
      }))
      
      self.present(alert, animated: true, completion: nil)
      
    }
    
    
    return [remove]
    
  }
  
  
  func render() {
    
    let count = self.fetchedResultsController!.fetchedObjects!.count
    
    if count == 0 {
      emptyState.isHidden = false
      reorderButton.isEnabled = false
    } else {
      emptyState.isHidden = true
      if count == 1 {
        reorderButton.isEnabled = false
      } else {
        reorderButton.isEnabled = true
      }
      
    }
    
    
  }
  
}

extension EditForms: NSFetchedResultsControllerDelegate {
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    self.tableView.reloadData()
    render()
    
  }
}
