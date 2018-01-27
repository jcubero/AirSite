//
//  Config.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-05-26.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//
import Foundation
import UIKit

let DEV = false

let WSPAPIRoute = "https://wsp-infield.canadaeast.cloudapp.azure.com/INFIELD/"
//let WSPAPIRoute = "https://singe.wspgroup.com/INFIELD/"

class Config {

  // MARK: logs

  // define how much to log, always disabled when dev is off
  static let showInfo: Bool = DEV ? true : false
  static let showDatabase: Bool = DEV ? true : false
  static let showNetwork: Bool = DEV ? true : false

  static let detailedNetwork: Bool = false


  // enable fabric and google analytics; always on when dev is on
  static let enableAnalytics: Bool = DEV ? false : true
  static let googleAnalytics = "UA-68117901-1"

  // MARK: mgration

  // if true, performs migration but does not save the results, enable for testing migration only
  static let testMigration: Bool = false
  // when false, doesn't perform migration and deletes the database
  static let runMigration: Bool = true

  // MARK: archive files
  static let projectFileExtension = "infield"
  // encrypted keys -- used for archive files, do not change without breaking all previous versions of these files
  static let INFIELDKEY = "uGs6Nkq,wJaS4G%,"
  static let INFIELDIV =  "pRk&jGMU+]UxeR[T"


  // MARK: internal variables
  static let databaseReloadNotification = "WSPDatabaseReloadNotification"
  static let keychainService = "com.wsp.infield"

  // private queue for updating locked variables
  static let privateQueueService = "com.wsp.infield.queue"
  static let privateQueue = DispatchQueue(label: Config.privateQueueService, attributes: [])

  // MARK: data collection interface

  // data collection view variables
  static let fadeOnSelection: Bool = true
  static let draggingHandleSize: CGFloat = 58
  static let speedrackSize: CGFloat = 44

  // pill size
  static let pillMetadataHeight: CGFloat = 40
  static let forcePillPageAspectRation: Bool = false

  static let minPillSize: CGFloat = 12
  static let maxPillSize: CGFloat = 25

  static let experimentalFeaturesCode = "7123"

  // MARK: network

  static let networkTimeout: Double = DEV ? 5 : 60

  // static let networkConfig: NetworkConfig.Type = UbrietyNetworkConfig.self
  static let networkConfig: NetworkConfig.Type = WSPNetworkConfig.self
  static let Routes: NetworkAPIRoutes = networkConfig.Routes
  static let Fields: NetworkAPIFields = networkConfig.Fields

  // MARK: builds, etc

  static var buildNumner: Int {
    get {
      guard let ver = Bundle.main.infoDictionary!["CFBundleVersion"] as? String  else {
        return 0
      }
      if let v = Int(ver) {
        return v
      } else {
        return 0
      }
    }
  }

  static var versionNumber: String {
    get {
      guard let ver = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String  else {
        return ""
      }
      return ver
    }
  }

  static func error(_ s: String = "", functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {

    var file : NSString = fileName as NSString
    file = file.lastPathComponent as NSString

    let string = "ERROR - 😡 - [\(file):\(functionName):\(lineNumber)] :  \(s)"
    let err = NSError(domain: "com.ubriety.wsp", code: lineNumber, userInfo: [NSLocalizedDescriptionKey: string])

    Manager.sharedInstance.sendAnalyticsError(string, err: err)
    self.dispatchLog(string, printing: true)

  }


  static func warn(_ s: String = "", functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {

    var file : NSString = fileName as NSString
    file = file.lastPathComponent as NSString

    let string = "WARN - 😐 - [\(file):\(functionName):\(lineNumber)] :  \(s)"
    Manager.sharedInstance.sendAnalyticsWarning(string)
    self.dispatchLog(string, printing: true)

  }

  static func memoryWarning() {

    let string = "MEMORY WARNING - 😐 -  \(self.report_task_info())"

    Manager.sharedInstance.sendAnalyticsWarning(string)
    self.dispatchLog(string, printing: true)

  }

  static func startup(_ s :String = "", functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {

    var file : NSString = fileName as NSString
    file = file.lastPathComponent as NSString
    let string = "STARTUP - \(s)"

    self.dispatchLog(string, printing: true)

  }

  static func info(_ s :String = "", functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {

    var file : NSString = fileName as NSString
    file = file.lastPathComponent as NSString
    let string = "INFO - \(s)"

    self.dispatchLog(string, printing: Config.showInfo)

  }

  static func network(_ s :String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {

    var file : NSString = fileName as NSString
    file = file.lastPathComponent as NSString
    let string = "NETWORK - \(s)"

    self.dispatchLog(string, printing: Config.showNetwork)

  }

  static func database(_ s :String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {

    var file : NSString = fileName as NSString
    file = file.lastPathComponent as NSString
    let string = "DATABASE - \(s)"

    self.dispatchLog(string, printing: Config.showDatabase)

  }

  static func dispatchLog(_ string: String, printing: Bool) {

    if !printing { return }

    let log = string.trunc(450)

    DispatchQueue.main.async {
      LogFiles.sharedInstance.write(log)
      print(string)
    }
  }

    
  static func report_task_info() -> String {

    return ""
}

}
