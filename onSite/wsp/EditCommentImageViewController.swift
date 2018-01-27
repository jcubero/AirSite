//
//  EditCommentImageViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-08-16.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit

class EditCommentImageViewController: UIViewController, UIGestureRecognizerDelegate, UITextViewDelegate {
  
  var comment: Comment!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var tagImageView: UIImageView!
  @IBOutlet weak var tagLabel: UILabel!
  
  @IBOutlet weak var tagTitle: UILabel!
  @IBOutlet weak var tagSubtitle: UITextView!
  
  @IBOutlet weak var commentContainer: UIView!
  @IBOutlet weak var commentTextField: UITextView!
  @IBOutlet weak var backgroundView: UIView!
  
  @IBOutlet weak var imageBottomLayout: NSLayoutConstraint!
  
  override func viewDidLoad() {
    
    super.viewDidLoad()
    if let imageFilePath = self.comment!.imagePath {
      self.imageView.hnk_setImageFromFile(imageFilePath.path)
    }
    
    if let issue = self.comment.issue {
      self.tagImageView.image = UIImage(named: issue.shape)
      self.tagImageView.fillWithColor(issue.color)
      self.tagTitle.text = issue.topLevelTagTitle
      self.tagSubtitle.text = issue.formattedChildTitle
      self.tagLabel.text = issue.issueTag
    }
    
    
    if let title = comment.title {
      commentTextField.text = title
    }
    
    self.resize()
    
    NotificationCenter.default.addObserver(self, selector: #selector(EditCommentImageViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(EditCommentImageViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    
    
    let tapRec = UITapGestureRecognizer(target: self, action:#selector(EditCommentImageViewController.handleTap(_:)))
    tapRec.delegate = self
    self.view.addGestureRecognizer(tapRec)
    
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  func resize() {
    let screenSize: CGRect = UIScreen.main.bounds
    
    self.preferredContentSize = CGSize(width: screenSize.width * 0.8, height: ((screenSize.width * 0.8)/4 * 3) + 116)
    
  }
  
  
  @objc func handleTap(_ rec: UITapGestureRecognizer) {
    self.view.endEditing(true)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    commentTextField.becomeFirstResponder()
    
    
  }
  
  override var preferredStatusBarStyle : UIStatusBarStyle {
    return UIStatusBarStyle.lightContent
  }
  
  @IBAction func cancelPressed(_ sender: AnyObject) {
    self.dismiss(animated: true, completion: nil)
  
  }
  
  
  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    
    if text == "\n" {
      textView.resignFirstResponder()
      savePressed(textView)
      return false
    }
    return true
  }
  
  
  @IBAction func savePressed(_ sender: AnyObject) {
    
    comment.title = commentTextField.text
    comment.setModified()
    
    Manager.sharedInstance.saveCurrentState {
      self.dismiss(animated: true, completion: nil)
    }
    
  }
  
  @objc func keyboardWillShow(_ notification: Notification) {
    if let userInfo = notification.userInfo {
      if let keyboardSize: CGSize = (userInfo[UIKeyboardFrameBeginUserInfoKey] as AnyObject).cgRectValue.size {
        let adjust = keyboardSize.height
        imageBottomLayout.constant = adjust
        imageView.setNeedsLayout()
      }
    }
  }
  
  @objc func keyboardWillHide(_ notification: Notification) {
    imageBottomLayout.constant = 0
    imageView.setNeedsLayout()
  }
  
}
