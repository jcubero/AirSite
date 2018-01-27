//
//  String+Extensions.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-09-29.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation

extension String {
  subscript(integerIndex: Int) -> Character {
    let index = characters.index(startIndex, offsetBy: integerIndex)
    return self[index]
  }
  
  subscript(integerRange: Range<Int>) -> String {
    let start = characters.index(startIndex, offsetBy: integerRange.lowerBound)
    let end = characters.index(startIndex, offsetBy: integerRange.upperBound)
    let range = start..<end
    return String(self[range])
  }
  
  public func strip() -> String {
    return self.trimmingCharacters(in: .whitespaces)
  }
  
  
  func trunc(_ length: Int, trailing: String? = "...") -> String {
    if self.characters.count > length {
      return self.substring(to: self.characters.index(self.startIndex, offsetBy: length)) + (trailing ?? "")
    } else {
      return self
    }
  }
  
}


