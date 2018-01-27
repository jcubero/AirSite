//
//  EditLibraryVariableViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-01-15.
//  Copyright © 2016 Ubriety. All rights reserved.
//


import UIKit
import CoreData

class EditLibraryVariableViewController: EditLibraryViewController {
  
  var parentNavigationController: UINavigationController!
  
  @IBOutlet weak var toolbarContainer: UIView!
  @IBOutlet weak var topContainerHeight: NSLayoutConstraint!
  
  @IBOutlet weak var scrollView: UIScrollView!
  
  @IBOutlet weak var rightInfoView: UIView!
  
  
  @IBOutlet weak var leftToolbarGradient: UIView!
  @IBOutlet weak var rightToolbarGradient: UIView!
  @IBOutlet weak var nullParentView: UIView!
  
  var singleLevel: Bool { get { return self.currentLevel.topParent == self.currentLevel.parent } }
  
  lazy var scrollingToolbar: EditLibraryParentToolbar = {
    let view = EditLibraryParentToolbar(frame: CGRect(x: 0,y: 0,width: 1000,height: 50))
    view.parentScrollView = self.scrollView
    self.scrollView.addSubview(view)
    view.delegate = self
    return view
    
  }()
  
  var topBarColor = UIColor(hexString: "f9f9f9")
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if self.singleLevel {
      self.topContainerHeight.constant = 0
      self.toolbarContainer.isHidden = true
    }
    
    self.scrollingToolbar.level = self.currentLevel.topParent
    
    self.drawTopBarWithGradients()
    
  }
  
  
  func drawTopBarWithGradients() {
    
    self.toolbarContainer.backgroundColor = self.topBarColor
    
    let startPoint = CGPoint(x: 0.0, y: 0.5)
    let endPoint = CGPoint(x: 1.0, y: 0.5)
    
    var gradient: CAGradientLayer = CAGradientLayer()
    gradient.frame = self.leftToolbarGradient.bounds
    gradient.colors = [self.topBarColor?.cgColor, self.topBarColor?.withAlphaComponent(0).cgColor]
    gradient.startPoint = startPoint
    gradient.endPoint = endPoint
    self.leftToolbarGradient.layer.insertSublayer(gradient, at: 0)
    self.leftToolbarGradient.backgroundColor = UIColor.clear
    
    gradient = CAGradientLayer()
    gradient.frame = self.rightToolbarGradient.bounds
    gradient.colors = [self.topBarColor?.withAlphaComponent(0).cgColor, self.topBarColor?.cgColor]
    gradient.startPoint = startPoint
    gradient.endPoint = endPoint
    self.rightToolbarGradient.layer.insertSublayer(gradient, at: 0)
    self.rightToolbarGradient.backgroundColor = UIColor.clear
    
  }
  
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    super.prepare(for: segue, sender: sender)
    
    if (segue.identifier == "EditLibraryParentRoot") {
      self.parentNavigationController = segue.destination as! UINavigationController
      let tableviewcontroller = self.parentNavigationController.visibleViewController as! EditLibraryParentViewController
      tableviewcontroller.currentLevel = self.currentLevel!.topParent!
      tableviewcontroller.ownerItem = nil
      tableviewcontroller.targetLevel = self.currentLevel
      tableviewcontroller.delegate = self
      tableviewcontroller.isSingleLevel = self.singleLevel
      tableviewcontroller.tagsInLevels = TagsInLevels(targetLevel: self.currentLevel)
      self.nullParentView.isHidden = !tableviewcontroller.tagsInLevels.inNullState
      
    }
  }
  
}


extension EditLibraryVariableViewController: EditLibraryParentDelegate {
  
  func selectTag(_ tag: Tag) {
    self.ownerItem = tag
    self.fetch()
    self.rightInfoView.isHidden = true
    
  }
  
  func pushNewLevel(_ tag: Tag) {
    
    self.scrollingToolbar.tags.append(tag)
    self.scrollingToolbar.level = tag.level.nextLevel

    
  }
}

extension EditLibraryVariableViewController: EditLibraryParentToolbarDelegate {
  
  func popToLevel(_ level: Level) {
    
    self.rightInfoView.isHidden = false
    
    guard let index = self.parentNavigationController.viewControllers.index(where: { (controller) -> Bool in
      let vc = controller as! EditLibraryParentViewController
      return vc.currentLevel == level
    }) else {
      Config.error()
      return
    }
    
    let vc = self.parentNavigationController.viewControllers[index]
    self.parentNavigationController.popToViewController(vc, animated: true)
    
  }
  
}
