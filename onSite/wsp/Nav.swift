//
//  Plans.swift
//  wsp
//
//  Created by Jon Harding on 2015-07-29.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit
import CoreData

class Nav: UIViewController, CategoryPopoverDelegate, ActiveFilterProtocol {
  
  let manager : Manager = Manager.sharedInstance
  
  @IBOutlet weak var tableView: UITableView!
  
  weak var searchBar: UISearchBar!
  
  var project: Project!
  var issue: Issue?
  weak var rootView: ProjectSplitView!
  
  var activeArea: Area? {
    get {
      return self.rootView.activeArea
    } set {
      self.rootView.activeArea = newValue
    }
  }
  
  var activeForm: Form? {
    get {
      return self.rootView.activeForm
    } set {
      self.rootView.activeForm = newValue
    }
  }
  
  var activeIssue: Issue? {
    get {
      return self.rootView.activeIssue
    }
  }

  var filter: Filter {
    return self.project.filter
  }
  

  fileprivate var fileManager: FileManager_!
  fileprivate var loadCommnets: Bool = false
 
  @IBOutlet weak var commentsView: CommentsView!
  @IBOutlet weak var plansView: UIView!
  @IBOutlet weak var plansLeading: NSLayoutConstraint!
  @IBOutlet weak var footerBottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
  
  @IBOutlet weak var pillButton: UIButton!
  
  @IBOutlet weak var imageButton: UIButton!
  @IBOutlet weak var categoryHeightConstraint: NSLayoutConstraint!

  @IBOutlet weak var filterContainerHeight: NSLayoutConstraint!


  
  func autoComments() {
    
    if self.project.openCamera.boolValue {
      self.showCamera(nil)
      self.loadCommnets = true
    } else if self.project.openComments.boolValue {
      self.rootView.showNav()
      self.focusCommentKeyboard()
    }
    
  }
  
