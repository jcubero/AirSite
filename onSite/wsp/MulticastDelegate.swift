//
//  MulticastDelegate.swift
//  wsp
//
//  Created by Filip Wolanski on 2017-01-24.
//  Copyright © 2017 Ubriety. All rights reserved.
//

import Foundation


class MulticastDelegate<T> {
  
  /// The delegates hash table.
  fileprivate let delegates: NSHashTable<AnyObject>
  
  init() {
    
    delegates = NSHashTable.weakObjects()
  }
  
  internal func addDelegate(_ delegate: T) {
    delegates.add((delegate as AnyObject))
  }
  
  internal func removeDelegate(_ delegate: T) {
    delegates.remove((delegate as AnyObject))
  }
  
  internal func invokeDelegates(_ invocation: (T) -> ()) {
    
    for delegate in delegates.allObjects {
      invocation(delegate as! T)
    }
  }
  
  internal func containsDelegate(_ delegate: T) -> Bool {
    return delegates.contains((delegate as AnyObject))
  }
}

