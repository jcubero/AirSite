//
//  IssuesTableViewCell.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-08-11.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

protocol IssueTableViewCellDelegate: class {
  func tappedOnTagForIssue(_ issue: Issue)
}

class IssuesTableViewCell: UITableViewCell {
  
  @IBOutlet weak var tagImageView: UIImageView!
  @IBOutlet weak var issueTitle: UILabel!
  @IBOutlet weak var tagTitle: UILabel!
  @IBOutlet weak var comment: UILabel!
  @IBOutlet weak var info: UIView!
  @IBOutlet weak var InfoHeight: NSLayoutConstraint!
  
  var issue: Issue! {
    didSet {
      
      self.issueTitle.text = self.issue.issueTag
      
      
      let shape = self.issue.shape
      let color = self.issue.color
      self.tagImageView.image = UIImage(named: shape)
      self.tagImageView.fillWithColor(color)
      self.tagTitle.text = self.issue.topLevelTagTitle
      self.comment.text = self.issue.formattedChildTitle
      
      self.InfoHeight.constant = self.tagTitle.frame.height
      if self.comment.text != "" {
        self.InfoHeight.constant += self.comment.frame.height
      }
      self.needsUpdateConstraints()
      
    }
    
  }
  
  weak var delegate: IssueTableViewCellDelegate?
  
  override func awakeFromNib() {
    
    super.awakeFromNib()
    
    let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(IssuesTableViewCell.imageTapped(_:)))
    self.tagImageView.isUserInteractionEnabled = true
    self.tagImageView.addGestureRecognizer(tapGestureRecognizer)
    
  }
  
  
  @objc func imageTapped(_ sender: AnyObject?) {
    
    if self.issue != nil {
      self.delegate?.tappedOnTagForIssue(self.issue)
      
    }
    
  }
  
}
