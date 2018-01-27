//
//  ExcelExport.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-09-20.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord
import PromiseKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


typealias Spreadsheet = [[String]]

let ProjectProperties: [[String:String]] = [
  ["header": "Project Settings"],
  ["header": "Project Title", "field": "title"],
  ["header": "Project Subtitle", "field": "subtitle"],
  ["header": "Client Name", "field" : "client"],
  ["header": "Project Date", "field" : "date"],
  ["header": "Building Name", "field" : "buildingName"],
  ["header": "Project Location", "field" : "buildingAddress"],
  ["header": "Document Type", "field" : "documentType"],
  ["header": "Project Number", "field" : "projectNumber"],
  ["header": "Auto Open Comments (Y/N)", "field" : "openComments", "format" : "bool"],
  ["header": "Auto Open Camera (Y/N)", "field" : "openCamera", "format" : "bool"],
  ["header": "Pill Size (0 - 1)", "field" : "pillSize", "format" : "float"],
  ["header": "Save Photos on iPad (Y/N)", "field" : "photoAutoSave", "format": "bool"],
  ["header": "Embed Photo ID (Y/N)", "field" : "photoEmbedPills", "format": "bool"],
  
  ["header": "User Settings"],
  ["header": "Field Agent Name", "field" : "userNameForReport"],
  ["header": "Field Agent Company", "field" : "userCompanyForReport"],
  ["header": "Company Adress 1", "field" : "userCompanyAddress1"],
  ["header": "Company Adress 2", "field" : "userCompanyAddress2"],
  ["header": "Company Phone", "field" : "userCompanyPhone"],
  ["header": "Company Fax", "field" : "userCompanyFax"],
  ["header": "Company Email", "field" : "userCompanyEmail"],
  
  ["header": "Report Settings"],
  ["header": "Photo Quality (L,M,H)", "field" : "custom", "format": "photo_quality"],
  ["header": "Photos Per Page (L1,L4,L9,L12,P2,P6,P9,P12)", "field" : "custom", "format" : "photo_page"],
  ["header": "Plan Orientation (P,L)", "field" : "planPageOrientation"],
  ["header": "Plan Size (11,8)", "field" : "planPageSize", "format" : "int"],
  
]

class ExcelExport {
  
  var filename: URL!
  var data: Spreadsheet?
  
  var currentContext: NSManagedObjectContext!
  
  
  fileprivate var project: Project!
  
  var withObservations:Bool
  var withPlans:Bool
  var unsafeProject: Project
  
  
  init(project: Project, withObservations: Bool, withPlans: Bool) {
    self.withObservations = withObservations
    self.withPlans = withPlans
    self.unsafeProject = project
    
  }
  
