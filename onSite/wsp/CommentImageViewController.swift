//
//  CommentImageViewController.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-09-19.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit



protocol CommentImageViewControllerDelegate: class {
  func didPressIssuetLabel(_ issue: Issue)
}

class CommentImageViewController: UIViewController, UIGestureRecognizerDelegate {
  
  var comment: Comment!
  var inPageViewController: Bool = false
  weak var delegate: CommentImageViewControllerDelegate?
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var tagImageView: UIImageView!
  @IBOutlet weak var tagLabel: UILabel!
  
  @IBOutlet weak var tagTitle: UILabel!
  @IBOutlet weak var tagSubtitle: UITextView!
  
  @IBOutlet weak var backgroundView: UIView!
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
    
    let tapRec = UITapGestureRecognizer(target: self, action:#selector(CommentImageViewController.handleTap(_:)))
    tapRec.delegate = self
    self.view.addGestureRecognizer(tapRec)
    
    if inPageViewController {
      self.view.alpha = 1
      self.backgroundView.backgroundColor = UIColor.clear
    }
    
  }
  
  @objc func handleTap(_ rec: UITapGestureRecognizer) {
    self.dismiss(animated: false, completion: nil)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if !inPageViewController {
      UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn, animations: {
        self.view.alpha = 1
        }, completion: nil)
      
    }
  }
  
  override var preferredStatusBarStyle : UIStatusBarStyle {
    return UIStatusBarStyle.lightContent
  }


  @IBAction func didPressCommentLabel(_ sender: AnyObject) {
    self.dismiss(animated: true, completion: nil)

    guard let issue = self.comment.issue else {
      Config.error()
      return
    }

    self.delegate?.didPressIssuetLabel(issue)

  }


}
