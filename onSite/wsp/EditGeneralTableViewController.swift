//
//  EditGeneralTableViewController.swift
//  wsp
//
//  Created by Jon Harding on 2015-09-20.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

class EditGeneralTableViewController: UITableViewController {
  
  @IBOutlet weak var projectTitle : UITextField!
  @IBOutlet weak var projectSubTitle: UITextField!
  @IBOutlet weak var projectClient: UITextField!
  @IBOutlet weak var projectBuilding: UITextField!
  @IBOutlet weak var projectAddress: UITextField!
  @IBOutlet weak var projectDate: UITextField!
  @IBOutlet weak var userName: UITextField!
  @IBOutlet weak var userCompany: UITextField!
  
  @IBOutlet weak var companyAddress1: UITextField!
  @IBOutlet weak var companyAddress2: UITextField!
  @IBOutlet weak var companyPhone: UITextField!
  @IBOutlet weak var companyFax: UITextField!
  @IBOutlet weak var companyEmail: UITextField!
  
  @IBOutlet weak var documentType: UITextField!
  @IBOutlet weak var projectNumber: UITextField!
  
  @IBOutlet weak var imageButton : UIButton!
  @IBOutlet weak var buildingButton: UIButton!
  
  @IBOutlet weak var buildingName : UITextField!
  @IBOutlet weak var buildingAddress: UITextField!

  @IBOutlet weak var openCameraSwitch: UISwitch!
  @IBOutlet weak var openCommentsSwitch: UISwitch!
  @IBOutlet weak var pillSlider: UISlider!
  
  @IBOutlet weak var photoQuality: UISegmentedControl!
  @IBOutlet weak var photosPerPageLandscape: UISegmentedControl!
  @IBOutlet weak var photosPerPagePortrait: UISegmentedControl!
  @IBOutlet weak var photoPageOrientation: UISegmentedControl!
  @IBOutlet weak var embedPhotoDataSwitch: UISwitch!
  @IBOutlet weak var autoSavePhotosSwitch: UISwitch!
  
  @IBOutlet weak var planPageSize: UISegmentedControl!
  @IBOutlet weak var planPageOrientation: UISegmentedControl!
  
  @IBOutlet weak var pillValue: UILabel!
  
  let manager : Manager = Manager.sharedInstance
  fileprivate var imagePicker: ImagePicker?
  
  var deleted = false
  