  func promise() -> Promise<URL> {
  
    return Promise<URL> { fulfill, reject in
      
      MagicalRecord.save({ context in
        
        let withObservations = self.withObservations
        let withPlans = self.withPlans
        
        self.project = self.unsafeProject.mr_(in: context)
        self.currentContext = context
        

        
        let pathComponent = FileManager_.safeFilename("\(self.project.nonEmptyProjectTitle) (export).xlsx")
        let path = NSTemporaryDirectory()
        self.filename = URL(fileURLWithPath: path).appendingPathComponent(pathComponent)
        
        
        var filename = "s"
        if withObservations {
          filename += "+o"
        }
        if withPlans {
          filename += "+p"
        }
        
        let templatePath = Bundle.main.path(forResource: filename, ofType: "xlsx")
        if templatePath == nil {
          Config.error("Couldn't find spreadsheet template \(filename), aborting.")
          return
        }
        
        var currentSheet:Int = 0
        let document = BRAOfficeDocumentPackage.open(templatePath!)
        
        Manager.sharedInstance.updateStatus(NSLocalizedString("Exporting project settings...", comment: ""))
        
        let projectWorksheet: Worksheet = Worksheet(ref: document!.workbook.worksheets[currentSheet] as! BRAWorksheet)
        currentSheet += 1
        projectWorksheet.columnHeader = true
        let (projectData, headerData) = self.projectPropertiesToSpreadsheet()
        projectWorksheet.columnHeaders = headerData
        projectWorksheet.saveData(projectData)
        
        Manager.sharedInstance.updateStatus(NSLocalizedString("Exporting project library...", comment: ""))
        let tagWorksheet: Worksheet = Worksheet(ref: document!.workbook.worksheets[currentSheet] as! BRAWorksheet)
        currentSheet += 1
        tagWorksheet.rowHeader = true
        tagWorksheet.rowHeaderNumner = 1
        let tags = self.projectTagsToSpreadsheet()
        tagWorksheet.saveData(tags)


        if withPlans {
          
          Manager.sharedInstance.updateStatus(NSLocalizedString("Exporting project plans...", comment: ""))
          
          let areaWorksheet: Worksheet = Worksheet(ref: document!.workbook.worksheets[currentSheet] as! BRAWorksheet)
          currentSheet += 1
          areaWorksheet.rowHeader = true
          areaWorksheet.saveData(self.projectAreasToSpreadsheet(true))
        }
        
        if withObservations {
          
          Manager.sharedInstance.updateStatus(NSLocalizedString("Exporting project issues...", comment: ""))
          
          let issueWorksheet: Worksheet = Worksheet(ref: document!.workbook.worksheets[currentSheet] as! BRAWorksheet)
          currentSheet += 1
          issueWorksheet.rowHeader = true
          issueWorksheet.saveData(self.projectIssuesToSpreadsheet(tags))
        }
        
        Manager.sharedInstance.updateStatus(NSLocalizedString("Exporting project library (saving sheet)", comment: ""))
        document?.save(as: self.filename.path)
        
        self.currentContext = nil
        
        })
    }
  }
  
//    , completion: {  in
//    //self.filename!
//    // fulfill(())
//    // fulfill()
//    }
  fileprivate func projectPropertiesToSpreadsheet() -> (Spreadsheet, [Int]) {
    
    var rows: Spreadsheet = []
    var headerRows: [Int] = []
    var index = 0
    
    for property in ProjectProperties {
     
      if let header = property["header"] {
      
        if let field = property["field"] {
          
          var row: [String] = [header]
          
          if field == "custom" {
            let format = property["format"]!
            
            if format == "photo_quality" {
              var q = "L"
              switch self.project!.photoQuality.int32Value {
              case 0:
                q = "L"
              case 1:
                q = "M"
              default:
                q = "H"
              }
              row.append(q)
              
            } else if format == "photo_page" {
              
              var val = self.project!.photosPerPageLandscape.stringValue
              if self.project!.photosPageOrientation == "P" {
                val = self.project!.photosPerPagePortrait.stringValue
              }
              row.append("\(self.project!.photosPageOrientation)\(val)")
              
            }
            
          } else {
            if let format = property["format"] {
              row.append(self.getStringFromProjectValue(field, format: format))
            } else {
              row.append(self.getStringFromProjectValue(field, format: "string"))
            }
          }
          
          rows.append(row)
          
        } else {
          let row: [String] = [header]
          rows.append(row)
          headerRows.append(index)
        }
      }
      
      index += 1
    }
    
    return (rows, headerRows)
    
  }
  
    func test(){}
  fileprivate func getStringFromProjectValue(_ field: String, format: String) -> String {
    
    let repError : (() -> String) = { () -> String in
      Config.error("Format for value \(field) is incorrect")
      return ""
    }
    
    if let untypedValue: AnyObject? = self.project.value(forKey: field) as AnyObject!  {
      
      switch format {
       
      case "bool":
        if let v = untypedValue as? NSNumber {
          if v.boolValue {
            return "Y"
          } else {
            return "N"
          }
        } else { return repError()}
        
      case "int", "float":
        if let v = untypedValue as? NSNumber {
          return v.stringValue
        } else { return repError()}
        
      case "date":
        if let v = untypedValue as? Date {
         let dateFormatter = DateFormatter()
          dateFormatter.dateStyle = .short
          return dateFormatter.string(from: v)
        } else { return repError()}
        
        
      case "string":
        fallthrough
      default:
        if let v = untypedValue as? String {
          return v
        } else { return repError() }
      }
      
    } else {
      return ""
    }
    
  }
  
