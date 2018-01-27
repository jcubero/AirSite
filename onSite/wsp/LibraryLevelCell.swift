//
//  LibraryLevelCell.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-10-13.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit

class LibraryLevelCell: UITableViewCell {

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var tagImageView: UIImageView!
  @IBOutlet weak var tsConstraint: NSLayoutConstraint!
  @IBOutlet weak var strokeImageView: UIImageView!

  var tagCollection: TagCollection!
  var imageCache: IssueImageCache!
  var level: Level!

  func render() {
    
    self.titleLabel.text = self.level.nonEmptyTitle

    self.tsConstraint.constant = 48
    self.updateIssueImageView()
    self.setNeedsUpdateConstraints()
    
  }
  
  func updateIssueImageView() {
    
    var shape: String?
    var color: UIColor?
    
    self.tagImageView.isHidden = false
    self.strokeImageView.isHidden = false
    
    if level.hasShapes && level.hasColors {
      shape = tagCollection.shape
      color = tagCollection.color

    } else if level.hasShapes {
      
      shape = tagCollection.shape
      color = Tag.NoColorColor
      
    } else if level.hasColors {
      shape = Tag.NoShapeImage
      color = tagCollection.color
    }
    
    if let c = color, let s = shape {
      self.tagImageView.image = self.imageCache.getImageWithShape(s, color: c, ofSize: self.tagImageView.frame.size.width)
      let strokeColor: UIColor = UIColor.white
      self.strokeImageView.image = self.imageCache.getImageWithShape(s, color: strokeColor, ofSize: self.strokeImageView.frame.size.width)
      
    } else {
      self.tagImageView.isHidden = true
//      self.tsConstraint.constant = 14
      self.strokeImageView.isHidden = true
    }

    
  }


}
