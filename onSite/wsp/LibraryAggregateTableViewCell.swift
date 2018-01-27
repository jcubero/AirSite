//
//  LibraryAggregateTableViewCell.swift
//  wsp
//
//  Created by Filip Wolanski on 2017-01-26.
//  Copyright © 2017 Ubriety. All rights reserved.
//

import UIKit


class LibraryAggregateTableViewCell: LibraryBaseCell {

  var filter: AggregateFilter! {
    didSet {
      self.render()
    }
  }

  var filterItem: FilterItem? {
    didSet {
      if filterItem == nil {
        self.filterButton.setTitleColor(UIColor.lightGray, for: UIControlState())
      } else {
        self.filterButton.setTitleColor(UIColor.wspLightBlue(), for: UIControlState())
      }

    }
  }

  weak var aggregateDelegate: LibraryAggregateDelegate?


  override func render() {

    self.filterButton.isHidden = false
    
    self.titleLabel.attributedText = filter.itemTitle
    
    self.tsConstraint.constant = 48
    self.checkmarkContraint.constant = 48
    self.checkmarkLabel.isHidden = true
    
    self.updateIssueImageView()

  }

  override func updateIssueImageView() {

    self.tagImageView.isHidden = true
    self.tsConstraint.constant = 14
    self.checkmarkContraint.constant = 14

  }

  override func filterButtonPressed(_ sender: AnyObject) {

    if let item = filterItem {
      item.clear()
      aggregateDelegate?.didCancel()
    } else {
      aggregateDelegate?.didFilterByString(filter)
    }

  }


}