  func afterImageSelection(_ comment: Comment?) {
    
    if !self.loadCommnets { return }
    
    self.loadCommnets = false
    if self.project.openComments.boolValue && comment != nil {
      self.rootView.showNav()
      self.rootView.pages.showCommentImageEditor(comment!)
    }
  }
  
 
  @IBAction func showCamera(_ sender: UIButton?) {
   
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      let vc = self.storyboard!.instantiateViewController(withIdentifier: "ImageEditorViewController") as! ImageEditorViewController
      vc.mode = .camera
      vc.modalPresentationStyle = .formSheet
      vc.delegate = self.commentsView
      vc.initialText = self.commentsView.textField.text!
      vc.navController = self
      self.present(vc, animated: true, completion: nil)
      
    } else {
      
      var frame: CGRect = CGRect.zero
      if sender != nil {
        frame = sender!.superview!.convert(sender!.frame, to: self.view)
      }
      
      self.fileManager = FileManager_(vc: self, forFileTypes: [.Image])
      self.fileManager.loadImagePickerInViewController(frame, cb: { files in
        if files.count > 0 {
          self.getImage(files.first!.data)
        }
      })
      
    }
  }
  
  func focusCommentKeyboard() {
    
    if self.issue != nil {
      self.commentsView.activateKeyboard()
      
    }
    
  }
  
  func reload() {
    self.updateComments()
  }
  
  func reloadAndUpdateTable() {
    self.tableView.reloadData()
    
    if let area = self.activeArea, let indexPath = self.fetchedResultsController.indexPath(forObject: area) {
      self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableViewScrollPosition.top)
    }
    
  }
  
  @IBAction func showPhotoLibrary(_ sender: UIButton) {
    
    let frame = sender.superview!.convert(sender.frame, to: self.view)
    self.fileManager = FileManager_(vc: self, forFileTypes: [.Image])
    self.fileManager.loadImagePickerInViewController(frame, cb: { files in
      if files.count > 0 {
        self.getImage(files.first!.data)
      }
    })
    
  }
  
  @IBAction func showImagePicker(_ sender: UIButton) {
    
    self.fileManager = FileManager_(vc: self, forFileTypes: [.Image])
    self.fileManager.loadFilePicker() {
      files in
      for file in files {
        if file.type == .Image {
          // only consider 1 image file
         self.getImage(file.data)
        }
      }
      
    }
    
  }
  
  
  @IBAction func showMap(_ sender: UIButton) {
    
    self.getImage(self.activeArea!.imageData!)
    
  }
  
  
  func getImage(_ data: Data) {
    
    let vc = self.storyboard!.instantiateViewController(withIdentifier: "ImageEditorViewController") as! ImageEditorViewController
    vc.origImage = UIImage(data: data)
    vc.mode = .crop
    vc.modalPresentationStyle = .formSheet
    vc.initialText = self.commentsView.textField.text!
    vc.delegate = self.commentsView
    vc.navController = self
    self.fileManager = nil
    self.present(vc, animated: true, completion: nil)
      
  }
 //   var fetchedResultsController: NSFetchedResultsController<Area>
        
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = { [unowned self] in
        if let project = self.project {
            let areaFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Area")
            let predicate = NSPredicate(format: "project = %@", project)
            let primarySortDescriptor = NSSortDescriptor(key: "order", ascending: true)
            
            areaFetchRequest.predicate = predicate;
            areaFetchRequest.sortDescriptors = [primarySortDescriptor]
            
            let frc = NSFetchedResultsController( fetchRequest: areaFetchRequest,
                                                  managedObjectContext: NSManagedObjectContext.mr_default(),
                                                  sectionNameKeyPath: nil,
                                                  cacheName: nil)
            
            frc.delegate = self
            
            return frc
        }
        return NSFetchedResultsController()
        }()
    
    
  
   
  lazy var forms: [Form] = { [unowned self] in
    if let project = self.project {
      return Form.mr_find(byAttribute: "project", withValue: project, andOrderBy: "order", ascending: true) as! [Form]
    }
    return []
    }()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.delegate = self
    self.tableView.dataSource = self 
    
    automaticallyAdjustsScrollViewInsets = false
    extendedLayoutIncludesOpaqueBars = false
    edgesForExtendedLayout = UIRectEdge.bottom
    
    commentsView.footerBottomConstraint = self.footerBottomConstraint
    commentsView.headerHeightConstraint = self.headerHeightConstraint
    commentsView.categoryHeightConstraint = self.categoryHeightConstraint
    
    if let nav = self.navigationController?.navigationBar {
      nav.barTintColor = UIColor.wspNeutral()
        nav.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
    }
    
    do {
        try fetchedResultsController.performFetch()
    } catch {
      Config.error("Could not fetch results from controller.")
    }
    
    commentsView.rootView = self.rootView
    
    tableView.tableFooterView = UIView()
    
    let searchBar = UISearchBar(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: self.tableView.bounds.width, height: 44)))
    searchBar.barTintColor = UIColor.wspNeutral()
    searchBar.placeholder = NSLocalizedString("Search Observations", comment: "Search Observations")
    searchBar.delegate = self
    searchBar.showsCancelButton = false
    tableView.tableHeaderView = searchBar
    searchBar.sizeToFit()

    self.searchBar = searchBar

  }

  func selectFirstArea() {

    if self.fetchedResultsController.fetchedObjects != nil{
        if (self.fetchedResultsController.fetchedObjects?.count)! > 0 {
            self.delay(0.1, closure: { [unowned self] in
                let indexPath = IndexPath(row: 0, section: 0)
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.bottom)
                self.tableView(self.tableView, didSelectRowAt: indexPath)
                
            })
        }
    } else {
        print("No Fetched Objects")
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.fileManager = nil

  }
  
  override var preferredStatusBarStyle : UIStatusBarStyle {
    return UIStatusBarStyle.lightContent
  }
  
  
  func updateComments() {
    if let issue = self.activeIssue {
      self.issue = issue
      self.commentsView.loadComments(issue)
      UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
        self.plansView.frame.origin.x = -self.plansView.frame.width
        self.commentsView.frame.origin.x = 0
        }, completion: { finished in
      })
    } else {
      self.commentsView.dismissKeyboard()
      
      UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
        self.plansView.frame.origin.x = 0
        self.commentsView.frame.origin.x = self.plansView.frame.width
        }, completion: { finished in
      })
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if self.activeIssue != nil {
      self.plansView.frame.origin.x = -self.plansView.frame.width
      self.commentsView.frame.origin.x = 0
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "FilterPopover" {
      if let vc = segue.destination as? LibraryPopover {
        vc.popoverPresentationController?.sourceRect = vc.popoverPresentationController!.sourceView!.bounds
        vc.delegate = self
        vc.project = self.project
        vc.mode = .filterTree
        vc.imageCache = self.rootView.pages.areaView?.imageCache
      }
    } else if segue.identifier == "FilterLevelPopover" {
      guard let vc = segue.destination as? LibraryPopover else {
        Config.error()
        return
      }

      vc.popoverPresentationController?.sourceRect = vc.popoverPresentationController!.sourceView!.bounds
      
      vc.delegate = self
      vc.project = self.project
      vc.mode = .filterTag
      vc.imageCache = self.rootView.pages.areaView?.imageCache

    } else if segue.identifier == "ShowLibrary" {
      if let vc = segue.destination as? LibraryPopover {
        vc.delegate = self
        vc.sourceIssue = self.commentsView.issue
        vc.cloneTagsFromSourceIssue()
        vc.project = self.project
        vc.mode = .edit
        vc.imageCache = self.rootView.pages.areaView?.imageCache
        vc.popoverPresentationController?.sourceRect = vc.popoverPresentationController!.sourceView!.bounds
      }
    } else if let vc = segue.destination as? ActiveFilterTableViewController {

      vc.filter = self.filter
      vc.delegate = self
      self.filter.delegates.addDelegate(vc)

    } else if let vc = segue.destination as? FilterDateViewController {
      vc.popoverPresentationController?.sourceRect = vc.popoverPresentationController!.sourceView!.bounds
      vc.project = self.project
      vc.filter = filter

    }
  }


  @IBAction func didPressPillButton(_ sender: AnyObject) {

    if let issue = self.issue {
      self.rootView.pages.jumpToIssueOnMap(issue)
    } else {
      Config.error()
    }

  }

  func filterUpdated(_ filter: Filter) {

    self.reloadAndUpdateTable()
  }


}