  var project: Project? {
    didSet {
      
      if let title = self.project?.title {
        self.projectTitle.text = title
      }
      
      if let image = self.project?.image {
        self.imageButton.setImage(image, for: UIControlState())
        self.imageButton.setTitle("", for: UIControlState())
      } else {
        self.imageButton.setImage(nil, for: UIControlState())
      }
      
      if let image = self.project?.buildingImage {
        self.buildingButton.setImage(image, for: UIControlState())
        self.buildingButton.setTitle("", for: UIControlState())
      } else {
        self.buildingButton.setImage(nil, for: UIControlState())
      }
      
      self.projectDate.text = self.project?.date
      
      self.projectSubTitle.text = self.project?.subtitle
      self.projectClient.text = self.project?.client
      
      self.documentType.text = self.project?.documentType
      self.projectNumber.text = self.project?.projectNumber
      
      self.userName.text = self.project?.userNameForReport
      self.userCompany.text = self.project?.userCompanyForReport
      
      self.buildingName.text = self.project?.buildingName
      self.buildingAddress.text = self.project?.buildingAddress
      
      self.companyAddress1.text = self.project?.userCompanyAddress1
      self.companyAddress2.text = self.project?.userCompanyAddress2
      self.companyPhone.text = self.project?.userCompanyPhone
      self.companyFax.text = self.project?.userCompanyFax
      self.companyEmail.text = self.project?.userCompanyEmail
      
    
      
      if let openComments = self.project?.openComments {
        self.openCommentsSwitch.isOn = openComments.boolValue
      }
      
      if let openCamera = self.project?.openCamera {
        self.openCameraSwitch.isOn = openCamera.boolValue
      }
      
      if let pillSize = self.project?.pillSize {
        if pillSize != 0 {
          self.pillSlider.value = pillSize as! Float
        }
      }
      
      self.pillValue.text = String(format: "%.2f", self.pillSlider.value)
      
      if self.project?.photoQuality == 0  {
        self.photoQuality.selectedSegmentIndex = 0
      } else if self.project?.photoQuality == 1 {
        self.photoQuality.selectedSegmentIndex = 1
      } else {
        self.photoQuality.selectedSegmentIndex = 2
      }
      
      if self.project?.photosPerPageLandscape == 1 {
        self.photosPerPageLandscape.selectedSegmentIndex = 0
      } else if self.project?.photosPerPageLandscape == 4 {
        self.photosPerPageLandscape.selectedSegmentIndex = 1
      } else if self.project?.photosPerPageLandscape == 9 {
        self.photosPerPageLandscape.selectedSegmentIndex = 2
      } else {
        self.photosPerPageLandscape.selectedSegmentIndex = 3
      }
      
      if self.project?.photosPerPagePortrait == 2 {
        self.photosPerPagePortrait.selectedSegmentIndex = 0
      } else if self.project?.photosPerPagePortrait == 6 {
        self.photosPerPagePortrait.selectedSegmentIndex = 1
      } else if self.project?.photosPerPagePortrait == 9 {
        self.photosPerPagePortrait.selectedSegmentIndex = 2
      } else {
        self.photosPerPagePortrait.selectedSegmentIndex = 3
      }
      
      if self.project?.photosPageOrientation == "P" {
        self.photoPageOrientation.selectedSegmentIndex = 0
      } else {
        self.photoPageOrientation.selectedSegmentIndex = 1
      }
      
      if self.project?.planPageOrientation == "P" {
        self.planPageOrientation.selectedSegmentIndex = 0
      } else {
        self.planPageOrientation.selectedSegmentIndex = 1
      }
      
      if self.project?.planPageSize == 11 {
        self.planPageSize.selectedSegmentIndex = 0
      } else {
        self.planPageSize.selectedSegmentIndex = 1
      }
      
      
      
      self.embedPhotoDataSwitch.isOn = (self.project?.photoEmbedPills.boolValue)!
      self.autoSavePhotosSwitch.isOn = (self.project?.photoAutoSave.boolValue)!
     
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

        self.tableView.delegate = self;
        self.tableView.dataSource = self;
    
    let parentController = self.parent as! EditProjectTabBarController
    self.project = parentController.project
    
    self.styleImagebutton(self.imageButton!)
    self.styleImagebutton(self.buildingButton!)
    
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 100, 0)
    
  }
  
  @IBAction func pillSizeValueChanged(_ sender: AnyObject) {
    
    self.pillValue.text = String(format: "%.2f", self.pillSlider.value)
    
  }
  
  
  func styleImagebutton(_ button: UIButton) {
    button.layer.cornerRadius = 36
    button.clipsToBounds = true
    button.layer.borderColor = UIColor.wspNeutral().cgColor
    button.layer.borderWidth = 1
    button.imageView!.contentMode = .scaleAspectFill
  }
  
