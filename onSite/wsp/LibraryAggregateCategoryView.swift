//
//  LibraryAggregateCategoryView.swift
//  wsp
//
//  Created by Filip Wolanski on 2017-01-26.
//  Copyright © 2017 Ubriety. All rights reserved.
//


import UIKit
import CoreData



protocol LibraryAggregateDelegate: class {
  func didFilterByString(_ filter: AggregateFilter)
  func didCancel()
}


class LibraryAggregateCategoryView: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource {
  
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var myTitle: UILabel!
  @IBOutlet weak var titleImage: UIImageView!
  @IBOutlet weak var titleConstraint: NSLayoutConstraint!

  var imageCache: IssueImageCache!
  
  var height: CGFloat = 0
  var topMargin: CGFloat = 44

  var level: Level!
  var tags: [AggregateFilter] = []
  var filter: Filter!

  let tagRegularHeight:CGFloat = 44

  var frc: NSFetchedResultsController<NSFetchRequestResult>!
  weak var delegate: LibraryAggregateDelegate?
  
  let tagLibraryCacheName = "AggregateTagLibraryCache"
  
  override func viewDidLoad() {
    super.viewDidLoad()

    renderUpperBar()
    fetchTags()
    adjustHeightToMatchNumberOfTags()

    self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 1))
    
  }

  func renderUpperBar() {

    let currentLevel = level
    self.myTitle.text = currentLevel?.title

    self.titleImage.isHidden = true
    self.titleConstraint.constant = 8

  }

  func fetchTags() {

    let predicate = NSPredicate(format: "level = %@ and issueTags.@count > 0", level)
    let fetchedObjs = Tag.mr_findAllSorted(by: "title", ascending: true, with: predicate) as! [Tag]

    tags = []
    for tag in fetchedObjs {

      let res = tags.filter({ $0.itemTitle == tag.nonEmptyAttributedTitle })

      if res.count == 1 {
        let ao = res[0]
        ao.uniqueTagIds.append(tag.localId)
      } else if res.count == 0 {
        let ao = AggregateFilter(levelTitle: level.nonEmptyTitle, itemTitle: tag.nonEmptyAttributedTitle, uniqueTagIds: [tag.localId])
        tags.append(ao)
      } else {
        Config.error("how is res larger than 1?")
      }
    }

  }

  func adjustHeightToMatchNumberOfTags() {

    // adjust height to match number of tags
//    let adjustFactor: CGFloat = tags.count < 2 ? 2 : CGFloat(tags.count)
    let adjustFactor: CGFloat =  CGFloat(tags.count)

    self.height = adjustFactor * tagRegularHeight
    self.height += self.topMargin

    var contentSize = self.preferredContentSize
    contentSize.height = self.height
    self.presentingViewController!.presentedViewController!.preferredContentSize = contentSize

  }
  

  @IBAction func cancel(_ sender: AnyObject) {
    self.delegate?.didCancel()
  }
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    self.tableView.reloadData()
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.tags.count
  }
  
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let tag = self.tags[indexPath.row]

    let cell = tableView.dequeueReusableCell(withIdentifier: "SelectAggregateTagsCell", for: indexPath) as! LibraryAggregateTableViewCell
    configureAggregateCell(cell, withTag: tag)
    cell.filterItem = filter.hasSimilarAggregateFilter(tag)

    return cell
  }

  func configureAggregateCell(_ cell: LibraryAggregateTableViewCell, withTag tag: AggregateFilter) {

    cell.imageCache = self.imageCache
    cell.filter = tag
    cell.backgroundColor = UIColor.clear
    cell.showAccessory(false)
    cell.aggregateDelegate = self

  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
   
    return self.tagRegularHeight

  }
  
  func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {

    return false

  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    

  }


}

extension LibraryAggregateCategoryView: LibraryAggregateDelegate {

  func didFilterByString(_ filter: AggregateFilter) {
    tableView.reloadData()
    delegate?.didFilterByString(filter)
  }

  func didCancel() {
    tableView.reloadData()
  }
  
}