extension Nav: UISearchBarDelegate {
  
  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    searchBar.setShowsCancelButton(true, animated: true)
  }
  
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchBar.text = ""
    searchBar.resignFirstResponder()
    self.delay(0.1) {
      searchBar.setShowsCancelButton(false, animated: true)
    }
    
    self.filter.clearTextSearch()

  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    
    let text = searchText.strip()
    
    if text.characters.count == 0 {
      self.filter.clearTextSearch()

    } else {
      self.filter.addTextSearch(text)

    }
    
  }
  
}


extension Nav : UITableViewDelegate, UITableViewDataSource {
  
  func sectionIsAreas(_ section: Int) -> Bool {
    
    var sections = 0
    
    if self.fetchedResultsController.fetchedObjects!.count > 0 {
      sections += 1
    }
    
    if sections - 1 == section {
      return true
    }
    return false
    
  }
  
  func sectionIsForms(_ section: Int) -> Bool {
    
    var sections = 0
    
    if self.fetchedResultsController.fetchedObjects!.count > 0 {
      sections += 1
    }
    if forms.count > 0 {
      sections += 1
    }
    
    if sections - 1 == section {
      return true
    }
    return false
    
  }
  
 
  func numberOfSections(in tableView: UITableView) -> Int {
    
    var sections = 0
    if self.fetchedResultsController.fetchedObjects != nil{
        if self.fetchedResultsController.fetchedObjects!.count > 0 {
            sections += 1
        }
        if forms.count > 0 {
            sections += 1
        }
        
        
        return sections

    } else {
        print("No Fetched Objects")
    }
    
    
    
    if forms.count > 0 {
      sections += 1
    }
    
    
    return sections
    
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    if sectionIsAreas(section) {
        return fetchedResultsController.fetchedObjects!.count
      
    } else if sectionIsForms(section) {
      return forms.count
      
    }
    
    return 0
  }
  
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = self.tableView.dequeueReusableCell(withIdentifier: "NavTableViewCell") as! NavTableViewCell
    
