//
//  Form.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-05-26.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord
import PromiseKit

@objc(Form)

class Form: SyncableModel {
  
   
  // properties
  @NSManaged var title: String
  @NSManaged var order: NSNumber?
  
  @NSManaged var data: [String:String]?
  
 
  // relationships
  @NSManaged var project: Project?
  @NSManaged var pdf: File?
  
  
  var pdfData: Data? { get {
    return self.pdf?.pdfData as! Data
    } set {
      let imageFile = self.makeFile("pdf", project: self.project!)
      imageFile.pdfData = newValue
    }
  }
  
  var filename: String {
    get {
      return "\(self.title).pdf"
    }
  }
  
  var nextOrder: Int {
    get {
      guard let forms = Form.mr_find(byAttribute: "project", withValue: self.project!) as? [Form] else {
        return 1
      }
      var topOrder = 0
      for form in forms {
        if let order = form.order {
          topOrder = max(topOrder, order.intValue)
        }
      }
      return topOrder + 1
    }
  }
  
  
  var document: ILPDFDocument {
    get {
      
      let d = ILPDFDocument(data: pdfData!)
      loadDataInto(d)
      return d
      
    } set {
      var dataToSave: [String:String] = [:]
      
      for f in newValue.forms {
        let form = f as! ILPDFForm
        if let v = form.value {
          dataToSave[form.name] = v
        }
      }
      
      data = dataToSave
    }
  }



  
  override class func registerSyncableData(_ converter: RemoteDataConverter) {
  
    
    converter.registerRemoteData("title", remote: "title", type: .String)
    converter.registerRemoteData("order", remote: "order", type: .Integer)
    converter.registerRemoteData("data", remote: "data", type: .Dictionary)
    
    converter.registerRemoteData("pdf", remote: "pdf", type: .PDF)
    
    
  }


  override func removeWithFiles() {

    self.pdf?.deleteFileData()
    super.removeWithFiles()


  }

  
  func loadDataInto(_ document: ILPDFDocument) {
    guard let savedData = data else {
      return
    }
    
    for f in document.forms {
      let form = f as! ILPDFForm
      if let v = savedData[form.name] {
        form.value = v
      }
    }
    
  }
  

}




extension ILPDFFormContainer: Sequence {
  public func makeIterator() -> NSFastEnumerationIterator {
    return NSFastEnumerationIterator(self)
  }
}
