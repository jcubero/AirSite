//
//  PDFFormPage.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-05-27.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation

extension PDFExport {


  func renderForms() {
    
    let forms = Form.mr_find(byAttribute: "project", withValue: project, andOrderBy: "order", ascending: true) as! [Form]
    
    for form in forms {
      renderForm(form)
    }
    
  }

  func renderForm(_ form: Form) {
    
    
    let data = form.document.savedStaticPDFData()
    

    let cfData = CFDataCreate(kCFAllocatorDefault, data.bytes, data.count)
    
    // let cfData = CFDataCreate(kCFAllocatorDefault, (data as CFData).bytes(to: UInt8.self, capacity: data.count), data.count)
    let cgDataProvider =  CGDataProvider(data: cfData!)
    let pdfRef  =  CGPDFDocument(cgDataProvider!)
    
    let numberOfPages = pdfRef?.numberOfPages
    
    let context = UIGraphicsGetCurrentContext()
    
    for i in 0 ..< numberOfPages! {
        
        let page = pdfRef?.page(at: i);
        let mediaBox = page?.getBoxRect(.mediaBox);
        
        UIGraphicsBeginPDFPageWithInfo(mediaBox!, nil)
        
        context?.saveGState ()
        context?.translateBy(x: 0, y: (mediaBox?.height)!)
        context?.scaleBy(x: 1, y: -1)
        context?.drawPDFPage(page!)
        context?.restoreGState ()
    }
    
    
    
  }



}
