//
//  EditAreas.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-06-29.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit
import CoreData

class EditAreas: UIViewController , UITableViewDataSource, UITableViewDelegate {

  let manager = Manager.sharedInstance
  var project : Project? = nil
  var newArea:Bool = false
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var addButton: UIButton!
  
  @IBOutlet weak var reorderButton: UIBarButtonItem!
  var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
  fileprivate var imagePicker: ImagePicker?
  
  func fetch() {
    
    let areaFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Area")
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
    self.imagePicker = nil
    
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier == "EditArea" {
   
      let editModal = segue.destination as! EditAreaModal
      editModal.area = sender as? Area
      editModal.newArea = self.newArea
      
    }
    
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
  
  
  @IBAction func onImportPressed(_ sender: UIButton) {
    
    self.imagePicker = ImagePicker()
    self.imagePicker!.showRemove = false
    let frame = sender.superview!.convert(sender.frame, to: self.view)
    
    self.imagePicker!.loadMultipleImagePickerInViewController(self, location: frame) { files in
      
      if files.count > 0 {
        let onlyOne: Bool = files.count == 1 ? true : false
        
        for file in files {
          if file.type == .Image {
            
            let area = Area.mr_createEntity()!
            area.project = self.project!
            area.setModified()

            if let otherAreas = self.project!.areas {
              area.order = otherAreas.count as NSNumber
            } else {
              area.order = 0
            }

            area.title = file.name
            area.importInitialImageToArea(file.data)
            if onlyOne {
              self.newArea = true
              self.performSegue(withIdentifier: "EditArea", sender: area)
            } else {
              self.manager.saveCurrentState(nil)
            }
          }
        }
      } else {
        let msg = NSLocalizedString("The selected file did not contain an image or PDF", comment: "The selected file did not contain an image or PDF")
        Manager.sharedInstance.showError(msg)
        
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
  
  func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
   
    let areaFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Area")
    let predicate = NSPredicate(format: "project = %@", self.project!)
    let primarySortDescriptor = NSSortDescriptor(key: "order", ascending: true)
    
    areaFetchRequest.predicate = predicate;
    areaFetchRequest.sortDescriptors = [primarySortDescriptor]
   
    
    let results =  Area.mr_executeFetchRequest(areaFetchRequest, in: NSManagedObjectContext.mr_default()) as! [Area]
    let areas : NSMutableArray = NSMutableArray(array: results)
    let area = areas.object(at: sourceIndexPath.row) as! Area
    areas.removeObject(at: sourceIndexPath.row) 
    areas.insert(area, at: destinationIndexPath.row)
    
    
    for i in 0 ..< areas.count {
      let area: Area = areas[i] as! Area
      
      if (area.order?.int32Value == Int32(i)) { continue }
      
      area.order = i as NSNumber;
      area.setModified()
    }
    
    self.manager.saveCurrentState(nil)
    
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = self.tableView.dequeueReusableCell(withIdentifier: "EditAreasCell", for: indexPath) as! EditAreasTableViewCell
    let area = self.fetchedResultsController?.object(at: indexPath) as! Area
    
    cell.area = area
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    return true
  }
 
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    if !self.tableView.isEditing {
      let area = self.fetchedResultsController?.object(at: indexPath) as! Area
      self.newArea = false
      self.performSegue(withIdentifier: "EditArea", sender: area)
    }
    
    self.tableView.deselectRow(at: indexPath, animated: true)
  }
  
  
 func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    
    return true
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    
  }
 
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let area = self.fetchedResultsController?.object(at: indexPath) as! Area
    
    let removeString = NSLocalizedString("Remove", comment: "Remove")
    let remove = UITableViewRowAction(style: .default, title: removeString) { (UITableViewRowAction, indexPath: IndexPath) -> Void in
      
      let issueCount = area.issues!.count
      
      var message = ""
      if issueCount > 0 {
        let replMsg = NSLocalizedString("Removing this area will also remove %s observations.", comment: "Removing this area will also remove %s observations.")
        message = replMsg.replacingOccurrences(of: "%s", with: "\(issueCount)")
      }
      
      
      let titleString = NSLocalizedString("Remove area from this project?", comment: "Remove area from this project?")
      let alert = UIAlertController(title: titleString, message: message, preferredStyle: UIAlertControllerStyle.alert)
      
      let removeString = NSLocalizedString("Remove", comment: "Remove")
      alert.addAction(UIAlertAction(title: removeString, style: .destructive, handler: { action in
        self.project!.deleteProjectEntity(area)
        self.manager.saveCurrentState(nil)
      }))
      
      let cancelString = NSLocalizedString("Cancel", comment: "Cancel")
      alert.addAction(UIAlertAction(title: cancelString, style: .default, handler: { action in
        
        alert.dismiss(animated: true, completion: nil)
      }))
      
      self.present(alert, animated: true, completion: nil)
      
    }
    
    let copyString = NSLocalizedString("Copy", comment: "Copy")
    let copy = UITableViewRowAction(style: .normal, title: copyString) { (UITableViewRowAction, indexPath: IndexPath) -> Void in
      
      let newArea = Area.mr_createEntity()!
      newArea.project = self.project!
      newArea.setModified()
      
      if let otherAreas = self.project!.areas {
        newArea.order = otherAreas.count as NSNumber
      } else {
        newArea.order = 0
      }
      
      let image: Data! = area.originalImageData == nil ? area.imageData : area.originalImageData!
      newArea.title = area.title
      newArea.originalImageData = image! as NSData as Data
      newArea.imageData = image! as NSData as Data
      self.newArea = true
      self.performSegue(withIdentifier: "EditArea", sender: newArea)
    }
    
    
    return [remove, copy]
    
  }
  
}

extension EditAreas: NSFetchedResultsControllerDelegate {
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    self.tableView.reloadData()
  }
}