  fileprivate func projectTagsToSpreadsheet() -> Spreadsheet {
    
    let predicate = NSPredicate(format: "project = %@", self.project)
    let levels = Level.mr_findAllSorted(by: "level", ascending: true, with: predicate, in: self.currentContext) as! [Level]
    
    var tagIndex:[Tag: Int] = [:]
    var data: [[String]] = []
    
    for level in levels {
      
      Manager.sharedInstance.updateStatus(NSLocalizedString("Exporting project library (level \(level.level.intValue))...", comment: ""))
     
      var col:[String] = []
      var colIndex:Int = 0
      
      var colors: [String]? = nil
      var shapes: [String]? = nil
      if level.isColorLevel.boolValue {
        colors = []
      }
      
      if level.isShapeLevel.boolValue {
        shapes = []
      }
      
      let tags = Tag.mr_find(byAttribute: "level", withValue: level, andOrderBy: "title", ascending: true, in: self.currentContext) as! [Tag]
      if level.isTreeLevel.boolValue && level.level.intValue != 0 {
        
        var parentIndex: [Tag:Int] = [:]
        
        for tag in tags {
          
          guard let parent = tag.parent else {
            Config.error("Tag in tree level has no parent")
            break
          }
          
          if parentIndex[parent] == nil {
            guard let colNum = tagIndex[parent] else {
              Config.error("Tag refers to parent that does not exist")
              break
            }
            parentIndex[parent] = colNum
          }
          
          
          let colNum: Int = parentIndex[parent]!
          let tagHeight = self.maxHeightOfTag(tag)
          let tagArray = Array<String>(repeating: tag.nonEmptyTitle, count: tagHeight)
          let topNum = colNum + tagHeight
          
          if col.count < topNum {
            let missing = topNum - col.count
            col += Array<String>(repeating: "", count: missing)
            
            colors? += Array<String>(repeating: "", count: missing)
            shapes? += Array<String>(repeating: "", count: missing)
          }
          
          col.replaceSubrange(colNum..<topNum, with: tagArray)
          colors?.replaceSubrange(colNum..<topNum, with: Array<String>(repeating: tag.colorString, count: tagHeight))
          shapes?.replaceSubrange(colNum..<topNum, with: Array<String>(repeating: tag.shapeValue(), count: tagHeight))
          
          tagIndex[tag] = colNum
          parentIndex[parent]! += tagHeight
          
        }
        
      } else {
        // first or constant
        
        
        for tag in tags {
          let tagHeight = self.maxHeightOfTag(tag)
          let tagArray = Array<String>(repeating: tag.nonEmptyTitle, count: tagHeight)
          
          tagIndex[tag] = colIndex
          colIndex += tagHeight
          
          col += tagArray
          
          colors? += Array<String>(repeating: tag.colorString, count: tagHeight)
          shapes? += Array<String>(repeating: tag.shapeValue(), count: tagHeight)
        
        }
      }
      
      if let s = shapes {
        data.append(s)
      }
      if let c = colors {
        data.append(c)
      }
      
      data.append(col)
    }
    
    // ensure all are of the same length for transposition
    var transposed: [[String]] = []
    if let max: Int = data.map({ $0.count }).max() {
      for var col in data {
        if col.count < max {
          let missing = max - col.count
          col += Array<String>(repeating: "", count: missing)
        }
        transposed.append(col)
      }
      transposed = self.transpose(transposed)
    }
    
    
    var type: [String] = []
    var header: [String] = []
    
    for level in levels {
      
      if level.isColorLevel.boolValue {
        header.append(ColorExcelHeader)
        type.append(ColorExcelHeader)
      }
      
      if level.isShapeLevel.boolValue {
        header.append(ShapeExcelHeader)
        type.append(ShapeExcelHeader)
      }
     
      header.append(level.nonEmptyTitle)
      if level.isTreeLevel.boolValue {
        guard let parent = level.parent else {
          Config.error("Every tree level must have a parent!")
          type.append(VariableExcelHeader)
          continue
        }
        let character = parent.characterColumn(currentContext)
        let hdr = VariableExcelHeader + " from \(character)"
        type.append(hdr)
      } else {
        type.append(ConstantExcelHeader)
      }
    }
    
    Manager.sharedInstance.updateStatus(NSLocalizedString("Exporting project library (saving levels)", comment: ""))
    return [type] + [header] + transposed
    
  }
  
  fileprivate func maxHeightOfTag(_ tag: Tag) -> Int {
    
    var levelIndex : [Level: Int] = [:]
    if tag.children?.count > 0 {
      
      for child in tag.children!.allObjects as! [Tag] {
        let sum = self.maxHeightOfTag(child)
        let level = child.level
        
        if levelIndex[level] == nil {
          levelIndex[level] = 0
        }
        
        levelIndex[level]! += sum
      }
      
      return levelIndex.values.max()!
    } else {
      return 1
    }
  }
  
