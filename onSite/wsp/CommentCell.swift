//
//  CommentCell.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-08-10.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

protocol CommentCellDelegate: class {
  func didPress(_ comment: Comment)
}

class CommentCell: UITableViewCell {
  
  @IBOutlet weak var commentText: UILabel!
  @IBOutlet weak var commentDate: UILabel!
  @IBOutlet weak var commentUser: UILabel!
  @IBOutlet weak var commentImage: UIImageView!
  
  weak var delegate: CommentCellDelegate?
  
  var comment: Comment! {
    didSet {
      self.commentText.text = comment.title
      //    cell!.commentDate.text = comment.dateAdded as! String
      
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
      dateFormatter.dateStyle = DateFormatter.Style.medium
      dateFormatter.timeStyle = DateFormatter.Style.short
      if let date = comment.createdDate {
        let d = dateFormatter.string(from: date as Date)
        self.commentDate.text = d
        
      }
      
      let tapRec = UITapGestureRecognizer(target: self, action:#selector(CommentCell.handleTap(_:)))
      tapRec.delegate = self
      self.addGestureRecognizer(tapRec)
      
      self.commentUser.text = comment.user?.username!
      
      if let _ = comment.image, let imagePath = comment.imagePath {
        self.commentImage.hnk_setImageFromFile(imagePath.path, placeholder: nil, format: nil, failure: nil, success: { image in
          self.commentImage.image = image
          self.commentImage.isHidden = false
          
        })
        
        
      } else {
        self.commentImage.isHidden = true
      }
    }
  }
  
  @objc func handleTap(_ rec: UITapGestureRecognizer) {
    self.delegate?.didPress(self.comment)
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  func calculateHeightForContent() -> CGFloat {
    
    return 500
  }
  

  
}
