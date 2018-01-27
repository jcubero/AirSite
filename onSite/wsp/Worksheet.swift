//
//  Worksheet.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-10-28.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import Foundation

class Worksheet {
  
  var rowHeader: Bool = false
  var columnHeader: Bool = false
  var columnHeaders: [Int] = []
  var rowHeaderNumner: Int = 0
 
  fileprivate var currentRow:Int = 1
  fileprivate var ref:BRAWorksheet!
  
  init(ref: BRAWorksheet) {
    self.ref = ref
  }
  
  func cell(_ cell: String, contains: String) -> Bool {
   
    let cell = self.ref.cell(forCellReference: cell)
    
    if cell == nil {
      return false
    }
    
    if cell?.stringValue().range(of: contains) != nil {
      return true
    } else {
      return false
    }
  }
  
  func readIntoSpreadsheet(_ withHeader: Bool) -> Spreadsheet {
    
    var row = withHeader == true ? 2 : 1
    
    var data:Spreadsheet = []
    let range = self.ref.dimension
    
    
    let height = (range?.bottomRowIndex)! - (range?.topRowIndex)! + 1
    let width = (range?.rightColumnIndex)! - (range?.leffColumnIndex)!
    
    while row != 0 {
      var column = 1
      var rowData: [String] = []
      
      
      while true {
        let cref = String(BRAColumn.columnName(forColumnIndex: column))
        let cellRef = "\(cref)\(row)"
        let cell = self.ref.cell(forCellReference: cellRef)

        if cell != nil {
          rowData.append(self.cleanString((cell?.stringValue())!))
          column += 1
          
        } else if rowData.count < width {
          rowData.append("")
          column += 1
          
        } else {
          break;
        }

      }
     
      if data.count < height {
        data.append(rowData)
        row += 1
      } else {
        row = 0
      }
    }
    
    return data
  }
  
  func cleanString(_ input: String) -> String {
    
    var output = input.strip()
    output = (output as NSString).replacingOccurrences(of: "\n", with: "") as String
    output = (output as NSString).trimmingCharacters(in: CharacterSet.newlines) as String
    
    return output
    
  }
  
  func saveData(_ data: Spreadsheet) {
    
    var greatestLength: Int = 0
    for d in data {
      greatestLength = max(d.count,greatestLength)
    }
    
    var maxWidths = [Int](repeating: 0, count: greatestLength)
   
    for (index, row) in data.enumerated() {
      if self.rowHeader && index == self.rowHeaderNumner {
        self.addHeaderRow(row)
      } else if self.columnHeaders.contains(index) {
        self.addWithHeaderColumn(row)
      } else if self.columnHeader {
        self.addWithWeakHeaderColumn(row)
      } else {
        addRow(row)
      }
      
      for (i, t) in row.enumerated() {
        maxWidths[i] = max(maxWidths[i], t.characters.count)
        
      }
    }
    
    for (index, maxWidth) in maxWidths.enumerated() {
      self.setWidthOfColumn(index, width: (maxWidth + 5))
    }
    
  }
  
  func addHeaderRow(_ row: [String]) {
    
    self._insert(row) { (item, _, cell) in
      self._makeHeader(cell, string: item)
    }
  }
  
  func addWithHeaderColumn(_ row: [String]) {
    
    self._insert(row) { (item, index, cell) in
      if index == 0 {
        self._makeHeader(cell, string: item)
      } else {
        cell.setStringValue(item)
      }
    }
    
    
  }
  
  func addWithWeakHeaderColumn(_ row: [String]) {
    
    self._insert(row) { (item, index, cell) in
      cell.setStringValue(item)
      if index == 0 {
        self._makeWeakHeader(cell)
      }
    }
  }
  
  func addRow(_ row: [String]) {
    self._insert(row) { (item, _, cell) in
      cell.setStringValue(item)
    }
  }
  
  func setWidthOfColumn(_ index: Int, width: Int) {
    
    if index >= self.ref.columns.count {
//      Config.error("Tried to adjust the width of a column that does not exist")
    } else {
      let col = self.ref.columns[index] as! BRAColumn
      col.width = width
    }
    
  }
  
  fileprivate func _makeHeader(_ cell: BRACell, string: String) {
    let attributes = [ NSAttributedStringKey.foregroundColor: UIColor.white]
    cell.setAttributedStringValue(NSAttributedString(string: string, attributes: attributes))
    let color = UIColor.wspBlue()
    cell.setCellFillWithForegroundColor(color, backgroundColor: color, andPatternType: kBRACellFillPatternTypeSolid)
  }
  
  fileprivate func _makeWeakHeader(_ cell: BRACell) {
    let color = UIColor(netHex: 0xF1F1F1)
    cell.setCellFillWithForegroundColor(color, backgroundColor: color, andPatternType: kBRACellFillPatternTypeSolid)
    
  }
  
  fileprivate func _insert(_ row: [String], op: (String, _ index: Int, _ cell: BRACell) -> Void) {
    
    var currentCol = 1
    for (index, item) in row.enumerated() {
      let cellRef = String(BRAColumn.columnName(forColumnIndex: currentCol)) + String(self.currentRow)
      let cell = self.ref.cell(forCellReference: cellRef, shouldCreate: true)
      op(item, index, cell!)
      currentCol += 1
    }
    self.currentRow += 1
    
    
  }
//  
//  private func increaseCol(currentCol: String) -> String {
//    let lastCharacter = currentCol.unicodeScalars.last!
//   
//    if lastCharacter == "Z" {
//      let numOfChars = currentCol.characters.count + 1
//      return String(count: numOfChars, repeatedValue: "A" as Character)
//    } else {
//      let newChar = lastCharacter.value + 1
//      var newString = currentCol.substringToIndex(currentCol.endIndex.predecessor())
//      newString.append(Character(UnicodeScalar(newChar)))
//      return newString
//      
//    }
//    
//  }
//  
}
