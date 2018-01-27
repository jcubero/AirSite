//
//  ImageEditorViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2015-08-24.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit
import CameraManager

protocol ImageEditorViewControllerDelegate: class {
  func pickedImage(_: UIImage) -> Comment
  
}

enum ImageEditorMode {
  case crop, draw, camera
}


class ImageEditorViewController: UIViewController {
  
 
  var origImage: UIImage!
  
  
  weak var delegate: ImageEditorViewControllerDelegate?
  var initialText: String = ""
  let cameraManager = CameraManager()
  var mode: ImageEditorMode = .camera
  
  weak var navController: Nav!
  
  @IBOutlet weak var titleLabel: UILabel!
  
  @IBOutlet weak var circleButton: UIButton!
  @IBOutlet weak var rectangleButton: UIButton!
  @IBOutlet weak var squiggleButton: UIButton!
  @IBOutlet weak var arrowButton: UIButton!
  @IBOutlet weak var removeButton: UIButton!
  
  @IBOutlet weak var drawingView: ACEDrawingView!
  @IBOutlet weak var croppingView: EditAreaImageView!
  @IBOutlet weak var backingImageView: UIImageView!
  @IBOutlet weak var cameraView: UIView!
  
  @IBOutlet weak var completeButton: UIButton!
 
  
  @IBOutlet weak var editorButtons: UIView!
  @IBOutlet weak var cropButtons: UIView!
  
  @IBOutlet weak var bottomDrawingConstraint: NSLayoutConstraint!
  @IBOutlet weak var leftDrawingConstraint: NSLayoutConstraint!
  @IBOutlet weak var topDrawingConstraint: NSLayoutConstraint!
  @IBOutlet weak var rightDrawingConstraint: NSLayoutConstraint!
  
  @IBOutlet weak var aspectRatioButton: UIButton!
  
  @IBOutlet weak var cameraButtonView: UIView!
  @IBOutlet weak var cameraButtonContainer: UIView! {
    didSet {
      cameraButtonContainer.backgroundColor = UIColor.wspLightBlue()
      cameraButtonContainer.layer.cornerRadius = cameraButtonContainer.frame.size.height / 2
      cameraButtonContainer.layer.masksToBounds = true
    }
  }
  
