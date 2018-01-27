//
//  ProjectListPopoverViewController.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-09-10.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit
import PromiseKit
import SwiftyJSON
import CoreData


class ProjectListPopoverViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var activityView: UIView!
  @IBOutlet weak var errorView: UIView!
  @IBOutlet weak var emptyView: UIView!
  
  let manager = Manager.sharedInstance

  var data: [ProjectListItem] = []
  weak var delegate: ProjectListDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
    
    self.getProjects()
    
  }
  
  func getProjects() {
    
    self.tableView.isHidden = true
    self.errorView.isHidden = true
    self.emptyView.isHidden = true
    self.activityView.isHidden = false
    
    self.manager.listRemoteProjects({ projectList in

      if projectList.count == 0 {
        self.emptyView.isHidden = false
      } else {
        self.tableView.isHidden = false
      }

      self.activityView.isHidden = true
      
      self.data = projectList
      self.tableView.reloadData()
      
      }, error: { _ in
        self.tableView.isHidden = true
        self.activityView.isHidden = true
        self.errorView.isHidden = false
        
    })
    
    
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    return self.data.count
  }
  
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = self.tableView.dequeueReusableCell(withIdentifier: "ProjectListPopoverCell")!
    
    let data = self.data[indexPath.row]
      
    cell.textLabel?.text = data.title
    cell.backgroundColor = UIColor.clear
    
    if data.exists {
      cell.accessoryType = .checkmark
      cell.isUserInteractionEnabled = false
    }
    
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    let data = self.data[indexPath.row]
    
    Manager.sharedInstance.getProject(data.localID)
    
    Manager.sharedInstance.sendActionEvent("Download Project", label: data.title)
    
    
    self.navigationController?.dismiss(animated: true, completion: nil)
    
    
  }
  
  @IBAction func retryPressed(_ sender: AnyObject) {
    getProjects()
  
  }
  
}
