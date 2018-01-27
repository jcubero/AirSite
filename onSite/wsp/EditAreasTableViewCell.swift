//
//  EditAreasTableViewCell.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-04-13.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit

class EditAreasTableViewCell: UITableViewCell {

  @IBOutlet weak var areaLabel: UILabel!
  
  var area: Area! {
    didSet {
      areaLabel.text = area.title
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.layoutMargins = UIEdgeInsetsMake(0, self.areaLabel.frame.origin.x, 0, 0)
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
