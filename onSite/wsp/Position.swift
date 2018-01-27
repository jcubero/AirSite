//
//  Position.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-07-31.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord
import PromiseKit

@objc(Position)

class Position: SyncableModel {
  
  // properties
  @NSManaged var x: NSNumber?
  @NSManaged var y: NSNumber?
  @NSManaged var markerX: NSNumber?
  @NSManaged var markerY: NSNumber?
  @NSManaged var hasArrow: NSNumber?
 
  // relationships
  @NSManaged var issue: Issue?

  override class func registerSyncableData(_ converter: RemoteDataConverter) {
  
    converter.registerRemoteData("x", remote: "x", type: .Float)
    converter.registerRemoteData("y", remote: "y", type: .Float)
    converter.registerRemoteData("markerX", remote: "marker_x", type: .Float)
    converter.registerRemoteData("markerY", remote: "marker_y", type: .Float)
    converter.registerRemoteData("hasArrow", remote: "has_arrow", type: .Boolean)
    
    
  }

}
