//
//  PhotosCollectionView.swift
//  wsp
//
//  Created by Jon Harding on 2015-10-27.
//  Copyright © 2015 Ubriety. All rights reserved.
//

import UIKit

class PhotosCollectionView: UICollectionView {
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  

}
