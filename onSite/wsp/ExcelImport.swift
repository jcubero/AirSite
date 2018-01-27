//
//  ExcelImport.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-10-28.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import Foundation
import MagicalRecord

enum ExcelImportType {
  case tags, project, areas
}

let ShapeExcelHeader = "Shape"
let ColorExcelHeader = "Color"
let VariableExcelHeader = "Variable"
let ConstantExcelHeader = "Constant"

class ExcelImport {
  
  var data: Spreadsheet?
  
  var errorMessage:String?
  
  var document: BRAOfficeDocumentPackage?
  
  
  init(excelFilePath: String) {
    
    document = BRAOfficeDocumentPackage.open(excelFilePath)
    
  }
  
  
  
  func importAll(_ areas: [FileStruct]?, cb: @escaping (String?) -> ()) {
    
    MagicalRecord.save({ context in
      
      self.errorMessage = nil
      
      let project = Project.create(context)
      
      
      guard let projectData = self.getData(.project)  else {
        self.errorMessage = NSLocalizedString("Could not read the selected spreadsheet", comment: "")
        return
      }
      
      Manager.sharedInstance.updateStatus(NSLocalizedString("Importing project settings...", comment: ""))
      
      if !self.addPropertiesToProjectFromSpreadsheet(projectData, project: project) {
        context.rollback()
        self.errorMessage = NSLocalizedString("Could not read project settings in selected spreadsheet", comment: "")
        return
      }
      
      
      Manager.sharedInstance.updateStatus(NSLocalizedString("Importing project library...", comment: ""))
      
      guard let tagData = self.getData(.tags) else {
        context.rollback()
        self.errorMessage =  NSLocalizedString("Could not read tags in selected spreadsheet", comment: "")
        return
      }
      
      if !self.addTagsToProjectFromSpreadsheet(tagData, project: project, context: context) {
        context.rollback()
        return
      }
      
      if let a = areas {
        Manager.sharedInstance.updateStatus(NSLocalizedString("Importing project areas...", comment: ""))
        
        for file in a {
          let area = Area.mr_createEntity(in: context)!
          area.project = project
          area.title = file.name
          area.setImageDataInContext(file.data, context: context)
          area.order = area.nextOrder() as NSNumber
        }
      }
      }, completion: { _, _ in
        
        cb(self.errorMessage)
        
    })
    
    
  }
  
  func importTags(intoProject mproject: Project, cb: @escaping (String?) -> ()) {
    

    MagicalRecord.save({ context in
      
      self.errorMessage = nil
      
      let project = mproject.mr_(in: context)!
      
      guard let tagData = self.getData(.tags) else {
        self.errorMessage = NSLocalizedString("Could not read tags in selected spreadsheet", comment: "")
        return
      }
      
      if !self.addTagsToProjectFromSpreadsheet(tagData, project: project, context: context) {
        context.rollback()
        return
      }
      
      }, completion: { _, _ in
        cb(self.errorMessage)

    })
    
  }
  
  func getData(_ type: ExcelImportType) -> Spreadsheet? {
    
    guard let doc = self.document else {
      self.errorMessage = "Could not read spreadsheet."
      return nil
    }
    
    var possibilities: [String] = []
    var withHeader: Bool = false
    switch type {

    case .tags:
      possibilities = ["Library", "Tags"]
      
    case .project:
      possibilities = ["Settings", "Project"]
    
    case .areas:
      possibilities = ["Areas", "Plans"]
      withHeader = true
      
    }
    
    if let worksheet = self.findWorksheet(doc, possibilities: possibilities) {
      let sheet = Worksheet(ref: worksheet)
      return sheet.readIntoSpreadsheet(withHeader)
    }
    
    self.errorMessage = "Could not read spreadsheet."
    return nil
    
    
  }
  
  
  
  func findWorksheet(_ document: BRAOfficeDocumentPackage, possibilities: [String]) -> BRAWorksheet? {
    for p in possibilities {
      if let sheet = document.workbook.worksheetNamed(p) {
        return sheet
      }
    }
    return nil
    
  }
  
