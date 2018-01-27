//
//  CommentPopover.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-08-02.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit
import CoreData

class CommentsView: UIView, NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
  
  let manager : Manager = Manager.sharedInstance
  
  var issue: Issue!
  var project: Project!
  var selectedRow: IndexPath?
  
  var frc: NSFetchedResultsController<NSFetchRequestResult>!
  
  weak var rootView: ProjectSplitView!
  var imageData: Data?
  
  weak var tableView: UITableView!
  weak var textField: UITextField!
  weak var button: UIButton!
  
  weak var headerView: UIView!
  weak var categoryView: UIView!
  weak var tagImageView: UIImageView!
  weak var tagStrokeImageView: UIImageView!
  weak var firstTag: UILabel!
  weak var issueTag: UITextView!
  weak var issueNumber: UILabel!
  
  weak var footerView: UIView!
  weak var footerBottomConstraint: NSLayoutConstraint!
  weak var headerHeightConstraint: NSLayoutConstraint!
  weak var categoryHeightConstraint: NSLayoutConstraint!
  
  var headerInTableView: Bool = false
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)

    self.assignViews()

    self.textField.delegate = self
    self.textField.addTarget(self, action: #selector(CommentsView.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)

    self.button.addShadow()
    self.button.addTarget(self, action: #selector(CommentsView.submitComment(_:)), for: .touchUpInside)
    
    self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
    
    NotificationCenter.default.addObserver(self,
      selector: #selector(CommentsView.keyboardWillShow(_:)),
      name: NSNotification.Name.UIKeyboardWillShow,
      object: nil)
    NotificationCenter.default.addObserver(self,
      selector: #selector(CommentsView.keyboardWillHide(_:)),
      name: NSNotification.Name.UIKeyboardWillHide,
      object: nil)
    
    self.button.alpha = 0
    self.button.transform = CGAffineTransform.identity.scaledBy(x: 0, y: 0)

  }

  func assignViews() {

    self.headerView = self.subviews[0] 
    self.tagStrokeImageView = headerView.subviews[0].subviews[0] as! UIImageView
    self.tagImageView = headerView.subviews[0].subviews[1] as! UIImageView
    self.issueNumber = headerView.subviews[0].subviews[2] as! UILabel
    self.categoryView = headerView.subviews[1] 
    
    self.firstTag = headerView.subviews[1].subviews[0] as! UILabel
    self.issueTag = headerView.subviews[1].subviews[1] as! UITextView
    self.issueTag.alpha = 0.65
    
    self.tableView = self.subviews[1] as? UITableView
    
    self.footerView = self.subviews[2] 
    self.textField = self.footerView.subviews[2] as? UITextField

    self.button = self.footerView.subviews[4] as? UIButton

  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  
  @objc func textFieldDidChange(_ textField: UITextField) {
    if textField.text!.characters.count != 0 {
      self.button.isHidden = false
      UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
        self.button.alpha = 1
        self.button.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 1)
        }, completion: { finished in
      })
    } else {
      UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
        self.button.alpha = 0
        self.button.transform = CGAffineTransform.identity.scaledBy(x: 0.01, y: 0.01)
        }, completion: { finished in
          self.button.isHidden = true
      })
    }
  }
  
  @objc func keyboardWillShow(_ notification: Notification) {
    if let userInfo = notification.userInfo {
      if let keyboardSize: CGSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size {
        self.footerBottomConstraint.constant = keyboardSize.height
      }
    }
  }
  
  @objc func keyboardWillHide(_ notification: Notification) {
    self.footerBottomConstraint.constant = 0
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField.text != "" {
      self.submitComment(self)
    } else {
      textField.endEditing(true)
    }
    return true;
  }
  
  func loadComments(_ issue: Issue) {
    
    self.issue = issue
    self.project = self.issue.area?.project

    self.renderAndAnimateHeaderView()
    self.fetchComments()

    self.textField.addTarget(self, action: #selector(CommentsView.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)

    self.constrainHeaderView()

  }

  func fetchComments() {

    let req = NSFetchRequest<NSFetchRequestResult>(entityName: "Comment")
    
    let primarySortDescriptor = NSSortDescriptor(key: "createdDate", ascending: false)
    
    req.predicate =  NSPredicate(format: "issue = %@", self.issue)
    req.sortDescriptors = [primarySortDescriptor]
    
    self.frc = NSFetchedResultsController( fetchRequest: req,
      managedObjectContext: NSManagedObjectContext.mr_default(),
      sectionNameKeyPath: nil,
      cacheName: nil)
    
    self.frc.delegate = self
    self.tableView.delegate = self
    self.tableView.dataSource = self
    
    do {
      try self.frc.performFetch()
    } catch {
      Config.error("Could not fetch project.")
    }
    
    self.tableView.reloadData()

  }

  func renderAndAnimateHeaderView() {

    // Issue Number
    self.issueNumber.text = self.issue.issueTag
    
    // Image
    self.tagImageView.image = UIImage(named: self.issue.shape)
    self.tagImageView.fillWithColor(issue.color)
    self.tagStrokeImageView.image = UIImage(named: self.issue.shape)
    self.tagStrokeImageView.fillWithColor(UIColor.white)
    // Image Shadow
    self.tagStrokeImageView.layer.shadowOffset = CGSize(width: 0, height: 3)
    self.tagStrokeImageView.layer.shadowOpacity = 0.15
    self.tagStrokeImageView.layer.shadowRadius = 1
    // Tag & Category
    self.firstTag.text = self.issue.topLevelTagTitle
    self.issueTag.text = self.issue.formattedChildTitleWithNewLines
    
    UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
      self.headerView.backgroundColor = self.issue.color
      }, completion: { finished in
    })

  }


  func constrainHeaderView() {

    var targetHeaderHeight: CGFloat = 0
    
    if self.firstTag.text! != "" {
      let firstTagTextHeight = UIFont.systemFont(ofSize: 17).sizeOfString(self.firstTag.text!, constrainedToWidth: self.firstTag.frame.width).height
      targetHeaderHeight += firstTagTextHeight + 15
    }
    
    if self.issueTag.text! != "" {
      let issueTagTextHeight = UIFont.systemFont(ofSize: 14).sizeOfString(self.issueTag.text!, constrainedToWidth: self.issueTag.frame.width - 10).height
      targetHeaderHeight += issueTagTextHeight
      targetHeaderHeight += 20
    }
    
    
    if targetHeaderHeight > self.rootView.view.frame.height * 0.4 {
      targetHeaderHeight = self.rootView.view.frame.height * 0.4
    }
    
    categoryHeightConstraint.constant = targetHeaderHeight

    headerHeightConstraint.constant = 100
    if targetHeaderHeight > headerHeightConstraint.constant {
      headerHeightConstraint.constant = targetHeaderHeight + 25
    }
    
    setNeedsUpdateConstraints()
    
    issueTag.textColor = UIColor.white
    issueTag.font = UIFont.systemFont(ofSize: 14)
    issueTag.setContentOffset(CGPoint.zero, animated: false)


  }

  
  func textFieldDidChange() {
    UIView.animate(withDuration: 0.25, animations: {
      self.textField.intrinsicContentSize
    })
  }
  
  @objc func submitComment(_ sender: AnyObject) {
    let comment = Comment.mr_createEntity()!
    comment.title = self.textField.text!
    comment.issue = self.issue
    comment.imageData = self.imageData as! NSData as Data
    comment.user = manager.getCurrentUser()
    comment.savePhotoIfNeeded()
    comment.setModified()
    self.manager.saveCurrentState(nil)
    self.imageData = nil
    self.textField.text = ""
    self.button.isHidden = true
    self.dismissKeyboard()
  }
  
  func dismissKeyboard() {
    self.textField.endEditing(true)
    
  }
  
  func activateKeyboard() {
    
    self.textField.becomeFirstResponder()
    
  }
  
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    self.tableView.reloadData()
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let sections = self.frc.sections {
      let currentSection = sections[section]
      return currentSection.numberOfObjects
    }
    return 0
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let comment = self.frc.object(at: indexPath) as! Comment
    
    var cell: CommentCell?
    
    if comment.image != nil {
      cell = self.tableView.dequeueReusableCell(withIdentifier: "CommentCell") as? CommentCell
    } else {
      cell = self.tableView.dequeueReusableCell(withIdentifier: "CommentCell") as? CommentCell
    }
    
    cell!.comment = comment
    cell!.delegate = self

    return cell!
    
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

    let comment = self.frc.object(at: indexPath) as! Comment
    
    var height: CGFloat = 50
    var textWidth: CGFloat
    
    if comment.image != nil {
      height += 208
      textWidth = self.tableView.frame.width
    } else {
      textWidth = self.tableView.frame.width - 40
    }
    
    if let title = comment.title {
      let textSize = UIFont(name: "Helvetica Neue", size: 14)!.sizeOfString(title, constrainedToWidth: textWidth)
      height += textSize.height
      
    }

    return height
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    
  }
  
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    
    self.selectedRow = indexPath
    
    let cancelString = NSLocalizedString("Cancel", comment: "Cancel")
    let deleteButtonString = NSLocalizedString("Delete", comment: "Delete")
    let remove = UITableViewRowAction(style: .default, title: deleteButtonString) { (UITableViewRowAction, indexPath: IndexPath) -> Void in
      let deleteString = NSLocalizedString("Delete comment?", comment: "Delete Comment?")
      
      let alert = UIAlertController(title: deleteString, message: "", preferredStyle: UIAlertControllerStyle.alert)
      alert.addAction(UIAlertAction(title: deleteButtonString, style: .destructive, handler: { action in
        let comment = self.frc!.object(at: IndexPath(row: indexPath.row, section: 0)) as! Comment
        self.project.deleteProjectEntity(comment)
        self.manager.saveCurrentState(nil)
      }))
      alert.addAction(UIAlertAction(title: cancelString, style: .default, handler: { action in
        alert.dismiss(animated: true, completion: nil)
      }))
      
      self.rootView.present(alert, animated: true, completion: nil)
    }


    let editButtonString = NSLocalizedString("Edit", comment: "Edit")
    let edit = UITableViewRowAction(style: .normal, title: editButtonString) { (UITableViewRowAction, indexPath: IndexPath) -> Void in
      let comment = self.frc!.object(at: IndexPath(row: indexPath.row, section: 0)) as! Comment
      self.editComment(comment)
    }
    edit.backgroundColor = UIColor.wspNeutral()
    
    return [remove, edit]
    
  }
  
  func alertView(_ alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
    if buttonIndex == 1 {
      let comment = self.frc!.object(at: IndexPath(row: self.selectedRow!.row, section: 0)) as! Comment
      comment.title = alertView.textField(at: 0)!.text
      self.manager.saveCurrentState(nil)
    }
    self.tableView.setEditing(false, animated: true)
  }

  func editComment(_ comment: Comment) {

    if comment.image != nil {
      self.rootView.pages.showCommentImageEditor(comment)
    } else {
      
      let comments = self.frc.fetchedObjects as! [Comment]
      guard let index = comments.index(of: comment) else {
        Config.error()
        return
      }
      self.selectedRow = IndexPath(row: index, section: 0)
      
      
      let editButtonString = NSLocalizedString("Edit", comment: "Edit")
      let editAlertTitleString = NSLocalizedString("Edit Comment", comment: "Edit Comment")
      let cancelString = NSLocalizedString("Cancel", comment: "Cancel")
      let alert = UIAlertView(title: editAlertTitleString, message: "", delegate: self, cancelButtonTitle: cancelString)
      alert.alertViewStyle = .plainTextInput
      alert.textField(at: 0)!.text = comment.title
      alert.addButton(withTitle: editButtonString)
      alert.show()
      
    }
  }
}


extension CommentsView: CommentCellDelegate {
  
  func didPress(_ comment: Comment) {

    let predicate = NSPredicate(format: "issue = %@ and imageFile != nil", comment.issue!)
    let comments = Comment.mr_findAllSorted(by: "createdDate", ascending: false, with: predicate) as! [Comment]
    self.rootView.pages.showCommentImagesWithComment(comment, amongComments: comments)

  }
  
}

extension CommentsView: ImageEditorViewControllerDelegate {
  
  func pickedImage(_ image: UIImage) -> Comment {
    
    let comment = Comment.mr_createEntity()!
    comment.issue = self.issue
    comment.image = image
    comment.user = self.manager.getCurrentUser()
    comment.setModified()
    comment.savePhotoIfNeeded()
    self.manager.saveCurrentState(nil)
    return comment
    
    
  }
  
}
