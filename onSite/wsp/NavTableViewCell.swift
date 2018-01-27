//
//  NavTableViewCell.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-09-21.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit
import CoreData

class NavTableViewCell: UITableViewCell, NSFetchedResultsControllerDelegate {
  
  var area: Area? {
    didSet {
      if let area = self.area {
        self.titleLabel.text = area.title
        
        var predicate = NSPredicate(format: "area = %@", self.area!)
        
        if let search = self.issuePredicate {
          predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, search])
        }

        let issueCount = Issue.mr_countOfEntities(with: predicate)
        self.issueCount = Int(issueCount)

      }
    }
  }
  
  var form: Form? {
    didSet {
      if let form = self.form {
        
        self.detailLabel.text = ""
        self.titleLabel.text = form.title
        
      }
    }
  }
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var detailLabel: UILabel!
  
  var issueCount: Int? {
    didSet {
      self.detailLabel.text = String(stringInterpolationSegment: self.issueCount!)
    }
  }


  var issuePredicate: NSPredicate?

}
