//
//  Deleted.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-07-18.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation


import Foundation
import CoreData
import MagicalRecord
import PromiseKit
import SwiftyJSON

@objc(Deleted)

class Deleted: NSManagedObject {

  
  @NSManaged var id: String
  @NSManaged var time: Date
  
  
  @NSManaged var project: Project
  


}
