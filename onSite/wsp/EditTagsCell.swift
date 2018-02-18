//
//  EditTagsCell.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-07-30.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

enum TouchSide {
  case left, right
}

protocol EditTagsCellDelegate: class {
  func filterByTag(_ tag: Tag)
}

class EditTagsCell: UITableViewCell {

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var tagImageView: UIImageView!
  @IBOutlet weak var titleLabelConstraint: NSLayoutConstraint!
  @IBOutlet weak var checkmarkLabel: UILabel!
  @IBOutlet weak var tsConstraint: NSLayoutConstraint!
  
  @IBOutlet weak var filterButton: UIButton!
  var touchSide: TouchSide = .left
  var filterMode: Bool = false
  weak var delegate: EditTagsCellDelegate?
 
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
    // Initialization code
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let touch = touches.first {
      if touch.location(in: self).x < (0.5 * self.frame.size.width) {
        self.touchSide = .left
      } else {
        self.touchSide = .right
      }
    }
    super.touchesBegan(touches, with: event)
  }
  
  @IBAction func filterButtonPressed(_ sender: AnyObject) {
    
    self.delegate?.filterByTag(self.item)
    
  }
  
  func render() {
    
    self.filterButton.isHidden = !self.filterMode
    
    self.titleLabel.attributedText = self.item.nonEmptyColoredAttributedTitle
    
    self.tsConstraint.constant = 48
    let diff = titleLabel.frame.origin.x - self.tsConstraint.constant
    
    self.tagImageView.isHidden = false
    if item.level.hasShapes && item.level.hasColors {
      self.tagImageView.image = UIImage(named: self.item.shapeValue())
      self.tagImageView.fillWithColor(self.item.colorValue())
    } else if item.level.hasShapes {
      self.tagImageView.image = UIImage(named: self.item.shapeValue())
      self.tagImageView.fillWithColor(Tag.NoColorColor)
      
    } else if item.level.hasColors {
      self.tagImageView.image = UIImage(named: Tag.NoShapeImage)
      self.tagImageView.fillWithColor(self.item.colorValue())
      
    } else {
      self.tagImageView.isHidden = true
      self.tsConstraint.constant = 14
    }
    
    // self.layoutMargins = UIEdgeInsetsMake(0, self.tsConstraint.constant + diff, 0, 0)
    
  }
  
  func setAsCurrent() {
    self.checkmarkLabel.isHidden = false
    self.titleLabelConstraint.constant += 26
    self.titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
  }
  
  
  
}
