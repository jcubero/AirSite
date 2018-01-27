//
//  NetworkActivityView.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-06-28.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit


class NetworkActivityView: UIView {
  
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var statusLabel: UILabel!
  @IBOutlet weak var progressView: UIProgressView!
  
  @IBOutlet weak var errorView: UIView!
  @IBOutlet weak var errorLabel: UILabel!
  
  @IBOutlet weak var infoView: UIView!
  @IBOutlet weak var infoTitleLabel: UILabel!
  @IBOutlet weak var infoMessageLabel: UILabel!
  
  
  
  var inErrorMode: Bool = false
  var delegate: ActivityDelegate?

  var progress: Float  = 0.0 {
    didSet {
      self.progressView.setProgress(progress, animated: true)
    }
  }
  
  var message: String! {
    didSet {
      self.containerView.isHidden = false
      self.errorView.isHidden = true
      self.messageLabel.text = self.message
    }
  }
  
  var status: String! {
    didSet {
      self.statusLabel.text = self.status
    }
  }
  
  var error: String! {
    didSet {
      self.containerView.isHidden = true
      self.errorView.isHidden = false
      self.errorLabel.text = self.error
      self.inErrorMode = true
    }
  }
  
  var abortCallback: (() -> ())?
  var retryCallback: (() -> ())?
  var cancelCallback: (() -> ())?
  
  func loadView() {
    self.messageLabel.text = ""
    self.statusLabel.text = ""
    
    self.containerView.addShadow()
    self.errorView.addShadow()
    self.infoView.addShadow()
    
    self.containerView.isHidden = false
    self.errorView.isHidden = true
    self.infoView.isHidden = true
    self.inErrorMode = false
    
  }
  
  func showInfo(_ title: String, message: String) {
    self.containerView.isHidden = true
    self.errorView.isHidden = true
    self.infoView.isHidden = false
    
    self.infoTitleLabel.text = title
    self.infoMessageLabel.text = message
    
  }

  func dismiss(_ cb: @escaping () -> ()) {

    self.layer.removeAllAnimations()

    UIView.animate(withDuration: 0.3, animations: {
      self.alpha = 0
      }, completion: { _ in
        self.removeFromSuperview()
        cb()

      })

  }
  
  
  @IBAction func errorOkButtonPressed(_ sender: AnyObject) {
    
    cancelCallback?()
    self.inErrorMode = false
    self.delegate?.dismissActivity(nil)
    
  }
  
  @IBAction func errorRetryButtonPressed(_ sender: AnyObject) {
    
    self.containerView.isHidden = false
    self.errorView.isHidden = true
    self.infoView.isHidden = true
    self.inErrorMode = false
    
    retryCallback?()
    
  }
  @IBAction func abortPressed(_ sender: AnyObject) {
    
    abortCallback?()
    
  }
  
  static func loadActivity(_ message: String, cb: @escaping (NetworkActivityView) -> ()) {
    
    DispatchQueue.main.async {
      
      var view: NetworkActivityView?
      
      guard let window = UIApplication.shared.delegate!.window! else {
        Config.error("Couldn't load the main window!")
        return
      }
      
      let views = Bundle.main.loadNibNamed("NetworkActivity", owner: nil, options: nil)
      for v in views! {
        if let tog = v as? NetworkActivityView {
          view = tog
        }
      }
      
      guard let aView = view else {
        Config.error("Couldn't create activity view")
        return
      }
      
      aView.delegate = Manager.sharedInstance
      aView.loadView()

      aView.alpha = 0
      UIView.animate(withDuration: 0.3, animations: {
        aView.alpha = 1
      })

      
      aView.message = message
      aView.frame = window.bounds
      window.addSubview(aView)
      aView.progressView.setProgress(0, animated: false)
      cb(aView)
      
    }
    
    
  }
  
}
