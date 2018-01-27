//
//  ActiveFilterTableViewCell.swift
//  wsp
//
//  Created by Filip Wolanski on 2017-01-24.
//  Copyright © 2017 Ubriety. All rights reserved.
//

import UIKit

class ActiveFilterTableViewCell: UITableViewCell {

  var item: FilterItem! {
    didSet {
      render()
    }
  }


  @IBOutlet weak var filterTitle: UILabel!
  @IBOutlet weak var filterSubtitle: UILabel!
  @IBOutlet weak var filterTopMargin: NSLayoutConstraint!

  @IBOutlet weak var labelContainer: UIView!
  @IBOutlet weak var filterTypeLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code

  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
//    super.setSelected(selected, animated: animated)

  }


  func render() {

    self.contentView.backgroundColor = item.color
    self.filterTitle.attributedText = item.title
    
    let childText = item.subtitle
    self.filterSubtitle.attributedText = childText
    if childText?.length != 0 {
      self.filterTopMargin.constant = 0
    } else {
      self.filterTopMargin.constant = 12
    }

    self.filterTypeLabel.text = item.icon

  }

  @IBAction func clearButtonPressed(_ sender: AnyObject) {
    item.clear()
  }

  
}
