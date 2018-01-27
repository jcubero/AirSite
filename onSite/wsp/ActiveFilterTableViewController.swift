//
//  ActiveFilterTableViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2017-01-24.
//  Copyright © 2017 Ubriety. All rights reserved.
//

import UIKit

protocol ActiveFilterTableViewControllerDelegate: class {

  func activeFilterRowsChangedTo(_ height: CGFloat)

}

class ActiveFilterTableViewController: UITableViewController, ActiveFilterProtocol {

  weak var filter: Filter!

  weak var delegate: ActiveFilterTableViewControllerDelegate?

  let rowHeight: CGFloat = 54.0

  override func viewDidLoad() {
    super.viewDidLoad()
    
  }

  func filterUpdated(_ filter: Filter) {


    var targetHeight = filter.numberOfFilters
    if filter.numberOfFilters > 5 {
      targetHeight = 5
      self.tableView.isScrollEnabled = true
      if let direction = filter.newFilterDirection, let index = filter.newFilterItemIndex {
        let indexPath = IndexPath(row: index, section: 0)
        if direction == .push {
          self.tableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.top)
        } else {
          self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.bottom)
        }
        self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
      } else {
        Config.error()
      }
    } else {
      self.tableView.isScrollEnabled = false
      self.tableView.reloadData()
    }

    self.delegate?.activeFilterRowsChangedTo((CGFloat(targetHeight) * rowHeight) - 1)

  }

  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return filter.numberOfFilters
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

    return rowHeight

  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ActiveFilterTableViewCell", for: indexPath) as! ActiveFilterTableViewCell

    cell.item = filter.itemAtIndex(indexPath.row)

    cell.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: cell.frame.height)
    cell.setNeedsUpdateConstraints()

    return cell
  }


}