    if sectionIsAreas(indexPath.section) {
        let area = self.fetchedResultsController.object(at: IndexPath(row: indexPath.row, section: 0)) as! Area
      cell.issuePredicate = self.filter.issuePredicate
      cell.area = area
    } else if sectionIsForms(indexPath.section) {
      let form = forms[indexPath.row]
      cell.form = form
    }
    
    return cell
    
  }
  
  func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    
    let cell = self.tableView.cellForRow(at: indexPath)
    
    if sectionIsAreas(indexPath.section) {
      if cell!.isSelected {
        self.tableView.deselectRow(at: indexPath, animated: true)
        self.activeArea = nil
        return nil
        
      }
      
    }
    return indexPath
    
  }
  
 
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    if sectionIsAreas(indexPath.section) {
      Manager.sharedInstance.startActivity(withMessage: NSLocalizedString("Loading...", comment: ""))
        let area = self.fetchedResultsController.object(at: IndexPath(row: indexPath.row, section: 0)) as! Area
      self.activeArea = area
      
    } else if sectionIsForms(indexPath.section) {
      
      if let area = activeArea {
        guard let index = fetchedResultsController.indexPath(forObject: area) else {
          Config.error()
          return
        }
        self.tableView.selectRow(at: index, animated: false, scrollPosition: .none)
      } else {
        
      }
      
      tableView.deselectRow(at: indexPath, animated: true)
      
      let form = self.forms[indexPath.row]
      self.activeForm = form
      
    }
    
  }
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    
    if sectionIsForms(section) {
      return NSLocalizedString("Forms", comment: "Forms")
    }
    
    if sectionIsAreas(section) {
      return NSLocalizedString("Areas", comment: "Areas")
    }
    
    return nil
    
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    
    let view = UIView(frame: CGRect(x: 0,y: 0, width: tableView.frame.width, height: 50))
    
    view.backgroundColor = UIColor.wspNeutral()
    
    let label = UILabel(frame: CGRect(x: 20, y: 5, width: 400, height: 20))
    label.font = UIFont.boldSystemFont(ofSize: 16)
    label.textColor = UIColor.white
    label.text = self.tableView(tableView, titleForHeaderInSection: section)
    
    view.addSubview(label)
    
    return view
    
    
  }
  
 func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    
    if self.fetchedResultsController.fetchedObjects!.count > 0 && forms.count > 0 {
      return 30.0
    } else {
      return 0
    }
    
  }
  
  
  func tagDidCancel() { }
  
  func tagDidSet(_ tagCollection: TagCollection) {
    
    issue?.tagsCollection = tagCollection
    issue?.setModified()
    rootView.updateActiveIssueLabel()
    manager.saveCurrentState(nil)

    if filter.isActive {
      filter.forceFilterUpdate()
    }

  }
  
  
  func tagDidChange(_ tagCollection: TagCollection?) { }

  func filterByTag(_ tagCollection: TagCollection) {
    filter.addTagTreeFilter(withTagCollection: tagCollection)
  }

  func filterByAggregate(_ filter: AggregateFilter) {
    self.filter.addAggregateFilter(filter)

  }

}

extension Nav: NSFetchedResultsControllerDelegate {
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    self.reloadAndUpdateTable()
  }
}

extension Nav: ActiveFilterTableViewControllerDelegate {

  func activeFilterRowsChangedTo(_ height: CGFloat) {
    var height = height

    if height < 0 {
      height = 0
    }

    if filterContainerHeight.constant != height {
      filterContainerHeight.constant = height
      
      self.view.setNeedsUpdateConstraints()
      UIView.animate(withDuration: 0.25, animations: {
        self.view.layoutIfNeeded()
      })

    }
  }

}


