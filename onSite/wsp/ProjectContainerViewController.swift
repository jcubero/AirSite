//
//  ProjectContainerViewController.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-12-02.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import UIKit

enum Orientation {
  case landscape, portrait
}

class ProjectContainerViewController: UIViewController {
  
  var project: Project!
  weak var projectTitleView: UIView!
  weak var projectSplitView: ProjectSplitView?
  weak var titleLabel: UILabel!
  weak var burgerButton: UIButton?

  var areaName: String = ""
  weak var readerVC: ReaderViewController!
  var readerDocument: ReaderDocument?
  
  let margin: CGFloat = 100
  
  var burgerRight:CGFloat {
    get {
      return self.currentOrientation == .landscape ? 325 : 305
    }
  }
  
  var topWidth : CGFloat {
    get {
      return self.currentOrientation == .landscape ? 1024 : 768
    }
  }
  
  var activeArea: Area? {
    get {
      return self.projectSplitView?.activeArea
    }
  }
  
  

  var currentOrientation: Orientation = .landscape {
    didSet {
      self.calculateFrames()
    }
  }
  
  var navHidden: Bool {
    get {
      return self.projectSplitView!.navHidden
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    let projectTitleView = UIView(frame: CGRect(x: 0,y: 0, width: self.topWidth - self.margin * 2, height: 44))
    self.projectTitleView = projectTitleView
    self.navigationItem.titleView = self.projectTitleView

    
    let titleLabel = UILabel(frame: self.projectTitleView.frame)
    self.titleLabel = titleLabel
    self.titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
    self.titleLabel.text = self.areaName
    self.titleLabel.backgroundColor = UIColor.clear
    self.titleLabel.isOpaque = false
    self.titleLabel.textColor = UIColor.white
    self.titleLabel.textAlignment = .center
    
    self.projectTitleView.addSubview(self.titleLabel)
    
    NotificationCenter.default.addObserver(self, selector: #selector(ProjectContainerViewController.rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    self.rotated()
    
    let repTitle = NSLocalizedString("Report", comment: "Report")
    addRightArrowButtonToNavigationBar(withTitle: repTitle, target: self, selector: #selector(ProjectContainerViewController.reportSelected(_:)))
    
    self.navigationItem.backBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Data Collecting", comment: "Data Collecting"), style: .plain, target: nil, action: nil)
    self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  override var preferredStatusBarStyle : UIStatusBarStyle {
    return UIStatusBarStyle.lightContent
  }
  
  override func viewWillAppear(_ animated: Bool) {
    self.calculateFrames()
    Manager.sharedInstance.sendScreenView("Data Collecting")
    
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let vc = segue.destination as? ProjectSplitView {
      vc.project = self.project
      vc.container = self
      self.projectSplitView = vc
    }
  }
  
  
  func addHamburger() {
    
    if self.burgerButton == nil {
      let fontSize: CGFloat = 25

      let burgerButton = UIButton(type: UIButtonType.custom)
      let attributes = [NSAttributedStringKey.font: UIFont.materialIconsOfSize(fontSize), NSAttributedStringKey.foregroundColor: UIColor.white]
      let string = NSAttributedString(string: "", attributes: attributes)
      
      
      burgerButton.setAttributedTitle(string, for: UIControlState())
      burgerButton.titleLabel?.textAlignment = NSTextAlignment.right
      burgerButton.sizeToFit();
      burgerButton.addTarget(self, action: #selector(ProjectContainerViewController.hamburgerPressed(_:)), for: .touchUpInside)
      burgerButton.frame.origin.y = 5
      self.calculateFrames()
      self.burgerButton = burgerButton

      self.projectTitleView.addSubview(burgerButton)
    }
  }
  
  func calculateFrames() {
    self.projectTitleView.frame.size.width = self.topWidth - self.margin * 2
    
    if self.burgerButton != nil {
      let fontSize: CGFloat = 25
      self.burgerButton!.frame.origin.x = self.burgerRight - self.margin - fontSize - 20
    }
    
    if self.navHidden {
      
      self.titleLabel.frame.origin.x = 0
      self.titleLabel.frame.size.width = self.projectTitleView.frame.size.width
      
      self.burgerButton?.isHidden = true
      
    } else {
      
      self.titleLabel.frame.origin.x = self.burgerRight
      self.titleLabel.frame.size.width = self.projectTitleView.frame.size.width - self.burgerRight
      
      self.burgerButton?.isHidden = false
      
    }
    
  }
  
  func removeHamburger() {
    
    if let button = self.burgerButton {
      button.removeFromSuperview()
      self.burgerButton = nil
    }
  }

  @objc func hamburgerPressed(_ sender: AnyObject?) {
    self.projectSplitView?.hideComments()
    
  }
  
  @objc func rotated() {
    
    if(UIDeviceOrientationIsLandscape(UIDevice.current.orientation)) {
      self.currentOrientation = .landscape
    } else if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
      self.currentOrientation = .portrait
    }
    
  }
  
  func updateTitle() {
    var string = ""
    
    if let area = self.activeArea {
      string = area.title
    }
    
    self.areaName = string
    if self.titleLabel != nil {
      self.titleLabel.text = string
    }
  }
  
  @objc func reportSelected(_ sender: AnyObject?) {
    self.loadPDFViewController()
  }
}



extension ProjectContainerViewController: ReaderViewControllerDelegate, UIPopoverPresentationControllerDelegate, ExportSettingsDelegate {
  
  
  func loadPDFViewController() {
    
  
    Manager.sharedInstance.exportSettings.loadDefaultSettingsFromProject(self.project)
    Manager.sharedInstance.exportSettings.delegate = self
   
    let exporter = PDFExport(project: self.project, exportSettings: Manager.sharedInstance.exportSettings)
    
    Manager.sharedInstance.startActivity(withMessage: NSLocalizedString("Generating Report", comment: "Generating Report"))
    
    exporter.loadFilter(project!.filter)
    exporter.runInBackground() {
      Manager.sharedInstance.stopActivity()
      
      let document = ReaderDocument(filePath: exporter.filename!.path, password: "")
      if let d = document {
        Manager.sharedInstance.sendScreenView("Report")
        self.readerDocument = d
        let vc = ReaderViewController(readerDocument: d)
        self.readerVC = vc
        self.readerVC.title = NSLocalizedString("Report", comment: "Report")
        self.navigationController?.pushViewController(vc!, animated: true)
        self.readerVC.delegate = self
      }
    }
    
  }
  
  
  func ready(forDocument viewController: ReaderViewController!) {
    
    viewController.change(self.readerDocument)
    
  }
  
  func dismiss(_ viewController: ReaderViewController!) {
    
    Manager.sharedInstance.exportSettings.delegate = nil
    self.navigationController?.popViewController(animated: true)
    self.navigationController?.setNavigationBarHidden(false, animated: false)
    self.readerVC = nil
    
  }
  
  func configureReaderViewController(_ viewController: ReaderViewController!, fromButton button: UIBarButtonItem!) {
    
    let vc = UIStoryboard(name: "ReportSettings", bundle: nil).instantiateInitialViewController() as! UINavigationController
    vc.modalPresentationStyle = .popover
    let popover = vc.popoverPresentationController!
    
    popover.barButtonItem = button
    popover.permittedArrowDirections = .any
    popover.delegate = self
    
    viewController.present(vc, animated: true, completion: nil)
    
  }
  
  
  func didChangeSettings(_ settings: ExportSettings) {
   
    let exporter = PDFExport(project: self.project, exportSettings: settings)
    Manager.sharedInstance.startActivity(withMessage: NSLocalizedString("Generating Report", comment: "Generating Report"))


    exporter.loadFilter(project!.filter)

    exporter.runInBackground() {
      Manager.sharedInstance.stopActivity()
      
      self.readerDocument = ReaderDocument(filePath: exporter.filename!.path, password: "")
      
      self.readerVC.change(self.readerDocument)
      Manager.sharedInstance.exportSettings.hasChanges = false
      
    }
  }
  
  
  func getPDF(_ completion: @escaping (URL) -> ()) {
    
    
    let exporter = PDFExport(project: self.project, exportSettings: Manager.sharedInstance.exportSettings)
    
    if Manager.sharedInstance.exportSettings.hasChanges {

      exporter.loadFilter(project!.filter)
      Manager.sharedInstance.startActivity(withMessage: NSLocalizedString("Generating Report", comment: "Generating Report"))
      
      exporter.runInBackground() {
        Manager.sharedInstance.stopActivity()
        self.readerDocument = ReaderDocument(filePath: exporter.filename!.path, password: "")
        
        self.readerVC.change(self.readerDocument)
        
        Manager.sharedInstance.exportSettings.hasChanges = false
        
        completion(exporter.filename! as URL)
        
      }
      
    } else {
      completion(exporter.filename! as URL)
    }
    
  }
  
}