  func addPropertiesToProjectFromSpreadsheet(_ data: Spreadsheet, project: Project) -> Bool {
   
    var valid = false
    
    for row in data {
     
      if row.count > 1 {
      
        let fieldTitle = row[0]
        let field = row[1]
        
        for dict in ProjectProperties {
          if dict["header"] == fieldTitle {
            if let key = dict["field"] {
              if key == "custom" {
                let f = dict["format"]!
                
                if f == "photo_quality" {
                  var value: Int = 2
                  switch field {
                  case "L":
                    value = 0
                  case "M":
                    value = 1
                  default:
                    value = 2
                  }
                  project.photoQuality = value as NSNumber
                  
                } else if f == "photo_page" {
               
                  let firstChar = field[field.startIndex]
                  let rest = String(field.characters.dropFirst())
                  
                  if let value = Int(rest) {
                    if firstChar == "P" {
                      project.photosPageOrientation = "P"
                      project.photosPerPagePortrait = value as NSNumber
                    } else {
                      project.photosPageOrientation = "L"
                      project.photosPerPageLandscape = value as NSNumber
                    }
                  }
                }
              } else {
                var format = "string"
                if let f = dict["format"] {
                  format = f
                }
                
                let value = self.getProjectValueFromString(field, format: format)
                project.setValue(value, forKey: key)
              }
              
              valid = true
              break
            }
          }
        }
      }
    }
    
    if !valid {
      self.errorMessage = "Could not read the project settings"
    }
    
    return valid
  }
  
  
  func addAreasToProjectFromSpreadsheet(_ data: Spreadsheet, project: Project, areas: [FileStruct]) -> Bool {
    
    let filenameColumn = 2
    var filenames:[String] = []
    
    for row in data {
      if row.count > filenameColumn {
        let filename = row[filenameColumn]
        filenames.append(filename)
      }
    }
    
    for file in areas {
      guard let actualName = file.fullName else {
        continue
      }
      if filenames.contains(actualName) {
        let area = Area.mr_createEntity()!
        area.project = project
        area.title = file.name
        area.imageData = file.data
        area.order = area.nextOrder() as NSNumber
      }
    }
    
    return true
    
  }
  
