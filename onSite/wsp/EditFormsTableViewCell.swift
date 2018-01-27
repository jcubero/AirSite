//
//  EditFormsTableViewCell.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-05-26.
//  Copyright © 2016 Ubriety. All rights reserved.
//
import UIKit

class EditFormsTableViewCell: UITableViewCell {

  @IBOutlet weak var formLabel: UILabel!
  
  var form: Form! {
    didSet {
      formLabel.text = form.title
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.layoutMargins = UIEdgeInsetsMake(0, self.formLabel.frame.origin.x, 0, 0)
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  override func addSubview(_ view: UIView) {
    super.addSubview(view)
    if view.isKind(of: NSClassFromString("UITableViewCellEditControl")!) {
      view.isHidden = true
    }
  }

}
