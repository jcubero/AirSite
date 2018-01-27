//
//  Filter.swift
//  wsp
//
//  Created by Filip Wolanski on 2017-01-24.
//  Copyright © 2017 Ubriety. All rights reserved.
//

import Foundation

protocol ActiveFilterProtocol: class {
  func filterUpdated(_ filter: Filter)
}

enum FilterItemType {
  case tagTree, dateRange, tagAggregate
  static let allValues = [tagTree, dateRange, tagAggregate]
}

class Filter: NSObject {


  var commentPredicate: NSPredicate? {
    return combinePredicates(commentFilterPredicate, second: commentSearch)
  }
  var issuePredicate: NSPredicate? {
    return combinePredicates(issueFilterPredicate, second: issueSearch)

  }
  var tagPredicate: NSPredicate? {
    return tagFilterPredicate
  }

  var delegates = MulticastDelegate<ActiveFilterProtocol>()

  var numberOfFilters: Int { return filterItems.count }
  var isActive: Bool { return issuePredicate != nil }

  internal enum FilterDirection {
    case pop, push
  }

  var newFilterItemIndex: Int?
  var newFilterDirection: FilterDirection?

  fileprivate var commentFilterPredicate: NSPredicate? {
    return processfilterPredicates { $0.commentFilterPredicate! }
  }

  fileprivate var tagFilterPredicate: NSPredicate? {
    return processfilterPredicates { $0.tagFilterPredicate! }
  }

  fileprivate var issueFilterPredicate: NSPredicate? {
    return processfilterPredicates { $0.issueFilterPredicate! }
  }

  fileprivate var issueSearch: NSPredicate?
  fileprivate var commentSearch: NSPredicate?

  fileprivate var filterItems: [FilterItem] = []

  func addTextSearch(_ text: String) {

    commentSearch = NSPredicate(format:"any issue.issueTags.tag.title CONTAINS[cd] %@ or any issue.issueTags.input CONTAINS[cd] %@", text, text)
    issueSearch = NSPredicate(format: "any issueTags.tag.title CONTAINS[cd] %@ or any issueTags.input CONTAINS[cd] %@", text, text)

    filterUpdated()

  }

  func clearTextSearch() {
    issueSearch = nil
    commentSearch = nil
    filterUpdated()

  }


  func addTagTreeFilter(withTagCollection tagCollection: TagCollection) {
    let item = FilterItem.tagTreeFilter(self, withTagCollection: tagCollection)

    var targetInsertion = 0
    for i in filterItems {
      if i.type == .tagTree {
        targetInsertion += 1
      }
    }

    newFilterItemIndex = targetInsertion
    newFilterDirection = .push

    filterItems.insert(item, at: targetInsertion)
    filterUpdated()

  }

  func addDateRangeFilter(_ startDate: Date, endDate: Date) {

    let item = FilterItem.dateRangeFilter(self, startDate: startDate, endDate: endDate)

    var targetInsertion = 0
    for i in filterItems {
      if i.type == .tagTree || i.type == .dateRange {
        targetInsertion += 1
      }
    }

    newFilterDirection = .push
    newFilterItemIndex = targetInsertion

    filterItems.insert(item, at: targetInsertion)
    filterUpdated()

  }

  func addAggregateFilter(_ filter: AggregateFilter) {

    let item = FilterItem.aggregateFilter(self, filter: filter)

    newFilterDirection = .push
    newFilterItemIndex = filterItems.count

    filterItems.append(item)
    filterUpdated()

  }

  func hasSimilarAggregateFilter(_ filter: AggregateFilter) -> FilterItem? {

    let items = filterItems.filter({ item -> Bool in
      if let ag = item.aggregateFilter {
        return ag == filter
      } else {
        return false
      }
    })

    if items.count > 0 {
      return items[0]
    } else {
      return nil
    }

  }



  func itemAtIndex(_ index: Int) -> FilterItem {
    return filterItems[index]
  }

  func removeItem(_ item: FilterItem) {

    newFilterItemIndex = filterItems.index(of: item)
    newFilterDirection = .pop

    filterItems = filterItems.filter({ (candidate) -> Bool in
      return candidate != item
    })

    filterUpdated()
  }

  func forceFilterUpdate() {

    filterUpdated()

  }

  internal func filterUpdated() {

    Manager.sharedInstance.startActivity(withMessage: NSLocalizedString("Loading...", comment: ""))

    DispatchQueue.main.async {
      self.delegates.invokeDelegates { [weak self] (delegate) in
        if let s = self {
          delegate.filterUpdated(s)
        }
      }
      Manager.sharedInstance.stopActivity()
    }

  }

  internal func combinePredicates(_ first: NSPredicate?, second: NSPredicate?) -> NSPredicate? {

    if first == nil && second == nil {
      return nil
    } else if first != nil && second == nil {
      return first
    } else if first == nil && second != nil {
      return second
    } else {
      return NSCompoundPredicate(andPredicateWithSubpredicates: [first!, second!])
    }
  }

  internal func processfilterPredicates(_ mapItem: ((FilterItem) -> NSPredicate)) -> NSPredicate? {

    var andPredicates: [NSPredicate] = []

    for item in FilterItemType.allValues {
      let orPredicates = filterItems
        .filter { $0.type == item }
        .map(mapItem)
      if orPredicates.count > 0 {
        andPredicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: orPredicates))
      }
    }

    if andPredicates.count > 0 {
      return NSCompoundPredicate(andPredicateWithSubpredicates: andPredicates)
    } else {
      return nil
    }
  }

}





