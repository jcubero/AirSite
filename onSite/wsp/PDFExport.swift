//
//  PDFExport.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-08-03.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import Foundation
import UIKit
import CoreData

enum IssueTableHeaders { case icon, planNumber, issueNumber, issueTitle, issueComments}


let PDFTitlePageColor = UIColor(netHex: 0x649f35)
let PDFSubtitleColor = UIColor(netHex: 0x00aab5)

let PDFFilenameAppendString = NSLocalizedString("InField Report", comment: "InField Report")

class PDFExport {
  
  var exportSettings: ExportSettings!
  
  var filename: URL?
  
  var project : Project!
  var currentPage: Int = 1
  
  var currentManagedObjectContext: NSManagedObjectContext!
  
  var cancelOperation: Bool = false
  
  let detailItemMargin: CGFloat = 10

  internal var commentFilterPredicate: NSPredicate?
  internal var filterPredicate: NSPredicate?
  internal var tagFilterPredicate: NSPredicate?

  
  init(project: Project, exportSettings: ExportSettings) {
    
    let pathComponent = FileManager_.safeFilename("\(project.nonEmptyProjectTitle) \(PDFFilenameAppendString).pdf")
    let path = NSTemporaryDirectory()
    self.filename  = URL(fileURLWithPath: path).appendingPathComponent(pathComponent)
    
    self.project = project
    self.exportSettings = exportSettings
    
  }

  func loadFilter(_ filter: Filter) {

    filterPredicate = filter.issuePredicate
    commentFilterPredicate = filter.commentPredicate
    tagFilterPredicate = filter.tagPredicate

  }
  
  func runInBackground(_ completion: @escaping () -> ()) {
    
    Config.privateQueue.async {
      self.currentManagedObjectContext = NSManagedObjectContext.mr_()
      self.createPDF()
      DispatchQueue.main.async(execute: {
        

        completion()
      })
    }
    
  }
  
  func createPDF() {

    UIGraphicsBeginPDFContextToFile(self.filename!.path, CGRect.zero, nil)
   
   
    if self.exportSettings.cover {
      self.renderCoverPage(self.exportSettings.titlePage)
    }
    
    let predicate = NSPredicate(format: "project = %@", self.project)
    let areas = Area.mr_findAllSorted(by: "order", ascending: true, with: predicate, in: self.currentManagedObjectContext) as! [Area]
    let orders: [NSNumber?] = areas.map() { return $0.order }
    
    for order in orders {
      if let o = order {
        
        let predicate = NSPredicate(format: "project = %@ and order = %@", self.project, o)
        guard let area = Area.mr_findFirst(with: predicate, in: self.currentManagedObjectContext) else {
          Config.error()
          return
        }
        
        autoreleasepool() {
          if self.exportSettings.plans {
            self.renderArea(area, page: self.exportSettings.areaPage)
          }
        }
        
        autoreleasepool() {
          if self.exportSettings.comments {
            self.renderComments(area, page: self.exportSettings.issuePage)
          }
        }
        
        autoreleasepool() {
          if self.exportSettings.images {
            self.renderImages(area, page: self.exportSettings.photoPage)
          }
        }
        
      } else {
        Config.error("Area with nil order found! Ignoring.")
      }
    }
    
    
    autoreleasepool() {
      if self.exportSettings.imageDetails {
        self.renderPhotoDetailPage(self.exportSettings.detailPage)
      }
    }
    
    
    autoreleasepool() {
      self.renderForms()
    }
    
    UIGraphicsEndPDFContext()
    
  }
  
  func fillImageWithColor(_ image: UIImage, color: UIColor) -> UIImage? {
    
    let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()
    context?.clip(to: rect, mask: image.cgImage!)
    context?.setFillColor(color.cgColor)
    context?.fill(rect)
    
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    if img != nil {
      return UIImage(cgImage: (img?.cgImage!)!, scale: 1.0, orientation: .downMirrored)
    } else {
      Config.error("fillImageWithColorError")
      return nil
    }
  }
 
  

  func drawLine(_ begin: CGPoint, term: CGPoint, width: CGFloat, color: UIColor) {
    
    let context = UIGraphicsGetCurrentContext()
    let x1 = begin.x
    let y1 = begin.y
    let x2 = term.x
    let y2 = term.y
    
    context?.setLineWidth(width)
    context?.setStrokeColor(color.cgColor)

    context?.beginPath()
    context?.move(to: CGPoint(x: x1, y: y1))
    context?.addLine(to: CGPoint(x: x2, y: y2))
    context?.strokePath()
    
  }
  
    // Cannot convert value of type '[String : Any]' to expected argument type '[NSAttributedStringKey : Any]?'
  func attributesWithFont(_ font: UIFont, alignment: NSTextAlignment) -> [NSAttributedStringKey : Any] {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = alignment
    return [NSAttributedStringKey(rawValue: NSAttributedStringKey.font.rawValue): font, NSAttributedStringKey(rawValue: NSAttributedStringKey.paragraphStyle.rawValue): paragraphStyle]
  }
  
  func resizeImage(_ image: UIImage, newHeight: CGFloat) -> UIImage {
    
    let scale = newHeight / image.size.height
    let newWidth = image.size.width * scale
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }

  
  func resizeImage(_ image: UIImage, maxHeight: CGFloat, maxWidth: CGFloat) -> UIImage {
    
    let hScale = maxHeight / image.size.height
    let wScale = maxWidth / image.size.width
    let scale = min(hScale, wScale)
    
    let newWidth = image.size.width * scale
    let newHeight = image.size.height * scale
    
    UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, 300/72)
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }
  
  func resizeImage(_ image: UIImage, minHeight: CGFloat, minWidth: CGFloat) -> UIImage {
    
    let hScale = minHeight / image.size.height
    let wScale = minWidth / image.size.width
    let scale = max(hScale, wScale)
    
    let newWidth = image.size.width * scale
    let newHeight = image.size.height * scale
    
    UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, 300/72)
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }
  
  
}
