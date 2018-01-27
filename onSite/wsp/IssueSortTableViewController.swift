//
//  IssueSortTableViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-03-10.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit

class IssueSortTableViewController: UITableViewController {
  
  
  var levels: [Level]?
  var project: Project!
  
  weak var issuesVC: Issues!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.levels = Level.mr_find(byAttribute: "project", withValue: self.project, andOrderBy: "level", ascending: true) as? [Level]
    
    var size = self.preferredContentSize
    size.height = fmin(CGFloat(self.levels!.count + 1) * 44 + 2 * 22 + 20, 500)
    
    self.preferredContentSize = size
    
  }
  
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    
    return 2
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section == 0 {
      return "Issue Attributes"
    } else {
      return "Levels"
    }
    
  }
  
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    if section == 0 {
      return 1
    } else if section == 1 {
      if let l = self.levels {
        return l.count
      }
      return 0
    }
    return 0
  
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "IssueSortCell", for: indexPath)
    
    
    if indexPath.section == 0 {
      cell.textLabel!.text = "Issue Number"
      if issuesVC.sortingLevel == nil {
        cell.accessoryType = .checkmark
      } else {
        cell.accessoryType = .none
      }
    } else {
      guard let levels = self.levels else {
        return cell
      }
      let level = levels[indexPath.row]
      cell.textLabel!.text = level.title
      if issuesVC.sortingLevel == level {
        cell.accessoryType = .checkmark
      } else {
        cell.accessoryType = .none
      }
    }
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    if indexPath.section == 0 {
      self.issuesVC.sortingLevel = nil
    } else {
      guard let levels = self.levels else {
        return
      }
      let level = levels[indexPath.row]
      self.issuesVC.sortingLevel = level
    }
    
    self.dismiss(animated: true, completion: nil)
  }
  
  
}