  fileprivate func recurseTagsToCurrentRow(_ tag: Tag, currentRow: [String], rows: [[String]], level: Level)  -> [[String]]{
    var currentRow = currentRow
    var rows = rows
    
    if level.isColorLevel.boolValue {
      currentRow.append(tag.colorString)
    }
    if level.isShapeLevel.boolValue {
      currentRow.append(tag.shapeValue())
    }
    
    currentRow.append(tag.nonEmptyTitle)
    
    
    if tag.children != nil && tag.children!.count > 0 {
      let tags = Tag.mr_find(byAttribute: "parent", withValue: tag, andOrderBy: "title", ascending: true) as! [Tag]
      for child in tags {
        rows = self.recurseTagsToCurrentRow(child, currentRow: currentRow, rows: rows, level: child.level)
      }
      return rows
    } else {
      rows.append(currentRow)
      return rows
    }
  }
  
  
  func transpose<T>(_ input: [[T]]) -> [[T]] {
    if input.isEmpty { return [[T]]() }
    let count = input[0].count
    var out = [[T]](repeating: [T](), count: count)
    for outer in input {
      for (index, inner) in outer.enumerated() {
        out[index].append(inner)
      }
    }
    
    return out
  }
  
  
  fileprivate func projectIssuesToSpreadsheet(_ tags: Spreadsheet) -> Spreadsheet {
    
    var predicate = NSPredicate(format: "project = %@", self.project)
    let areas = Area.mr_findAll(with: predicate, in: self.currentContext) as! [Area]
    
    predicate = NSPredicate(format: "project = %@", self.project)
    let levels = Level.mr_findAllSorted(by: "level", ascending: true, with: predicate, in: self.currentContext) as! [Level]
    
    var header: [String] = ["Issue ID", "Multiple User ID", "Area"]
    for level in levels {
      header.append(level.nonEmptyTitle)
    }
    
    header += ["Comment", "User", "Date"]
    
    var rows: [[String]] = []
    
    for area in areas {
      let issuePredicate = NSPredicate(format: "area = %@", area)
      let issues = Issue.mr_findAllSorted(by: "createdDate", ascending: true, with: issuePredicate, in: self.currentContext) as! [Issue]
      
      for issue in issues {
        let title: String = area.title
        
        var currentRow = [issue.issueNumber!, issue.userId, title]
        
        for level in levels {
         
          predicate = NSPredicate(format: "tag.level = %@ and issue = %@", level, issue)
          if let issueTag = IssueTag.mr_findFirst(with: predicate, in: self.currentContext) {
            currentRow.append(issueTag.title)
          } else {
            currentRow.append("")
          }
        }
        
        var commentString = ""
        for comment in  Comment.mr_find(byAttribute: "issue", withValue: issue, andOrderBy: "createdDate", ascending: true) as! [Comment] {
          guard let title = comment.title else { continue; }
          
          if commentString.characters.count == 0 {
            commentString += title
          } else {
            commentString += "\n" + title
          }
          
        }
        currentRow.append(commentString)
        
        var userTitle = ""
        if let user = issue.user {
          if let name = user.username {
            userTitle = name
          }
        }
        currentRow.append(userTitle)
        
        var dateString = ""
        if let date = issue.createdDate {
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "yyyy-MM-dd"
          dateString = dateFormatter.string(from: date as Date)
        }
        currentRow.append(dateString)
        
        rows.append(currentRow)
      }
    }
    return [header] + rows
  }

  fileprivate func projectAreasToSpreadsheet(_ withFilenames: Bool) -> Spreadsheet {
    
    let predicate = NSPredicate(format: "project = %@", self.project)
    let areas = Area.mr_findAllSorted(by: "order", ascending: true, with: predicate, in: self.currentContext)  as! [Area]
    var header = ["Area Name",  "Number of Issues"]
    
    if withFilenames {
      header.append("Filename")
    }
    
    var rows: [[String]] = []
    
    for area in areas {
      var currentRow: [String] = []
      let issuePredicate = NSPredicate(format: "area = %@", area)
      let issues = Issue.mr_findAllSorted(by: "issueNumber", ascending: true, with: issuePredicate, in: self.currentContext) as! [Issue]
      
      currentRow.append(area.title)
     
      currentRow.append(String(issues.count))
      
      if withFilenames {
        currentRow.append(area.filename)
      }
      
      rows.append(currentRow)
    }
    return [header] + rows
  }
  
}