  override func viewDidLoad() {
    
    super.viewDidLoad()
    
    self.drawingView.lineColor = UIColor.red
    self.drawingView.lineWidth = 3
    
    self.croppingView.backgroundColor = UIColor.white
    self.croppingView.clipsToBounds = true
    
    self.cameraManager.cameraDevice = .back
    self.cameraManager.cameraOutputQuality = .high
    self.cameraManager.flashMode = .auto
    self.cameraManager.writeFilesToPhoneLibrary = false
    
    self.cameraView.clipsToBounds = true
    
    
    self.drawingView.layer.borderColor = UIColor.wspNeutral().cgColor
    self.drawingView.layer.borderWidth = 1
    
    self.resize()
    self.render()
  
  }
  
  
  func resize() {
    let screenSize: CGRect = UIScreen.main.bounds
    
    self.preferredContentSize = CGSize(width: screenSize.width * 0.8, height: ((screenSize.width * 0.8)/4 * 3) + 116)
    
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    self.resize()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
 
  func render() {
    
    if self.mode == .crop {
      self.view.sendSubview(toBack: self.drawingView)
      self.view.sendSubview(toBack: self.backingImageView)
      self.view.sendSubview(toBack: self.cameraView)
      
      self.croppingView.isHidden = false
      
      
      self.editorButtons.isHidden = true
      self.cropButtons.isHidden = false
      
      self.cameraView.isHidden = true
      
      self.croppingView.image = self.origImage
     
      self.completeButton.isHidden = false
      self.cameraButtonView.isHidden = true
      self.completeButton.setTitle("\u{e3be}", for: UIControlState())
      
      let label = NSLocalizedString("Crop", comment: "Crop")
      self.titleLabel.text = label
      
      self.updateButtonOnAspectChange()
      
    } else if self.mode == .camera {
     
      self.cameraManager.addPreviewLayerToView(self.cameraView)

      self.view.sendSubview(toBack: self.drawingView)
      self.view.sendSubview(toBack: self.backingImageView)
      self.view.sendSubview(toBack: self.croppingView)
      
      self.editorButtons.isHidden = true
      self.cropButtons.isHidden = true
      
      self.croppingView.isHidden = true
      self.cameraView.isHidden = false
      
      let label = NSLocalizedString("Take a photo", comment: "Take a photo")
      self.titleLabel.text = label
     
      self.completeButton.isHidden = true
      self.cameraButtonView.isHidden = false
      self.completeButton.setTitle("\u{e412}", for: UIControlState())
      
      
    } else {
      self.view.sendSubview(toBack: self.backingImageView)
      self.view.sendSubview(toBack: self.croppingView)
      self.view.sendSubview(toBack: self.cameraView)
      
      self.arrowTool(self.arrowButton)
      
      self.croppingView.isHidden = true
      
      self.editorButtons.isHidden = false
      self.cropButtons.isHidden = true
      
      self.cameraView.isHidden = true
      
      self.completeButton.isHidden = false
      self.cameraButtonView.isHidden = true
      self.completeButton.setTitle("\u{e5ca}", for: UIControlState())
      
      let label = NSLocalizedString("Annotate", comment: "Annotate")
      self.titleLabel.text = label
      
      self.calculateClientRectOfImageInUIImageView(self.backingImageView)
      
    }
    
    self.view.bringSubview(toFront: self.completeButton)
    
  }
 
  
  func calculateClientRectOfImageInUIImageView(_ image: UIImageView) {
    let imgViewSize = image.frame.size
    let imgSize = image.image!.size
    
    let scaleW = imgViewSize.width / imgSize.width
    let scaleH = imgViewSize.height / imgSize.height
    let zoom = fmin(scaleW, scaleH)
    
    let x = (imgViewSize.width - imgSize.width * zoom) / 2
    let y = (imgViewSize.height - imgSize.height * zoom) / 2
   
    self.topDrawingConstraint.constant = y
    self.bottomDrawingConstraint.constant = -y
    
    self.leftDrawingConstraint.constant = x
    self.rightDrawingConstraint.constant = -x
    
  }
  
  func clearButtons() {
    
    self.squiggleButton.setTitleColor(UIColor.wspNeutral(), for: UIControlState())
    self.rectangleButton.setTitleColor(UIColor.wspNeutral(), for: UIControlState())
    self.circleButton.setTitleColor(UIColor.wspNeutral(), for: UIControlState())
    self.arrowButton.setTitleColor(UIColor.wspNeutral(), for: UIControlState())
    
  }
  
  
  @IBAction func squiggleTool(_ sender: UIButton) {
    self.clearButtons()
    sender.setTitleColor(UIColor.wspLightBlue(), for: UIControlState())
    
    self.view.bringSubview(toFront: self.drawingView)
    self.drawingView.drawTool = ACEDrawingToolTypePen
    
  }
  
  @IBAction func rectangleTool(_ sender: UIButton) {
    self.clearButtons()
    sender.setTitleColor(UIColor.wspLightBlue(), for: UIControlState())
    self.view.bringSubview(toFront: self.drawingView)
    self.drawingView.drawTool = ACEDrawingToolTypeRectagleStroke
    
  }
  
  @IBAction func circleTool(_ sender: UIButton) {
    self.clearButtons()
    sender.setTitleColor(UIColor.wspLightBlue(), for: UIControlState())
    self.view.bringSubview(toFront: self.drawingView)
    self.drawingView.drawTool = ACEDrawingToolTypeEllipseStroke
    
  }
  
  @IBAction func arrowTool(_ sender: UIButton) {
    
    self.clearButtons()
    sender.setTitleColor(UIColor.wspLightBlue(), for: UIControlState())
    self.view.bringSubview(toFront: self.drawingView)
    self.drawingView.drawTool = ACEDrawingToolTypeLine
    
  }
  
  @IBAction func undoDraw(_ sender: AnyObject) {
    
    self.drawingView.undoLatestStep()
    
  }
  
  @IBAction func rotateLeft(_ sender: AnyObject) {
    self.croppingView.rotation = CGFloat(-M_PI_2)
    
  }
  
  @IBAction func rotateRight(_ sender: AnyObject) {
    self.croppingView.rotation = CGFloat(M_PI_2)
    
  }
  
  @IBAction func cancelButtonPressed(_ sender: UIButton) {
    
    self.dismiss(animated: true, completion: {
      self.navController.afterImageSelection(nil)
    })
    
  }
  
  @IBAction func changeAspect(_ sender: AnyObject) {
    
    self.croppingView.cropAspectRatio = 1.0 / self.croppingView.cropAspectRatio
    self.updateButtonOnAspectChange()
    
    
  }
  
  func updateButtonOnAspectChange() {
    
    if self.croppingView.cropAspectRatio > 1 {
      self.aspectRatioButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
      
    } else {
      self.aspectRatioButton.transform = CGAffineTransform(rotationAngle: CGFloat(0))
    }
    
  }
  
  @IBAction func takePhotoPressed(_ sender: AnyObject) {
    
    self.cameraManager.capturePictureWithCompletion({ [unowned self] (image, error) -> Void in
      self.origImage = image
      self.mode = .draw
      self.backingImageView.image = self.origImage
      
      self.cameraManager.stopAndRemoveCaptureSession()
      self.render()
      
      })
    
    
  }
  
  @IBAction func checkmarkButtonPressed(_ sender: UIButton) {
   
    
    if self.mode == .crop {
      self.mode = .draw
      
      self.origImage = self.croppingView.image
      
      self.backingImageView.image = self.origImage
      
      self.render()
      
    } else if self.mode == .camera {
      
      
    } else {
      
      let currentDrawing = self.drawingView.image
    
      var actualImage = self.origImage
      if currentDrawing != nil {
        actualImage = self.overlayImage(currentDrawing!, sourceImage: actualImage!)
      }
      
      let comment = self.delegate?.pickedImage(actualImage!)
      self.dismiss(animated: true, completion:{
        
        self.navController.afterImageSelection(comment)
      
      })
      
    }
    
  }
  
  func overlayImage(_ image: UIImage, sourceImage: UIImage) -> UIImage {
    
    UIGraphicsBeginImageContext(sourceImage.size);
    sourceImage.draw(in: CGRect(origin: CGPoint.zero, size: sourceImage.size))
    
    let context = UIGraphicsGetCurrentContext()
    context?.setBlendMode(CGBlendMode.normal);
    
    
    image.draw(in: CGRect(x: 0,y: 0, width: sourceImage.size.width, height: sourceImage.size.height), blendMode: CGBlendMode.normal, alpha: 1.0)
    let newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext()

    return newImage!
  }
  
}
