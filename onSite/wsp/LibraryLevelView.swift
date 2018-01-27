//
//  LibraryLevelView.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-10-13.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit


class LibraryLevelView: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var myTitle: UILabel!


  var imageCache: IssueImageCache!
  var tagCollection: TagCollection!

  var height: CGFloat = 0
  var topMargin: CGFloat = 44

  var levels: [Level]!
  var project: Project!

  weak var delegate: LibraryLevelDelegate?

  var mode: LibraryPopoverMode = .select


  override func viewDidLoad() {
    super.viewDidLoad()

    if mode == .filterTag {
      let predicate = NSPredicate(format: "project = %@ and subquery(tags, $t, any $t.issueTags != NULL).@count > 0", project)

      self.levels = Level.mr_findAllSorted(by: "level", ascending: true, with: predicate) as! [Level]

    } else {
      self.levels = tagCollection.allUsedLevels
    }


    self.myTitle.text = NSLocalizedString("Levels", comment: "")


    var size = self.preferredContentSize
    size.height = CGFloat(self.levels!.count) * 44 + topMargin
    
    self.preferredContentSize = size
    self.presentingViewController!.presentedViewController!.preferredContentSize = size

    self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 1))
    
  }
  


  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.levels!.count
  }
  
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let level = self.levels[indexPath.row]

    let cell = tableView.dequeueReusableCell(withIdentifier: "SelectLevelsCell", for: indexPath) as! LibraryLevelCell

    cell.imageCache = imageCache
    cell.tagCollection = tagCollection
    cell.level = level

    cell.render()
    cell.backgroundColor = UIColor.clear

    return cell

  }
  

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    let level = self.levels[indexPath.row]
    delegate?.didSelectLevel(level)

  }
  
  
}

protocol LibraryLevelDelegate: class {


  func didSelectLevel(_ level: Level)

}
