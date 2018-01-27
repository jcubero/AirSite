//
//  ProjectListExportTableViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-10-07.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import UIKit
import PromiseKit
import CryptoSwift

class ProjectListExportTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
  
  
    var project: Project!
    var delegate: ProjectListDelegate!
    var fileManager: FileManager_!
  
    override func viewDidLoad() {
        super.viewDidLoad()
            self.tableView.delegate = self;
            self.tableView.dataSource = self;
        self.navigationController?.popoverPresentationController?.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.fileManager = nil
    }
  
    // Setting color in storyboard has no impact. Not sure why.
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }

    func zipPackaging(_ exp: ZipExport, task:Promise<Void>) -> () {
        // TODO: Uncomment and migrate it for later
//        let manager = Manager.sharedInstance
//
//        task.then { _ -> Void in
//            try exp.packageZipFile()
//            manager.stopActivity()
//            self.fileManager!.shareFile(exp.filename, cb: self.finish)
//
//            }.catch(){_ in
//                Config.error("Exporting zip error occured")
//                let err = NSLocalizedString("An error occured exporting the zip file", comment: "An error occured exporting the zip file")
//                manager.showError(err)
//            }
//        }
    }

    func finish(_ files : [FileStruct] = []) {

        self.dismiss(animated: true, completion: nil)
        //self.dismissViewController(animated: true, completion: nil)
        // self!.dismiss(animated: true, completion: nil)
        self.delegate!.endEditing()

    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        tableView.deselectRow(at: indexPath, animated: true)
        let manager = Manager.sharedInstance
        self.fileManager = FileManager_(vc: self as UIViewController, forFileTypes: [.Excel, .DB])
    
        let msgProject = NSLocalizedString("Exporting Project", comment: "Exporting Project")
        let msgReport = NSLocalizedString("Exporting Report", comment: "Exporting Report")
    
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0: // Report
                Manager.sharedInstance.exportSettings.loadDefaultSettingsFromProject(self.project)
                Manager.sharedInstance.sendActionEvent("Export Report", label: self.project.nonEmptyProjectTitle)
                let exp = PDFExport(project: self.project, exportSettings: Manager.sharedInstance.exportSettings)
        
                manager.startActivity(withMessage: msgReport)
                exp.runInBackground() {
                    manager.stopActivity()
                    
                    self.fileManager!.shareFile(exp.filename!, cb: self.finish)
                }
            case 1: // Settings
                Manager.sharedInstance.sendActionEvent("Export Settings", label: self.project.nonEmptyProjectTitle)
        
                manager.startActivity(withMessage: msgProject)
                let exporter = ExcelExport(project: self.project, withObservations: false, withPlans: false)
                exporter.promise().then { file -> () in
                    manager.stopActivity()
                    self.fileManager!.shareFile(file, cb: self.finish)
                }
          
            case 2: // Settings + Data
                Manager.sharedInstance.sendActionEvent("Export Settings + Data", label: self.project.nonEmptyProjectTitle)
                manager.startActivity(withMessage: msgProject)
        
                let exporter = ExcelExport(project: self.project, withObservations: true, withPlans: false)
                exporter.promise().then { file -> () in
                    manager.stopActivity()
                    self.fileManager!.shareFile(file, cb: self.finish)
                }
          
            case 3: // Settings + Plans
                Manager.sharedInstance.sendActionEvent("Export Settings + Plans", label: self.project.nonEmptyProjectTitle)
                manager.startActivity(withMessage: msgProject)
        
                let exp = ZipExport(project: self.project)
                let task = exp.addPlansToArchive()
                    .then { return exp.addExcelToArchive(withObservations: false, withPlans: true) }
        
                zipPackaging(exp, task: task)
        
            case 4: // Settings + Data + Report
                Manager.sharedInstance.sendActionEvent("Export Settings + Data + Report", label: self.project.nonEmptyProjectTitle)
        
                manager.startActivity(withMessage: msgProject)
        
                let exp = ZipExport(project: self.project)
                let task  = exp.addExcelToArchive(withObservations: true, withPlans: false)
                    .then { return exp.addReportToArchive() }
        
                zipPackaging(exp, task: task)
        
        
            case 5: // Settings + Data + Photos + Plans + Report
                Manager.sharedInstance.sendActionEvent("Export Settings + Data + Photos + Plans + Report", label: self.project.nonEmptyProjectTitle)
                manager.startActivity(withMessage: msgProject)
        
                let exp = ZipExport(project: self.project)

                let task = exp.addExcelToArchive(withObservations: true, withPlans: true)
                    .then { return exp.addPlansToArchive() }
                    .then { return exp.addReportToArchive() }
                    .then { return exp.addPhotosToReport() }


                zipPackaging(exp, task: task)
        
        
            case 6: // Archive
                Manager.sharedInstance.sendActionEvent("Export Archive", label: self.project.nonEmptyProjectTitle)
                manager.startActivity(withMessage: msgProject)
        
                let exp = ZipExport(project: self.project, ext: Config.projectFileExtension)
                let task = exp.addAllProjectFilesToArchive()
                    .then { return  exp.addJSONToArchive() }
                zipPackaging(exp, task: task)
        
            default:
                Config.error("undefined menu item pressed")
            
            }
        }
    }
}

 

