//
//  ExportSettings.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-08-03.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import Foundation


enum ExportSettingsOrientation { case portrait, landscape }
enum ExportSettingsSize { case eight, eleven }



protocol ExportSettingsDelegate: class {
  func didChangeSettings(_ settings: ExportSettings)
    func getPDF(_ completion: @escaping (URL) -> ())
}

class ExportSettings {
  
  var hasChanges = false
  
  var orientation: ExportSettingsOrientation = .landscape {
    didSet {
      hasChanges = true
    }
  }
  var size: ExportSettingsSize = .eleven {
    didSet {
      hasChanges = true
    }
  }
  
  var photoPageOrientation: ExportSettingsOrientation = .portrait {
    didSet {
      self.photoPageCount = 9
    }
  }
  
  var photoPageCount: Int = 9 {
    didSet {
      hasChanges = true
    }
  }
  
  var cover: Bool = true {
    didSet {
      hasChanges = true
    }
  }
  
  var plans: Bool = true {
    didSet {
      hasChanges = true
    }
  }
  var comments: Bool = true {
    didSet {
      hasChanges = true
    }
  }
  var images: Bool = true {
    didSet {
      hasChanges = true
    }
  }
  
  var imageDetails: Bool = false {
    didSet {
      hasChanges = true
    }
  }
  
  var coverText: String = "" {
    didSet {
      hasChanges = true
    }
  }
  
  weak var delegate: ExportSettingsDelegate?
  
  
  var titlePage: PDFPage {
    get {
      return PDFPage()
    }
  }
  
  var areaPage: PDFPage {
    get {
      let page =  PDFPage()
      if self.size == .eleven {
        page.height = 17 * 72
        page.width = 11 * 72
      }
      
      if self.orientation == .landscape {
        let w  = page.height
        page.height = page.width
        page.width = w
      }
      
      return page
    }
    
  }
  
  var issuePage: PDFPage {
    get {
      return PDFPage()
    }
  }
  
  var photoPage: PDFPage {
    get {
      let page = PDFPage()
      if self.photoPageOrientation == .landscape {
        let w  = page.height
        page.height = page.width
        page.width = w
      }
      return page
    }
  }
  
  var detailPage: PDFPage {
    get {
      let page = PDFPage()
      page.width = 8.5 * 72
      page.height = 11 * 72
      
      page.topMargin = page.bottomMargin
      return page
      
    }
    
  }
  
  func loadDefaultSettingsFromProject(_ project: Project) {
    self.delegate =  nil
    
    if project.photosPageOrientation == "P" {
      self.photoPageOrientation = .portrait
      self.photoPageCount = project.photosPerPagePortrait.intValue
    } else {
      self.photoPageOrientation = .landscape
      self.photoPageCount = project.photosPerPageLandscape.intValue
    }
    
    if project.planPageSize == 11 {
      self.size = .eleven
    } else {
      self.size = .eight
    }
    
    if project.planPageOrientation == "P" {
      self.orientation = .portrait
    } else {
      self.orientation = .landscape
    }
    
//    self.plans = false
//    self.comments = false
//    self.images = false
//    self.cover = false
//    self.imageDetails = true

  }
  
}
