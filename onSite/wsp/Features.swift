//
//  ExperimentalFeatures.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-09-28.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import Foundation
import KeychainAccess


class Features {
  
  // adjust pill text size to be consistent across every pill, ie: pill a1 and a888 with be the same font size
  var globalPillSizeAdjust: Bool = false
  
  var experimentalEnabled: Bool {
    get {
      if let experimental = self.keychain[self.keychainKey] {
        return experimental == "enabled"
      } else {
        return false
      }
    }
    set {
      self.keychain[self.keychainKey] = newValue ? "enabled" : "disabled"
      if newValue{
        enableExperimental()
      } else {
        disableExperimental()
      }
    }
  }
  
  // enable the sync feature
  var sync: Bool = true

  // show logs when clicking on the app information
  var showLogs: Bool = true
  
  var allowImportOfUnencryptedInfieldFiles = true

  var exportUnencryptedFiles = true
  
  fileprivate let keychain = Keychain(service: Config.keychainService)
  fileprivate let keychainKey = "experimental_"
  
  init() {
    
    if experimentalEnabled {
      enableExperimental()
    } else {
      disableExperimental()
    }
  }
  
  
  fileprivate func disableExperimental() {
//    sync = false
//    showLogs = false
//    allowImportOfUnencryptedInfieldFiles = false
  }
  
  fileprivate func enableExperimental() {
//    sync = true
//    showLogs = true
//    allowImportOfUnencryptedInfieldFiles = true
  }
  
}
