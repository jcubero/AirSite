//
//  ImportTagsTableViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-10-09.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import UIKit
import Foundation
import MobileCoreServices
import zipzap
import PromiseKit
import CryptoSwift
class ImportTagsTableViewController: UITableViewController {

  
  var project: Project!
  weak var callingVc: EditLibraryViewController!
 
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.presentingViewController!.presentedViewController!.preferredContentSize = self.preferredContentSize

  }
 
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier == "SelectProject" {
      let vca = segue.destination as! SelectProjectTableViewController
      vca.delegate = self
      vca.currentProject = self.project
      
    }
  }
  
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    tableView.deselectRow(at: indexPath, animated: true)
    self.navigationController!.automaticallyAdjustsScrollViewInsets = true
    

    if indexPath.section == 0 {
      switch indexPath.row {
      case 0:
        let fileManager = FileManager_(vc: self, forFileTypes: [.Excel])

        fileManager.loadFilePicker() { files in
          self.navigationController!.dismiss(animated: true, completion: nil)

          Manager.sharedInstance.startActivity(withMessage: NSLocalizedString("Importing Tags", comment: "'"))

          self.callingVc.importTagsFromFiles(files, cb: nil)
          
        }
      case 1:
        break
      default:
        Config.error("undefined menu item pressed")
      }
    }
  }
  
  
  
}



extension ImportTagsTableViewController: SelectProjectDelegate {
  
  func selectProject(_ project: Project) {
    
    let manager = Manager.sharedInstance
    Manager.sharedInstance.startActivity(withMessage: NSLocalizedString("Importing Tags", comment: "'"))

    let exporter = ExcelExport(project: project, withObservations: false, withPlans: false)
    
    exporter.promise().then { file ->() in
      let st = FileStruct(url: file, name: "excel.xlsx", type: .Excel)
      self.callingVc.importTagsFromFiles([st], cb: { err in

      })
        }.catch { error in
            
            let msg = NSLocalizedString("An error occured importing tags", comment: "An error occured importing tags")
            manager.showError(msg)
            self.navigationController!.dismiss(animated: true, completion: nil)
        }
    }
}




