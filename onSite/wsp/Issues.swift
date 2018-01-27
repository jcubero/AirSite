//
//  Issues.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-07-30.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit
import CoreData

class Issues: Page, NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource {
  
  var frc: NSFetchedResultsController<NSFetchRequestResult>!
  weak var pages: PagesViewController!
  var filter: Filter {
    get {
      return self.pages.project.filter
    }
  }
  
  var issue: Issue? {
    get {
      return self.pages.issue
    } set {
      self.pages.issue = newValue
    }
  }
  
  var area: Area? {
    get {
      return self.pages.area
    }
  }
  
  var sortingLevel: Level? {
    didSet {
      self.sortFetchedResults()
    }
  }
  
  var sections: [Tag]?
  var issueForSection: [Tag: [Issue]]?
  var results: [Issue]?
  
  let cacheName = "IssueListViewCache"
  
  @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
  @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var tableHeaderView: UIView!
  @IBOutlet weak var sortButton: UIButton!
  @IBOutlet weak var sortDescription: UILabel!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.pos = 1
    
    tableView.panGestureRecognizer.maximumNumberOfTouches = 1
    tableHeaderView.backgroundColor = UIColor.wspNeutral()
    
    let bottomBorder = CALayer()
    bottomBorder.frame = CGRect(x: 0.0, y: 43.5, width: 1024, height: 0.5)
    bottomBorder.backgroundColor = UIColor.black.cgColor
    tableHeaderView.layer.addSublayer(bottomBorder)
    
    
    self.fetch()
    self.updateSelectedIssue()
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    
  }
  
  override var preferredStatusBarStyle : UIStatusBarStyle {
    return UIStatusBarStyle.lightContent
    
  }
  
  func didDismissSearchController(_ searchController: UISearchController) {
    
    self.pages.searchBarDidHide()
    
  }
  
  func fetch() {
    let req = NSFetchRequest<NSFetchRequestResult>(entityName: "Issue")
    
    let primarySortDescriptor = NSSortDescriptor(key: "createdDate", ascending: true)
    
    var pred = NSPredicate(format: "area.project = %@", self.pages.project)
    
    if let area = self.area {
      let areaPred = NSPredicate(format: "area = %@", area)
      pred = NSCompoundPredicate(andPredicateWithSubpredicates: [pred, areaPred])
    }

    if let filter = self.filter.issuePredicate {
      let cp = NSCompoundPredicate(andPredicateWithSubpredicates: [filter, pred])
      req.predicate = cp
    } else {
      req.predicate = pred
    }
    
    req.sortDescriptors = [primarySortDescriptor]
    
    
    NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: self.cacheName)
    self.frc = NSFetchedResultsController( fetchRequest: req,
      managedObjectContext: NSManagedObjectContext.mr_default(),
      sectionNameKeyPath: nil,
      cacheName: self.cacheName)
    frc.delegate = self
    do {
      try frc.performFetch()
      self.sortFetchedResults()
    } catch {
      Config.error("There was an error fetching!")
    }
  }
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    self.sortFetchedResults()
  }
  
  
  func sortFetchedResults() {
    
    let results: [Issue] = self.frc.fetchedObjects as! [Issue]
    
    if let level =  self.sortingLevel {
      
      sortDescription.text = sortingLevel!.title
      
      self.results = nil
      let tags = Tag.mr_find(byAttribute: "level", withValue: level, andOrderBy: "title", ascending: true) as! [Tag]
      
      var uniqued: [Tag] = []
      for tag in tags {
        if let _ = uniqued.index(where: { $0.title == tag.title }) {
          continue
        } else {
          uniqued.append(tag)
        }
      }
      
      self.sections = uniqued
      self.issueForSection = [:]
      
      for result in results {
        
        let predicate = NSPredicate(format: "tag.level = %@ and issue = %@", level, result)
        if let issueTag = IssueTag.mr_findFirst(with: predicate) {
          if let ind = self.sections!.index(where: { $0.title == issueTag.tag!.title }) {
            let tag = self.sections![ind]
            
            if self.issueForSection![tag] != nil {
              self.issueForSection![tag]!.append(result)
            } else {
              self.issueForSection![tag] = [result]
            }
          }
        }
      }
      
      self.sections = Array(self.issueForSection!.keys).sorted { $0.title?.localizedCaseInsensitiveCompare($1.title!) == .orderedAscending }
      
      
    } else {
      
      sortDescription.text = "Issue Number"

      self.results = results.sorted(by: { (i1, i2) -> Bool in
        guard let num1 = i1.issueNumber else {
          return false
        }
        guard let num2 = i2.issueNumber else {
          return false
        }
        guard let n1 = Int(num1) else {
          return false
        }
        guard let n2 = Int(num2) else {
          return false
        }

        return n1 < n2
      })

      self.sections = nil
      self.issueForSection = nil
    }
    
    
    if self.tableView != nil {
      self.tableView.reloadData()
      self.updateSelectedIssue()
    }
    
  }
  
  func issueAtIndexPath(_ indexPath: IndexPath) -> Issue? {
    
    if let r = self.results {
      if indexPath.section > 0 {
        Config.error("Oh oh")
        return nil
      } else {
        return r[indexPath.row]
      }
    } else if let sec = self.sections, let issues = self.issueForSection {
      
      let tag = sec[indexPath.section]
      return issues[tag]![indexPath.row]
      
    }
    
    return nil
    
  }
  
  func indexPathForIssue(_ issue: Issue) -> IndexPath? {
    
    if let r = self.results {
      
      if let i = r.index(of: issue) {
        return IndexPath(row: i, section: 0)
      } else {
        return nil
      }
      
    } else if let sec = self.sections, let issues = self.issueForSection {
      
      for tag in issues.keys {
        
        let i = issues[tag]!
        
        if let issueIndex = i.index(where: {$0 == issue}), let tagIndex = sec.index(where: {$0 == tag}) {
          return IndexPath(row: issueIndex, section: tagIndex)
        } else {
          return nil
        }
      }
    }
    
    return nil
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if self.results != nil {
      if section == 0 {
        return self.results!.count
      } else {
        return 0
      }
    } else if let sec = self.sections, let issues = self.issueForSection {
      
      if section < sec.count {
        let tag = sec[section]
        return issues[tag]!.count
      }
      return 0
    }
    return 0
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    
    if self.results != nil {
      return 1
    } else if let sec = self.sections {
      return sec.count
    } else {
      return 0
    }
  }
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if let sec = self.sections {
      return sec[section].nonEmptyTitle
    }
    
    return nil
    
    
  }
  
  func updateSelectedIssue() {
    
    if let tableView = self.tableView {
      if let issue = self.issue, let indexPath = self.indexPathForIssue(issue) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
          if selectedIndexPath == indexPath {
            return
          }
        }
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.none)
      } else if issue == nil {
        if let indexPath = tableView.indexPathForSelectedRow {
          tableView.deselectRow(at: indexPath, animated: true)
        }
      }
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    var cell = self.tableView.dequeueReusableCell(withIdentifier: "IssuesTableViewCell") as? IssuesTableViewCell
    if cell == nil {
      cell = IssuesTableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "IssuesTableViewCell")
    }
    cell?.issue = self.issueAtIndexPath(indexPath)
    cell?.delegate = self
    return cell!
  }
  
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    let issue = self.issueAtIndexPath(indexPath)

    if self.issue == issue {
      self.issue = nil
    } else {
      self.issue = issue
    }

  }

  fileprivate var issueTagHeights: [CGFloat: [Int: CGFloat]]  = [:]
  fileprivate var issueTitleHeight: [CGFloat: CGFloat] = [:]
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

    guard let issue = self.issueAtIndexPath(indexPath) else {
      return 0
    }

    let frameWidth: CGFloat = self.view.frame.width - 70

    var height: CGFloat =
      cacheTitleHeightForWidth(frameWidth, issue: issue)
      + cacheTagHeightForWith(frameWidth, issue: issue)

    height += 20
    
    let minHeight: CGFloat = 70
    return height > minHeight ? height : minHeight
    
  }

  func cacheTitleHeightForWidth(_ frameWidth: CGFloat, issue: Issue) -> CGFloat {

    if issueTitleHeight[frameWidth] == nil {
      let title = issue.topLevelTagTitle
      var height: CGFloat = 0
      if title != "" {
        let titleHeight = UIFont.systemFont(ofSize: 17).sizeOfString(title, constrainedToWidth: frameWidth).height
        height += titleHeight
      }
      issueTitleHeight[frameWidth] = height
    }

    return issueTitleHeight[frameWidth]!

  }

  func cacheTagHeightForWith(_ frameWidth: CGFloat, issue: Issue) -> CGFloat {

    let hash = issue.issueTagHash

    if issueTagHeights[frameWidth] == nil {
      issueTagHeights[frameWidth] = [:]
    }
    if issueTagHeights[frameWidth]![hash] == nil {
      let subtitle = issue.formattedChildTitle
      var height: CGFloat = 0
      if subtitle != "" {
        let subTitleHeight = UIFont.systemFont(ofSize: 14).sizeOfString(subtitle, constrainedToWidth: frameWidth).height
        height += subTitleHeight
      }
      issueTagHeights[frameWidth]![hash] = height
    }

    return issueTagHeights[frameWidth]![hash]!

  }

  
  @IBAction func sortButtonPressed(_ sender: UIButton) {
    
    let vc = self.storyboard!.instantiateViewController(withIdentifier: "IssueSortTableViewController") as! IssueSortTableViewController
    vc.project = self.pages.project
    vc.issuesVC = self
    
    let frame = self.sortButton.frame
    let translated = self.view.convert(frame, to: self.view)
    
    let popover = UIPopoverController(contentViewController: vc)
    popover.present(from: translated, in: self.view, permittedArrowDirections: .any, animated: true)
    
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
    
    if self.results == nil {
      return 30.0
    } else {
      return 0
    }
    
  }
  
  
}

extension Issues :  IssueTableViewCellDelegate {
  
  func tappedOnTagForIssue(_ issue: Issue) {
    self.pages.jumpToIssueOnMap(issue)
  }
  
  
}