  func addTagsToProjectFromSpreadsheet( _ data: Spreadsheet, project: Project, context: NSManagedObjectContext) -> Bool  {
    var data = data
    
    var levels: [Level] = []
    
    // process the header
    let type = data[0]
    let header = data[1]
    
    var nextLevelIsColor = false
    var nextLevelIsShape = false
    var levelIndex: Int = 0
    
    if type.count != header.count {
      return false
    }
    
    for (index,item) in header.enumerated() {
      if type[index] == ColorExcelHeader { nextLevelIsColor = true }
      else if type[index] == ShapeExcelHeader { nextLevelIsShape = true }
      else {
        let title = item.strip()
        let kind = type[index].strip()
        let isTreeLevel = (kind == ConstantExcelHeader) ? false : true
        
        if title.characters.count == 0 || kind.characters.count == 0 {
          break
        }
        
        var parent: Level? = nil
        if isTreeLevel {
          
          let headerComponents = kind.components(separatedBy: CharacterSet.whitespaces)
          
          if headerComponents.count < 2 {
            self.errorMessage = "Do not understand header: \"\(kind)\""
            return false
          }
          
          let reference = headerComponents.last!.uppercased()
         
          for level in levels {
            if level.characterColumn(context) == reference {
              parent = level
              break
            }
          }
          
          if parent == nil {
            self.errorMessage = "Do not understand header: \"\(kind)\""
            return false
          }
          
        }
        
        let levelManagedObject = Level.getOrCreateLevelForProject(project, level: levelIndex, inContext: context)
        levelManagedObject.title = title
        levelManagedObject.isTreeLevel = isTreeLevel as NSNumber
        levelManagedObject.isColorLevel = nextLevelIsColor as NSNumber
        levelManagedObject.isShapeLevel = nextLevelIsShape as NSNumber
        levelManagedObject.parent = parent
        
        nextLevelIsShape = false
        nextLevelIsColor = false
        levels.append(levelManagedObject)
        
        levelIndex += 1
      }
    }
    
    
    data.remove(at: 0)
    data.remove(at: 0)
    
    Manager.sharedInstance.updateStatus(NSLocalizedString("Importing project library", comment: ""))

    for (rowIndex, row) in data.enumerated() {
      
      var currentIndex = 0
      let rowLength = row.count
      var currentParent: [Level:Tag] = [:]

      for level in levels {
        var colorString: String?
        var shapeString: String?
        
        // color
        if level.isColorLevel.boolValue {
          if currentIndex < rowLength {
            colorString = row[currentIndex]
          }
          currentIndex += 1
        }
       
        // shape
        if level.isShapeLevel.boolValue {
          if currentIndex < rowLength {
            shapeString = row[currentIndex]
          }
          currentIndex += 1
        }
        
        // tag
        if currentIndex < rowLength {
          let title = row[currentIndex].strip()
          
          if title.characters.count == 0 {
            currentIndex += 1
            continue
          }
         
          var predicate = NSPredicate(format: "level = %@ and title = %@", level, title)
          
          if level.isTreeLevel.boolValue {
            let parent = level.parent!
            guard let currentP = currentParent[parent] else {
              let cell = BRACell.cellReference(forColumnIndex: currentIndex+1, andRowIndex: rowIndex + 3)
              self.errorMessage = "No tag defined for level \"\(parent.nonEmptyTitle)\" when referenced from \"\(level.nonEmptyTitle)\" with title \"\(title)\" at \(cell)"
              return false
            }
            
            let parentPred = NSPredicate(format: "parent = %@", currentP)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, parentPred])
          }
          
          if let tag = Tag.mr_findFirst(with: predicate, in: context) {
            currentParent[level] = tag
          } else {
            let tag = Tag.mr_createEntity(in: context)!
            tag.title = title
            
            tag.level = level
            
            if level.isTreeLevel.boolValue {
              let parent = level.parent!
              guard let currentP = currentParent[parent] else {
                let cell = BRACell.cellReference(forColumnIndex: currentIndex+1, andRowIndex: rowIndex + 3)
                self.errorMessage = "No tag defined for level \"\(parent.nonEmptyTitle)\" when referenced from \"\(level.nonEmptyTitle)\" with title \"\(title)\" at \(cell)"
                return false
              }
              tag.parent = currentP
            }
          
            currentParent[level] = tag
            
            if let color = colorString {
              let colorStr = color.capitalized.trimmingCharacters(in: CharacterSet.whitespaces)
              if colorStr.characters.count > 0 {
                if let index = Tag.Colors.index(of: colorStr) {
                  tag.color = NSNumber(value: index + 1 as Int)
                } else {
                  self.errorMessage = "Undefined color \"\(colorStr)\" found."
                  return false
                  
                }
              }
            }
            
            if let shape = shapeString {
              let shapeStr = shape.capitalized.trimmingCharacters(in: CharacterSet.whitespaces)
              if shapeStr.characters.count > 0 {
                if let index = Tag.Shapes.index(of: shapeStr) {
                  tag.shape = NSNumber(value: index + 1 as Int)
                } else {
                  self.errorMessage = "Undefined shape \"\(shapeStr)\" found."
                  return false
                }
              }
            }
          }
        }
        
        currentIndex += 1
        
      }
    }
    
    return true
  }
  
  fileprivate func getProjectValueFromString(_ field: String, format: String) -> AnyObject? {
    
    switch format {
      
    case "bool":
      if field == "Y" {
        return NSNumber(value: true as Bool)
      } else {
        return NSNumber(value: false as Bool)
      }
      
    case "int":
      if let intVal = Int(field) {
        return NSNumber(value: intVal as Int)
      } else {
        return nil
      }
    case  "float":
      if let intVal = Float(field) {
        return NSNumber(value: intVal as Float)
      } else {
        return nil
      }
      
    case "date":
      return nil
      
    case "string":
      fallthrough
    default:
      return field as AnyObject
    }
      
    
  }
  
}
