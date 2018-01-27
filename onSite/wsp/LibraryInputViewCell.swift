//
//  LibraryInputViewCell.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-01-06.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit


class LibraryInputViewCell: LibraryBaseCell, UITextFieldDelegate {


  @IBOutlet weak var inputContainer: UIView!
  
  @IBOutlet weak var inputLabel: UILabel!
  @IBOutlet weak var inputTextField: UITextField!


  var previousInput: String? {
    didSet {
      if let i = self.previousInput {
        self.titleLabel.isHidden = true
        self.inputContainer.isHidden = false
        self.inputTextField.text = i
        
        self.textChanged(self.inputTextField)
      }
    }
  }
 

  override func awakeFromNib() {
    super.awakeFromNib()
    self.inputContainer.isHidden = true
    self.inputTextField.delegate = self
    
  }
  
  var isValid: Bool = false

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    
    if mode == .filterTag || mode == .filterTree {
      super.touchesBegan(touches, with: event)
      return
    }
    
    if let touch = touches.first {
      if touch.location(in: self).x > (0.9 * self.frame.size.width) && self.isValid {
        self.delegate?.tagInputSet(self.item, input: self.inputTextField.text!)
        return
      }
    }

    self.enableEdit()
  }
  
  func enableEdit() {
    if mode != .filterTag && mode != .filterTree {
      self.titleLabel.isHidden = true
      self.inputContainer.isHidden = false
      
      self.inputTextField.becomeFirstResponder()
      
    }
  }
  
  override func render() {
    
    self.filterButton.isHidden = !(mode == .filterTree || mode == .filterTag)
    
    self.titleLabel.attributedText = self.item.nonEmptyColoredAttributedTitle
    self.inputLabel.attributedText = self.item.nonEmptyColoredAttributedTitle
    
    self.tsConstraint.constant = 48
    self.checkmarkContraint.constant = 48
    
    self.updateIssueImageView()
   
    if self.item.type == .NumericInput {
      self.inputTextField.keyboardType = .numberPad
      
    } else {
      self.inputTextField.keyboardType = .default
      
    }
    
    self.textChanged(self.inputTextField)


  }

  @IBAction func textChanged(_ sender:UITextField) {
    self.isValid = (sender.text! != "")

  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    
    if self.isValid {
      self.inputTextField.resignFirstResponder()
      self.delegate?.tagInputSet(self.item, input: self.inputTextField.text!)
      
    }
    
    return self.isValid
  }
  
}
