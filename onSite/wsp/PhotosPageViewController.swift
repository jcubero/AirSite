//
//  PhotosPageViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-03-14.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit

class PhotosPageViewController: UIPageViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.backgroundColor = UIColor.black.withAlphaComponent(0.8) //UIColor(colorLiteralRed: 1, green: 1, blue: 1, alpha: 0.8)
    
    
    // Do any additional setup after loading the view.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  override var preferredStatusBarStyle : UIStatusBarStyle {
    return UIStatusBarStyle.lightContent
  }
  
  
}
