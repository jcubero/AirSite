//
//  ActivityView.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-02-15.
//  Copyright © 2016 Ubriety. All rights reserved.
// 
// ActivityView.swift and Activity.xib are view that are displayed directly on the window object,
// and inform the user that the iPad is busy (either generating a report, loading a project, etc). 
// They either dismiss themselves, or they can also display an error message, whereby a user can 
// dismiss them by pressing the dismiss button.

import UIKit


protocol ActivityDelegate: class {
  func dismissActivity(_ cb: (()->())?)
}

class ActivityView: UIView {
  
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var statusLabel: UILabel!
  
  @IBOutlet weak var errorView: UIView!
  @IBOutlet weak var errorLabel: UILabel!
  @IBOutlet weak var containerWidthConstraint: NSLayoutConstraint!
  
  var inErrorMode: Bool = false
  weak var delegate: ActivityDelegate?
  
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
      
      if error.characters.count > 50 {
        containerWidthConstraint.constant = 700
        
      }
      
    }
  }
  
  func loadView() {

    self.messageLabel.text = ""
    self.statusLabel.text = ""
    
    self.containerView.addShadow()
    self.errorView.addShadow()
    
    self.containerView.isHidden = false
    self.errorView.isHidden = true
    self.inErrorMode = false

    
  }


  func initialLoad() {

    self.delegate = Manager.sharedInstance

    self.alpha = 0
    UIView.animate(withDuration: 0.3, animations: {
      self.alpha = 1
    })
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
    self.delegate?.dismissActivity(nil)
  }
  
  static func loadActivity(_ message: String, cb: @escaping (ActivityView) -> ()) {


    let loadBlock =  {

      var view: ActivityView?

      guard let window = UIApplication.shared.delegate!.window! else {
        Config.error("Couldn't load the main window!")
        return
      }

      // check if the activity view already exists.
      for subv in window.subviews {
        if let v = subv as? ActivityView {
          view = v
        }
      }

      // create the view
      if view == nil {
        let views = Bundle.main.loadNibNamed("Activity", owner: nil, options: nil)
        for v in views! {
          if let tog = v as? ActivityView {
            view = tog
          }
        }

        guard let aView = view else {
          Config.error("Couldn't create activity view")
          return
        }

        aView.initialLoad()
        aView.frame = window.bounds
        window.addSubview(aView)
        aView.loadView()

      }
      
      view!.message = message
      cb(view!)

    }

    if Thread.isMainThread {
      loadBlock()
    } else {
      DispatchQueue.main.async(execute: loadBlock)
    }
    
    
  }
  
}
