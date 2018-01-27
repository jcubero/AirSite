//
//  EditUsersTableViewCell.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-11-24.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import UIKit

class EditUsersTableViewCell: UITableViewCell {
  
  var touchSide: TouchSide = .left
  
  @IBOutlet weak var checkmarkImageView: UIImageView!
  @IBOutlet weak var usernameTextLabel: UILabel!
  @IBOutlet weak var userLabelTextLabel: UILabel!
  
  func setUser(_ user: User, project: Project) {
    
    usernameTextLabel.text = user.username
    let predicate = NSPredicate(format: "project = %@ and user = %@", project, user)
    
    if let userProject = ProjectUser.mr_findFirst(with: predicate) {
      if userProject.active.boolValue {
        checkmarkImageView.isHidden = false
      } else {
        checkmarkImageView.isHidden = true
      }
      userLabelTextLabel.text = userProject.label
    } else {
      checkmarkImageView.isHidden = true
      userLabelTextLabel.text = ""
    }
    
    if user.active {
      usernameTextLabel.textColor = UIColor.black
    } else {
      usernameTextLabel.textColor = UIColor.gray
    }
    
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.layoutMargins = UIEdgeInsetsMake(0, self.usernameTextLabel.frame.origin.x, 0, 0)
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
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
  
  
  
}
