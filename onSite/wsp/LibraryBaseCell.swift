//
//  LibraryBaseCell.swift
//  wsp
//
//  Created by Filip Wolanski on 2017-01-26.
//  Copyright © 2017 Ubriety. All rights reserved.
//

import UIKit

protocol LibraryInputViewCellDelegate: class {
  func tagInputSet(_ tag: Tag, input: String)
  func filterByTag(_ tag: Tag)
}

class LibraryBaseCell: UITableViewCell {

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var tagImageView: UIImageView!
  @IBOutlet weak var checkmarkLabel: UILabel!
  @IBOutlet weak var tsConstraint: NSLayoutConstraint!
  @IBOutlet weak var checkmarkContraint: NSLayoutConstraint!

  @IBOutlet weak var strokeImageView: UIImageView!
  @IBOutlet weak var filterButton: UIButton!

  weak var delegate: LibraryInputViewCellDelegate?

  var touchSide: TouchSide = .left
  var mode: LibraryPopoverMode = .select
  var imageCache: IssueImageCache!
 
  var item: Tag! {
    didSet {
      self.render()
    }
  }
  
  var available: Bool = true {
    didSet {
      self.render()
    }
  }


  override func awakeFromNib() {
    super.awakeFromNib()

  }
  

  @IBAction func filterButtonPressed(_ sender: AnyObject) {
    
    self.delegate?.filterByTag(self.item)
    
  }
  
  func render() {

    self.filterButton.isHidden = (mode != .filterTree && mode != .filterTag)
    
    self.titleLabel.text = self.item.nonEmptyTitle
    
    if item.type == .Text {
      self.titleLabel.textColor = UIColor.black
    } else {
      self.titleLabel.textColor = UIColor.gray
    }
    
    self.tsConstraint.constant = 48
    self.checkmarkContraint.constant = 48
    self.checkmarkLabel.isHidden = true
    
    self.updateIssueImageView()

  }


  func showAccessory(_ show: Bool) {

    if show {
      self.accessoryType = .disclosureIndicator
    } else {
      self.accessoryType = .none

    }

  }

  func updateIssueImageView() {
    
    var shape: String?
    var color: UIColor?
    
    self.tagImageView.isHidden = false
    
    if item.level.hasShapes && item.level.hasColors {
      shape = self.item.shapeValue()
      color = self.item.colorValue()
     
    } else if item.level.hasShapes {
      
      shape = self.item.shapeValue()
      color = Tag.NoColorColor
      
    } else if item.level.hasColors {
      shape = Tag.NoShapeImage
      color = self.item.colorValue()

    }
    
    if let c = color, let s = shape {
      self.tagImageView.image = self.imageCache.getImageWithShape(s, color: c, ofSize: self.tagImageView.frame.size.width)
      let strokeColor: UIColor = UIColor.white
      self.strokeImageView.image = self.imageCache.getImageWithShape(s, color: strokeColor, ofSize: self.strokeImageView.frame.size.width)
      
    } else {
      self.tagImageView.isHidden = true
      self.tsConstraint.constant = 14
      self.checkmarkContraint.constant = 14
    }

  }
  
  
  func setAsCurrent() {
    self.checkmarkLabel.isHidden = false
    self.tsConstraint.constant += 26
    self.titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
  }
  
}