  func styleTextView(_ textView: UITextView) {
    textView.layer.cornerRadius = 6
    textView.layer.borderColor = UIColor(netHex: 0xcdcdcd).cgColor
    textView.layer.borderWidth = 1
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    if !self.deleted {
      if let project = self.project {
        project.title = self.projectTitle.text!
        project.subtitle = self.projectSubTitle.text!
        project.client = self.projectClient.text!
        project.buildingName = self.buildingName.text!
        project.buildingAddress = self.buildingAddress.text!
        
        project.userNameForReport = self.userName.text!
        project.userCompanyForReport = self.userCompany.text!
        
        project.projectNumber = self.projectNumber.text!
        project.documentType = self.documentType.text!
        
        project.userCompanyAddress1 = self.companyAddress1.text!
        project.userCompanyAddress2 = self.companyAddress2.text!
        project.userCompanyPhone = self.companyPhone.text!
        project.userCompanyFax = self.companyFax.text!
        project.userCompanyEmail = self.companyEmail.text!
        
        project.openCamera = self.openCameraSwitch.isOn as NSNumber
        project.openComments = self.openCommentsSwitch.isOn as NSNumber
        project.photoEmbedPills = self.embedPhotoDataSwitch.isOn as NSNumber
        
        project.pillSize = NSNumber(floatLiteral: Double(self.pillSlider.value))
        project.photoAutoSave = self.autoSavePhotosSwitch.isOn as NSNumber
        
        project.date = self.projectDate.text!
        
        // photo quality
        var selectedIndex = self.photoQuality.selectedSegmentIndex
        switch selectedIndex {
        case 0:
          project.photoQuality = 0
        case 1:
          project.photoQuality = 1
        default:
          project.photoQuality = 2
        }
        
        // photos per page landscape
        selectedIndex = self.photosPerPageLandscape.selectedSegmentIndex
        switch selectedIndex {
        case 0:
          project.photosPerPageLandscape = 1
        case 1:
          project.photosPerPageLandscape = 4
        case 2:
          project.photosPerPageLandscape = 9
        default:
          project.photosPerPageLandscape = 12
        }
        
        // photos per page portrait
        selectedIndex = self.photosPerPagePortrait.selectedSegmentIndex
        switch selectedIndex {
        case 0:
          project.photosPerPagePortrait = 2
        case 1:
          project.photosPerPagePortrait = 6
        case 2:
          project.photosPerPagePortrait = 9
        default:
          project.photosPerPagePortrait = 12
        }
        
        // photos per page orientation
        selectedIndex = self.photoPageOrientation.selectedSegmentIndex
        switch selectedIndex {
        case 0:
          project.photosPageOrientation = "P"
        default:
          project.photosPageOrientation = "L"
        }
        
        // plan page orientation
        selectedIndex = self.planPageOrientation.selectedSegmentIndex
        switch selectedIndex {
        case 0:
          project.planPageOrientation = "P"
        default:
          project.planPageOrientation = "L"
        }
        
        // plan page size
        selectedIndex = self.planPageSize.selectedSegmentIndex
        switch selectedIndex {
        case 0:
          project.planPageSize = 11
        default:
          project.planPageSize = 8
        }
        
      }
      project?.setModified()
      manager.saveCurrentState(nil)
    }
    
  }
  
  @IBAction func selectImage(_ sender: UIButton) {
    self.updateImageButton(sender) {
      self.project!.imageData = $0
      if($0 == nil) {
        sender.setTitle(NSLocalizedString("Project Image", comment: "Project Image"), for: UIControlState())
      }
    }
  }
  
  @IBAction func selectBuildingImage(_ sender: UIButton) {
    self.updateImageButton(sender) {
      self.project!.buildingImageData = $0!
      if($0 == nil) {
        sender.setTitle(NSLocalizedString("Alternate Logo", comment: "Alternate Logo"), for: UIControlState())
      }
    }
  }
  
  func updateImageButton(_ sender: UIButton, completion: ((_ data: Data?) -> ())?) {
    
    self.imagePicker = ImagePicker()
    
    let frame = sender.superview!.convert(sender.frame, to: self.view)
    self.imagePicker!.loadImagePickerInViewController(self, location: frame, completion: { data in
      if let image = UIImage(data: data) {
        sender.setImage(image, for: UIControlState())
        sender.setTitle("", for: UIControlState())
        completion?(data)
        
      } else {
        sender.setImage(nil, for: UIControlState())
        completion?(nil)
      }
      self.imagePicker = nil
      
    })
    
  }
  
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    
    let view = UIView(frame: CGRect(x: 0,y: 0, width: tableView.frame.width, height: 50))
    
    view.backgroundColor = UIColor.wspNeutral()
    
    let label = UILabel(frame: CGRect(x: 20, y: 5, width: 400, height: 20))
    label.font = UIFont.boldSystemFont(ofSize: 16)
    label.textColor = UIColor.white
    label.text = self.tableView(tableView, titleForHeaderInSection: section)
    
    view.addSubview(label)
    
    return view
    
    
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    
    return 30.0
    
  }
  
  
}
