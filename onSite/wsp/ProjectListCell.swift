//
//  ProjectListCell.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-06-08.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit


class ProjectListCell: UITableViewCell {
 
  @IBOutlet weak var title: UILabel!
  @IBOutlet weak var lastSync: UILabel!
  @IBOutlet weak var projectImage: UIImageView!
  @IBOutlet weak var lastAttemptedSync: UILabel!
  @IBOutlet weak var projectSizeLabel: UILabel!
  @IBOutlet weak var topRow: UIView!
  
  var project: Project? = nil {
    didSet {
      self.render()
    }
  }

  let manager = Manager.sharedInstance
  
  override func layoutSubviews() {
    super.layoutSubviews()
  }
  
  func render() {
    
    if let p = self.project {

      let dateFormatter = DateFormatter()
      //        dateFormatter.dateFormat = "YYYY-MM-dd hh:mm"
      dateFormatter.timeStyle = .short
      dateFormatter.dateStyle = .short
      dateFormatter.doesRelativeDateFormatting = true

      self.title.text = p.nonEmptyProjectTitle

      if p.title == "" {
        self.title.font = self.title.font.setItalic()
      } else {
        self.title.font = self.title.font.removeItalic()
      }
      
      if let sync = p.lastModified {
        let since = sync.timeIntervalSinceNow

        self.lastSync.text = dateFormatter.string(from: Date(timeIntervalSinceNow: since)).capitalized
      } else {
        self.lastAttemptedSync.text = NSLocalizedString("Unmodified", comment: "Unmodified")
      }
      
      if let sync = p.createdDate {
        let since = sync.timeIntervalSinceNow

        self.lastAttemptedSync.text = dateFormatter.string(from: Date(timeIntervalSinceNow: since)).capitalized
      } else {
        self.lastAttemptedSync.text = NSLocalizedString("Never", comment: "Never")
      }
      
      if let path = p.imagePath {
        self.projectImage.hnk_setImageFromFile(path.path)
      } else {
        self.projectImage.image = UIImage(named: "image-placeholder")
      }
      
      self.projectImage!.layer.cornerRadius = 20
      self.projectImage!.clipsToBounds = true
      
      self.projectSizeLabel.text = ""
      FileObjectManager.sharedInstance.fileSizeForProject(p, cb: { size in
        let string = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
        self.projectSizeLabel.text = string
        
      })
      
      
      self.layoutMargins = UIEdgeInsetsMake(0, self.topRow.frame.origin.x, 0, 0)
      
      
    }
  }
 
  
}
