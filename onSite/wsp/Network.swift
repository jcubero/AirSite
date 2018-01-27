//
//  Network.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-05-29.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import Alamofire
import SwiftyJSON
import Reachability
import PromiseKit

typealias ServerData = Dictionary<String, AnyObject>


class APIRequest {
  
  var method: HTTPMethod!
  var url: URL
  var params: [String: AnyObject]?
  var resp: (JSON) throws -> JSON = { json in
    return json
  }
  
  var encoding: ParameterEncoding

  var preProgress: Float?
  var postProgress: Float?

  init(method: HTTPMethod, url: URL, params: [String: AnyObject]?, resp: @escaping (JSON) throws -> JSON) {
    self.method = method
    self.url = url
    self.params = params
    self.resp = resp
    
    self.encoding = URLEncoding()
    
    }
  
}


class Network {
  
  enum NetworkStatus { case Wifi, Cell, None }
  private var _networkStatus : NetworkStatus
  private var _reachability: Reachability!
  private var currentRequest: String = ""
  private var currentAPIReq: APIRequest?
  private var currentAlamofireRequest: Alamofire.Request?

  var authorizationToken: String? {
    didSet {
      if let token = authorizationToken {
        self.headers = [
          "X-CSRF-Token": token
        ]
      } else {
        self.headers = nil
      }
    }
  }
  private var headers: [String:String]?
  
 let alamoFireManager: Alamofire.SessionManager
  
  init() {
    _networkStatus = .None
    
    // make network requests synchronous initially
    let serverTrustPolicies: [String: ServerTrustPolicy] = [
      "wsp-infield.canadaeast.cloudapp.azure.com": .disableEvaluation
    ]

    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = Config.networkTimeout
    configuration.timeoutIntervalForResource = Config.networkTimeout
    self.alamoFireManager = Alamofire.SessionManager(configuration: configuration, serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies))
  
  }


  func cancelCurrentRequest() {

    if let req = self.currentAlamofireRequest {
      req.cancel()
    }

  }
  
  func request(request: APIRequest) -> Promise<JSON> {
    
    return Promise<JSON> { fulfill, reject in
      
      if !Config.detailedNetwork {
        Config.network("\(request.method): \(request.url)")
      }
      
      if self._networkStatus == .None {
        reject(Throwable.noNetwork)
      } else {
        print(request.url)
        
        let req = Alamofire.request(request.url, method: request.method, parameters: request.params, encoding: request.encoding, headers: nil).downloadProgress { progress in
                Manager.sharedInstance.updateNetworkProgress(Float(progress.fractionCompleted))
            }.responseData(queue: nil, completionHandler: self.networkResponse(fulfill: fulfill, reject: reject))

        self.currentRequest = req.debugDescription
        self.currentAPIReq = request
        self.currentAlamofireRequest = req
        if Config.detailedNetwork {
            Config.network(req.debugDescription)
        }
        }
      }
  }
  
  
  
    func downloadFileToDestination(_ url: String, destination: URL) -> Promise<URL> {
        
        return Promise<URL> { fulfill, reject in
            
            Config.network("Downloading file: \(url)")
            
            
            let req =  self.alamoFireManager.download(url).response { response in // method defaults to `.get`
//                print(response.request)
//                print(response.response)
//                print(response.temporaryURL)
//                print(response.destinationURL)
//                print(response.error)
                
                if(response.error != nil){

                    Config.error("Failed: \(String(describing: response.error))");
                    let error = response.error
                    reject(error!)
                    
                } else {
                    
                    if FileManager.default.fileExists(atPath: url) {
                        print("FILE Yes AVAILABLE")
                        fulfill(destination)
                    } else {
                        print("FILE NOT AVAILABLE")
                        Config.error("File does not exists: \(destination.absoluteString)");
                        reject(NSError(domain: "wsp", code: 0, userInfo: nil))
                    }

                }
            }
            self.currentRequest = req.debugDescription
            self.clearMemHolds()
        }
    }
  
  
 
  func networkResponse(fulfill: @escaping (JSON) -> Void, reject: @escaping (Error)->Void) ->
    (DataResponse<Data>) -> ()  {

        
      return { (r: DataResponse<Data> ) -> Void in
        
        guard self.currentAPIReq != nil else {
          Config.error()
          self.clearMemHolds()
          return
        }
        
        
        if (r.result.isFailure) {
          Config.warn("Network request response of: \(r)")
          self.clearMemHolds()
          reject(Throwable.network)
          
        } else {
          
          if let v =  r.result.value {
            
            // init(data: Data, options opt: JSONSerialization.ReadingOptions = [])
            let j = try JSON(data:v as Data)
            do {
              if let saveCookies = Config.networkConfig.saveCookies, let re = r.response  {
                saveCookies(re, self.alamoFireManager)
              }
              
              self.clearMemHolds()
                // fulfill(j)
                fulfill(j)
//            } catch let err {
//              Config.error("Invalid json object: \(v.description)")
//              Config.network(self.currentRequest)
//              self.clearMemHolds()
//              reject(err)
//            }
          }
          }else {
            Config.warn(String(format: "Could not decipher empty network response"))
            self.clearMemHolds()
            reject(Throwable.network)
          }
        }
      } as! (DataResponse<Data>) -> ()
  }


  func clearMemHolds() {
    self.currentAPIReq = nil
    self.currentAlamofireRequest = nil

  }

  func resetNetworkHeaders() {
   
    let cookies = HTTPCookieStorage.shared.cookies
    for cookie in cookies! {
      HTTPCookieStorage.shared.deleteCookie(cookie)
    }
    
    Alamofire.SessionManager.default.session.configuration.httpAdditionalHeaders = nil
    //Alamofire.SessionManager.sharedInstance.session.configuration.HTTPAdditionalHeaders = nil
    let session = URLSessionConfiguration.default
    _ = Alamofire.SessionManager(configuration: session)
    self.headers = nil
    
  }
  
  func startReachabilityNofications() {
    
    do {
      self._reachability = Reachability()
      
      self._reachability.whenReachable = { reachability in
        if reachability.connection == .wifi {
          Config.network("reachability changed to WiFi")
          self._networkStatus = .Wifi
        } else {
          Config.network("reachability changed to Cellular")
          self._networkStatus = .Cell
        }
      }
      
      self._reachability.whenUnreachable = { reachability in
        Config.network("reachability changed to offline")
        self._networkStatus = .None
      }
      
      if self._reachability.connection == .wifi {
        self._networkStatus = .Wifi
      } else if self._reachability.connection == .cellular {
        self._networkStatus = .Cell
      }
      
      try self._reachability.startNotifier()
    } catch {
      Config.error("Couldn't load reachability notifications")
    }
  }
  
}
