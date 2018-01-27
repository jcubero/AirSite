//
//  DomainTableViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-10-13.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit
import PromiseKit

protocol DomainSelectionProtocol: class {
  func didSelectDomain(_ domain: Domain)
}

class DomainTableViewController: UITableViewController {

  weak var delegate: DomainSelectionProtocol?

    let refreshControl_ = UIRefreshControl()

  var domains: [Domain]? {
    return Manager.sharedInstance.user.downloadedDomains
  }

  
    override func viewDidLoad() {

        super.viewDidLoad()
        self.tableView.delegate = self;
        self.tableView.dataSource = self;

        refreshControl_.attributedTitle = NSAttributedString(string: NSLocalizedString("Pull to refresh", comment: ""))
        refreshControl_.addTarget(self, action: #selector((DomainTableViewController.refresh)), for:UIControlEvents.valueChanged)
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 1))
  }

    @objc func refresh(sender:AnyObject) {
        Manager.sharedInstance.user.updateDomains().always {
            
            self.refreshControl_.endRefreshing()
            self.tableView.reloadData()
        }
    }


  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return domains == nil ? 0 : domains!.count
  }
  
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "SelectDomainCell", for: indexPath)

    cell.backgroundColor = UIColor.clear
    cell.textLabel?.text = domains![indexPath.row].name

    return cell

  }
  

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    delegate?.didSelectDomain(domains![indexPath.row])


  }



}
