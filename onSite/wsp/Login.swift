//
//  Login.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-05-29.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

class Login : UIViewController {
  
  @IBOutlet var username: UITextField!
  @IBOutlet var password: UITextField!
  @IBOutlet weak var incorrectLabel: UILabel!
  @IBOutlet weak var scrollView: UIScrollView!
  
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var signinButton: UIButton!
  @IBOutlet weak var downloadUsersLabel: UILabel!
  @IBOutlet weak var domainDescriptionButton: UIButton!
  
  @IBOutlet weak var errorStatusButton: UIButton!
  
  @IBOutlet weak var domainForm: UIView!
  @IBOutlet weak var domainContainerBackgroundView: UIView!

  
  let manager = Manager.sharedInstance
  var needUsers: Bool = true
  var needDomain: Bool = true
  weak var domainTableViewController: DomainTableViewController!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    NotificationCenter.default.addObserver(self, selector:#selector(Login.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object:nil)
    NotificationCenter.default.addObserver(self, selector:#selector(Login.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object:nil)


    domainContainerBackgroundView.layer.cornerRadius = 5.0
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.navigationBar.isHidden = true

    self.logic()
    
  }

  func logic() {

    if manager.user.downloadedDomains == nil && needDomain {

      self.updateDomainForLogin()

    } else if !manager.user.haveDomain {
      renderDomain()
      
    } else if self.manager.user.haveUpdatedUsers {
      // already have updated users, no need to update again
      self.needUsers = false
      self.renderLogin()
      
    } else if self.manager.user.loginWithKeychain() {
      self.renderBusy(showingRefresh: false, withMessage: "")
      
      self.needUsers = false
      
      self.manager.user.updateUsers().always {
        self.switchToProjectsViewController()
      }
      
    } else {
      self.updateUsersForLogin()
    }

  }


  func updateDomainForLogin() {

    self.renderBusy(showingRefresh: false, withMessage: NSLocalizedString("Downloading groups...", comment: ""))
    
    self.manager.user.updateDomains().then { Void -> Void in

      guard let d = self.manager.user.downloadedDomains else {
        Config.error()
        return
      }
      if d.count > 0 || self.manager.user.haveDomain {
        self.needDomain = false
        self.logic()
      } else {
        self.renderBusy(showingRefresh: true, withMessage: NSLocalizedString("No domains found on the server", comment: ""))
      }
    }.catch { err in
            
            if self.manager.user.haveDomain {
                self.needDomain =
                false
                self.logic()
            } else {
                self.renderBusy(showingRefresh: true, withMessage: NSLocalizedString("Could not connect to server", comment: ""))
            }
          
        }
  }
  
  func updateUsersForLogin() {
    
    self.renderBusy(showingRefresh: false, withMessage: "")
    self.manager.user.updateUsers()
      .then { _ -> () in
        
        guard let domain = self.manager.user.domain else {
          Config.error()
          return
        }
        
        if !self.manager.user.someUsersExist {
          self.renderBusy(showingRefresh: true, withMessage: NSLocalizedString("Could not find any users on the \"\(domain.name)\" domain. Change groups...", comment: "Could not find any users on the server"))
        } else {
          self.renderLogin()
          self.needUsers = false
        }
        
      }.catch { err in
        
        guard let domain = self.manager.user.domain else {
          Config.error()
          return
        }
        
        if !self.manager.user.someUsersExist {
          self.renderBusy(showingRefresh: true, withMessage: NSLocalizedString("Could not connect to the \"\(domain.name)\" domain. Change groups...", comment: "Could not contact the server. No users could be downloaded"))
        } else {
          self.renderLogin()
          self.needUsers = false
        }
    }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  
  override var preferredStatusBarStyle : UIStatusBarStyle {
    return UIStatusBarStyle.default
  }
  
  @objc func keyboardWillShow(_ notification: Notification) {
    if let keyboardSize = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? CGRect {
        // let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        let contentInset = UIEdgeInsetsMake(0, 0.0, keyboardSize.height, 0.0);
        self.scrollView.contentInset = contentInset
    }
  }
  
  @objc func keyboardWillHide(_ notification: Notification) {
    let contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.scrollView.contentInset = contentInset
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == username {
       self.password.becomeFirstResponder()
    } else if textField == password {
      self.password.resignFirstResponder()
      self.login(nil)
    }
    
    return true;
  }
  
  
  func renderBusy(showingRefresh refresh: Bool, withMessage message: String) {
    
    self.username.isHidden = true
    self.password.isHidden = true
    self.incorrectLabel.isHidden = true
    domainDescriptionButton.isHidden = true
    
    self.downloadUsersLabel.isHidden = false
    
    self.domainForm.isHidden = true
    
    if refresh {
      errorStatusButton.isHidden = false
      downloadUsersLabel.isHidden = true

      errorStatusButton.setAttributedTitle(hightlightChangeGroupsIfYouCan(message), for: UIControlState())

      self.activityIndicator.isHidden = true
      self.signinButton.setTitle(NSLocalizedString("Retry", comment: "Retry"), for: UIControlState())
      self.signinButton.isHidden = false
      
    } else {
      
      errorStatusButton.isHidden = true
      downloadUsersLabel.isHidden = false
      
      self.activityIndicator.isHidden = false
      self.downloadUsersLabel.text = message == "" ? NSLocalizedString("Downloading users...", comment: "Downloading users...") : message
      self.signinButton.isHidden = true
      
    }
  }


  func hightlightChangeGroupsIfYouCan(_ domainString: String) -> NSAttributedString {


    let domainButtonTitle = NSMutableAttributedString(string: domainString, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17),
      NSAttributedStringKey.foregroundColor: UIColor.lightGray])
    let range = (domainString as NSString).range(of: NSLocalizedString("Change groups...", comment: ""))
    domainButtonTitle.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.systemBlue()], range: range)

    return domainButtonTitle

  }
  
  func renderLogin() {
    
    guard let domain = self.manager.user.domain else {
      Config.error()
      return
    }
    
    self.username.isHidden = false
    self.password.isHidden = false
    self.signinButton.isHidden = false
    self.incorrectLabel.isHidden = true
    domainDescriptionButton.isHidden = false
    errorStatusButton.isHidden = true
    
    self.signinButton.setTitle(NSLocalizedString("Login", comment: "Login"), for: UIControlState())
    
    let domainString = "Connected to the \"\(domain.name)\" group. Change..."
    let domainButtonTitle = NSMutableAttributedString(string: domainString, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14) ])
    let range = (domainString as NSString).range(of: "Change...")
    domainButtonTitle.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.systemBlue()], range: range)
    
    domainDescriptionButton.setAttributedTitle(domainButtonTitle, for: UIControlState())
    
    
    self.activityIndicator.isHidden = true
    self.downloadUsersLabel.isHidden = true
    self.domainForm.isHidden = true
    
    
    Manager.sharedInstance.sendScreenView("User Login")
    
  }
  
  
  func renderDomain() {
    
    self.username.isHidden = true
    self.password.isHidden = true
    self.signinButton.isHidden = true
    self.incorrectLabel.isHidden = true
    domainDescriptionButton.isHidden = true
    errorStatusButton.isHidden = true
    
    self.activityIndicator.isHidden = true
    self.downloadUsersLabel.isHidden = true
    
    self.domainForm.isHidden = false

    Manager.sharedInstance.sendScreenView("Domain Login")
    domainTableViewController.tableView.reloadData()
    
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    if let vc = segue.destination as? DomainTableViewController {
      domainTableViewController = vc
      domainTableViewController.delegate = self
    }


  }

  
  @IBAction func login(_ sender: UIButton!) {

    if self.needDomain {
      self.updateDomainForLogin()
      return 
    }


    if self.needUsers {
      self.updateUsersForLogin()
      return 
    }
    
    if Manager.sharedInstance.user.login(username.text!, password: password.text!) {
      self.username.text = ""
      self.password.text = ""
      self.password.resignFirstResponder()
      self.username.resignFirstResponder()
      self.performSegue(withIdentifier: "ProjectList", sender: nil)
    } else {
      self.incorrectLabel.isHidden = false
      self.signinButton.isEnabled = false
      UIView.animate(withDuration: 0.3, animations: {
        self.signinButton.alpha = 0.3
      })
    }
  }
  
  
  @IBAction func usernameOrPasswordChanged(_ sender: AnyObject) {
    if !self.signinButton.isEnabled {
      self.incorrectLabel.isHidden = true
      self.signinButton.isEnabled = true
      UIView.animate(withDuration: 0.3, animations: {
        self.signinButton.alpha = 1.0
      })
      
    }
    
  }
  
  @IBAction func changeDomains(_ sender: AnyObject) {
    
    self.signinButton.isEnabled = true
    UIView.animate(withDuration: 0.3, animations: {
      self.signinButton.alpha = 1.0
    })

    manager.user.domain = nil
    renderDomain()
    needUsers = true
    
    
  }
  
  func switchToProjectsViewController() {
    self.performSegue(withIdentifier: "ProjectList", sender: nil)
    
  }
  
}

extension Login: DomainSelectionProtocol {

  func didSelectDomain(_ domain: Domain) {
    manager.user.domain = domain
    logic()

  }

}

