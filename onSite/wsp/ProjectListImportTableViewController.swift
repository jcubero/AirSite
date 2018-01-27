//
//  ProjectListImportTableViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-10-08.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import UIKit
import CoreData

class ProjectListImportTableViewController: UITableViewController {

  
  weak var delegate: ProjectListDelegate?
  var fileManager: FileManager_?
 
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
    }
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.presentingViewController!.presentedViewController!.preferredContentSize = self.preferredContentSize
    
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.fileManager = nil
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier == "ShowProjectList" {
      let projectListPopoverViewController = segue.destination as! ProjectListPopoverViewController
      projectListPopoverViewController.delegate = self.delegate
    }
  }
  
  // Setting color in storyboard has no impact. Not sure why.
  override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    cell.backgroundColor = UIColor.clear
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    tableView.deselectRow(at: indexPath, animated: true)
    self.navigationController!.automaticallyAdjustsScrollViewInsets = true
    
    self.fileManager = FileManager_(vc: self, forFileTypes: [.Excel, .DB, .Zip])
    
    if indexPath.section == 0 {
      switch indexPath.row {
      case 0:
        
        if Manager.sharedInstance.features.sync {
          
          self.performSegue(withIdentifier: "ShowProjectList", sender: nil)
        
        } else {
          
          let title = NSLocalizedString("Import From Server", comment: "Import From Server")
          let message = NSLocalizedString("Sorry, importing a project from the server is unavailable in this version of InField", comment: "Sorry, importing a project from the server is unavailable in this version of InField")
          let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
          let cancelString = NSLocalizedString("OK", comment: "OK")
          alert.addAction(UIAlertAction(title: cancelString, style: .default, handler: { action in
            self.navigationController!.dismiss(animated: true, completion: nil)
          }))
          
          self.present(alert, animated: true, completion: nil)
          
        }
      case 1, 2:
    
        self.fileManager?.loadFilePicker(self.analyzeExcelAndZipFiles)
        
      case 3:
        self.fileManager?.loadFilePicker(self.importArchiveFile)
        
      default:
        Config.error("undefined menu item pressed")
      }
    }
  }
  
  func analyzeExcelAndZipFiles(_ files: [FileStruct]) {
    
    let excel = files.filter {$0.type == .Excel}
    let images = files.filter {$0.type == FileTypes.Image}
    
    // warn user if there are more than 15 images in zip
    if files.count > 1 && excel.count == 1 && images.count > 15 {
      
      let title = NSLocalizedString("Import", comment: "Import")
      let titleString = NSLocalizedString("import project with %s areas?", comment: "import project with %s areas?")
      let message = titleString.replacingOccurrences(of: "%s", with: "\(images.count)")
      
      let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
      
      let removeString = NSLocalizedString("Import", comment: "Import")
      alert.addAction(UIAlertAction(title: removeString, style: .default, handler: { action in
        
        Manager.sharedInstance.sendActionEvent("Import Project Excel/Zip", label: "")
        
        self.processExcelAndZipFiles(files)
        
      }))
      
      let cancelString = NSLocalizedString("Cancel", comment: "Cancel")
      alert.addAction(UIAlertAction(title: cancelString, style: .cancel, handler: { action in
        self.navigationController!.dismiss(animated: true, completion: nil)
      }))
      
      self.present(alert, animated: true, completion: nil)
      return
    }
    
    self.processExcelAndZipFiles(files)
    
    
  }
 
  
  func processExcelAndZipFiles(_ files: [FileStruct]) {
    
    let excel = files.filter {$0.type == .Excel}
    let images = files.filter {$0.type == FileTypes.Image}
    
    Manager.sharedInstance.startActivity(withMessage: NSLocalizedString("Importing project", comment: ""))
    
    let errCb: (String?) -> () = { error in
      
      if error != nil {
        Config.error(error!)
        Manager.sharedInstance.showError(error!)
      } else {
        Manager.sharedInstance.stopActivity()
      }
    }
    
    if files.count == 1  && files.first!.type == FileTypes.Excel {
      
      let file = files[0]
      
      self.excelImport(file, areas: nil, cb: errCb)
        
    } else if files.count > 1 {
      
      if excel.count == 1 {
        self.excelImport(excel[0], areas: images, cb: errCb)
      } else {
        errCb(NSLocalizedString("More than one excel file found! Aborted.", comment: ""))
      }
      
    }
    
    self.navigationController!.dismiss(animated: true, completion: nil)
    
    
  }
  
  
  func excelImport(_ excel: FileStruct, areas: [FileStruct]?, cb: @escaping (String?) -> ())  {
    
    guard let excelFilePath = excel.path else {
      cb( NSLocalizedString("Couldn't read excel file.", comment: "Couldn't read excel file."))
      return
    }
    
    let importer = ExcelImport(excelFilePath: excelFilePath)
    
    importer.importAll(areas, cb: cb)
    
  }
  
  func importArchiveFile(_ files: [FileStruct]) {
    
    Manager.sharedInstance.sendActionEvent("Import Project Archive", label: "")
    
    if files.count == 1 && files.first!.type != .JSON {
      let err = NSLocalizedString("Looks like this archive was created by a previous version of inField", comment: "")
      Manager.sharedInstance.showError(err)
      return
    }
    
    if files.index(where: {$0.type == .JSON }) == nil {
      let err = NSLocalizedString("Looks like this archive was created by a previous version of inField", comment: "")
      Manager.sharedInstance.showError(err)
      return
    }
    
    let json = JSONImport(files: files)
    
    if json.projectAlreadyExists {
      let err = NSLocalizedString("This project already exists", comment: "This project already exists")
      let alert = UIAlertController(title: err, message: "", preferredStyle: UIAlertControllerStyle.alert)
      let cancelString = NSLocalizedString("Cancel", comment: "Cancel")
      alert.addAction(UIAlertAction(title: cancelString, style: .default, handler: { action in
        
        alert.dismiss(animated: true, completion: nil)
        self.navigationController!.dismiss(animated: true, completion: nil)
      }))
      
      let replaceString = NSLocalizedString("Replace", comment: "Replace")
      alert.addAction(UIAlertAction(title: replaceString, style: .default, handler: { action in
        
        alert.dismiss(animated: true, completion: nil)
        self.navigationController!.dismiss(animated: true, completion: nil)
      }))
      
      self.present(alert, animated: true, completion: nil)
      
    } else {
      json.beginImport(true)
      
      self.navigationController!.dismiss(animated: true, completion: nil)
    }
  
  }
  
  
}
