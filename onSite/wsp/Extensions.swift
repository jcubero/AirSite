//
//  UIViewExtension.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-08-02.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit


func + <K,V> (left: Dictionary<K,V>, right: Dictionary<K,V>?) -> Dictionary<K,V> {
  guard let right = right else { return left }
  return left.reduce(right) {
    var new = $0 as [K:V]
    new.updateValue($1.1, forKey: $1.0)
    return new
  }
}

func += <K,V> (left: inout Dictionary<K,V>, right: Dictionary<K,V>?) {
  guard let right = right else { return }
  right.forEach { key, value in
    left.updateValue(value, forKey: key)
  }
}


struct WeakContainer<T> where T: AnyObject {
  weak var _value : T?

  init (value: T) {
    _value = value
  }

  func get() -> T? {
    return _value
  }
}
