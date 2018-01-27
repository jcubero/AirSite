//
//  FilterItem.swift
//  wsp
//
//  Created by Filip Wolanski on 2017-01-26.
//  Copyright © 2017 Ubriety. All rights reserved.
//

import Foundation
import GLCalendarView


class AggregateFilter {
  let levelTitle: String
  let itemTitle: NSAttributedString
  var uniqueTagIds: [String]

  var hash: Int

  init(levelTitle: String, itemTitle: NSAttributedString, uniqueTagIds: [String]) {
    self.levelTitle = levelTitle
    self.itemTitle = itemTitle
    self.uniqueTagIds = uniqueTagIds

    self.hash = uniqueTagIds.joined(separator: "").hash
  }
}

func == (lhs: AggregateFilter, rhs: AggregateFilter) -> Bool {
  return lhs.hash == rhs.hash
}


class FilterItem: NSObject {

  var commentFilterPredicate: NSPredicate!
  var tagFilterPredicate: NSPredicate!
  var issueFilterPredicate: NSPredicate!

  var title: NSAttributedString!
  var subtitle: NSAttributedString!
  var color: UIColor!
  var icon: String!

  var type: FilterItemType!

  var aggregateFilter: AggregateFilter?


  weak var container: Filter?

  init(parent: Filter) {
    container = parent
  }

  static func tagTreeFilter(_ parent: Filter, withTagCollection tagCollection: TagCollection) -> FilterItem {

    let filterItem = FilterItem(parent: parent)

    let tag = tagCollection.sorted.last!.tag!

    filterItem.color = tagCollection.color
    filterItem.title = tagCollection.topLevelTagAttributedTitle
    filterItem.subtitle = tagCollection.formattedChildAttributedTitle

    filterItem.tagFilterPredicate = NSPredicate(format: "SUBQUERY(issueTags, $i, $i.issue.issueTags.tag = %@).@count != 0", tag)
    filterItem.issueFilterPredicate = NSPredicate(format: "SUBQUERY(issueTags, $i, $i.tag = %@).@count != 0", tag)
    filterItem.commentFilterPredicate = NSPredicate(format: "SUBQUERY(issue.issueTags, $i, $i.tag = %@).@count != 0", tag)

    filterItem.type = .tagTree
    filterItem.icon = "\u{e922}"

    return filterItem

  }

  static func dateRangeFilter(_ parent: Filter, startDate: Date, endDate: Date ) -> FilterItem {

    let filterItem = FilterItem(parent: parent)

    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, y"

    if(startDate.timeIntervalSinceNow == endDate.timeIntervalSinceNow){
        filterItem.title = NSAttributedString(string: "\(formatter.string(from: startDate))")
    }
    else{
        filterItem.title = NSAttributedString(string: "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))")
    }

    filterItem.color = UIColor.wspNeutral()
    filterItem.subtitle = NSAttributedString(string: "")

    let adjustedEndDate = GLDateUtils.date(byAddingDays: 1, to: endDate)
    filterItem.commentFilterPredicate = NSPredicate(format: "issue.createdDate >= %@ and issue.createdDate < %@", startDate as CVarArg, adjustedEndDate! as CVarArg)
    filterItem.issueFilterPredicate = NSPredicate(format: "createdDate >= %@ and createdDate < %@", startDate as CVarArg, adjustedEndDate! as CVarArg)
    filterItem.tagFilterPredicate = NSPredicate(format: "SUBQUERY(issueTags, $i, $i.issue.createdDate >= %@ and $i.issue.createdDate < %@).@count != 0", startDate as CVarArg, adjustedEndDate! as CVarArg)

    filterItem.type = .dateRange
    filterItem.icon = "\u{e916}"

    return filterItem

  }

  static func aggregateFilter(_ parent: Filter, filter: AggregateFilter ) -> FilterItem {


    let filterItem = FilterItem(parent: parent)

    filterItem.color = UIColor.wspNeutral()
    filterItem.title = filter.itemTitle
    filterItem.subtitle = NSAttributedString(string: "Category: \(filter.levelTitle)")

    filterItem.tagFilterPredicate = NSPredicate(format: "SUBQUERY(issueTags, $i, $i.issue.issueTags.tag.localUnique in %@).@count != 0", filter.uniqueTagIds)
    filterItem.issueFilterPredicate = NSPredicate(format: "SUBQUERY(issueTags, $i, $i.tag.localUnique in %@).@count != 0", filter.uniqueTagIds)
    filterItem.commentFilterPredicate = NSPredicate(format: "SUBQUERY(issue.issueTags, $i, $i.tag.localUnique in %@).@count != 0", filter.uniqueTagIds)

    filterItem.type = .tagAggregate
    filterItem.icon = "\u{e152}"
    filterItem.aggregateFilter = filter

    return filterItem
  }


  func clear() {
    container?.removeItem(self)
  }

}
