//
//  NSDate+Extensions.swift
//  wsp
//
//  Created by Filip Wolanski on 2017-01-25.
//  Copyright © 2017 Ubriety. All rights reserved.
//

import Foundation


extension Date { }

public func ==(lhs: Date, rhs: Date) -> Bool {
  return lhs.compare(rhs) == ComparisonResult.orderedSame
}

public func <(lhs: Date, rhs: Date) -> Bool {
  return lhs.compare(rhs) == .orderedAscending
}
