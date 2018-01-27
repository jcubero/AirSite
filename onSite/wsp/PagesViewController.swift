//
//  Pages.swift
//  wsp
//
//  Created by Jonathan Harding on 2015-07-30.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit

protocol PagesViewControllerDelegate: class {
  func toggleNav()
}

class PagesViewController: UIViewController, SCPageViewControllerDataSource, SCPageViewControllerDelegate, ActiveFilterProtocol {

//  var weakPages: [WeakContainer<UIViewController>]!
  var pages: [UIViewController]!
  weak var pageViewController: SCPageViewController!
  
  weak var rootView: ProjectSplitView!
  var project: Project!
  
  var form: Form? {
    get {
      return self.rootView.activeForm
    }
  }
  
  var area: Area? {
    get {
      return self.rootView.activeArea
    } set {
      self.rootView.activeArea = newValue
    }
  }
  var issue: Issue? {
    get {
      return self.rootView.activeIssue
    } set {
      self.rootView.activeIssue = newValue
    }
  }

  var filter: Filter {
    return self.project.filter
  }
  
  weak var delegate: PagesViewControllerDelegate?
  
  weak var areaView: AreaViewController?
  weak var issues: Issues?
  weak var photos: Photos?
  let toggleWidth: CGFloat = 25
  
  weak var formNavController: UINavigationController?
  
  var initialRun = true
  var commentPageController: CommentPageViewController!
  
  @IBOutlet weak var containerLeftConstraint: NSLayoutConstraint!
  @IBOutlet weak var toggleWidthConstraint: NSLayoutConstraint!
  
  @IBOutlet weak var swipingView: UIView!
  
  @IBOutlet weak var areaControllerContainer: UIView!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(PagesViewController.swipeRight(_:)))
    swipeRight.direction = .right
    self.swipingView.addGestureRecognizer(swipeRight)
    
  }
  
  func load() {

    let av = UIStoryboard(name: "Area", bundle: nil).instantiateInitialViewController() as! AreaViewController
    areaView = av
    av.project = self.project
    av.pages = self

    let iv = UIStoryboard(name: "Issues", bundle: nil).instantiateInitialViewController() as! Issues
    issues = iv
    iv.pages = self
    
    let pv = UIStoryboard(name: "Photos", bundle: nil).instantiateInitialViewController() as! Photos
    photos = pv
    pv.pages = self

    self.pages = [av, iv, pv]
    
    self.pageViewController.delegate = self
    self.pageViewController.dataSource = self
    
    self.pageViewController.scrollView.minumumNumberOfTouches = 2
    
    let layouter = SCPageLayouter()
    layouter.navigationType = .vertical
    self.pageViewController.setLayouter(layouter, andFocusOn: 0, animated: false, completion: nil)
    self.pageViewController.reloadData()
    self.pageViewController.scrollView.bounces = false

    self.commentPageController = CommentPageViewController()
    self.commentPageController.parent = self
  
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    
    super.viewWillAppear(animated)
    
    if initialRun {
      initialRun = false
      self.navDidShow()
    }
    
    
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if let vc = segue.destination as? SCPageViewController {
      self.pageViewController = vc
    }
  }
  
  
  func numberOfPages(in pageViewController: SCPageViewController!) -> UInt {
    return UInt(self.pages.count)
  }
  
  func pageViewController(_ pageViewController: SCPageViewController!, viewControllerForPageAt pageIndex: UInt) -> UIViewController! {
    
    let index = Int(pageIndex)
    return self.pages[index]
    
  }
  
  func pageViewController(_ pageViewController: SCPageViewController!, didShow controller: UIViewController!, at index: UInt) {
    
  }
  
  
  func showCommentImageEditor(_ comment: Comment) {
    
    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    let vc = storyboard.instantiateViewController(withIdentifier: "EditCommentImageViewController") as! EditCommentImageViewController
    vc.modalPresentationStyle = UIModalPresentationStyle.formSheet
    vc.comment = comment
    self.rootView.present(vc, animated: false, completion: nil)
    
  }

  func showCommentImagesWithComment(_ comment: Comment, amongComments: [Comment]) {
    commentPageController.createWithComment(comment, withComments: amongComments)

  }

  override var preferredStatusBarStyle : UIStatusBarStyle {
    return UIStatusBarStyle.lightContent
    
  }
  
  func loadArea() {
    self.areaView?.refreshArea()
    self.photos?.fetch()
    self.issues?.fetch()
  }
  
  
  func updateActiveIssue() {
    self.areaView?.updateSelectedIssue()
    self.issues?.updateSelectedIssue()

    
  }
  
  func updateActiveIssueLabel() {
    
    self.areaView?.updateIssueLabels()
  }

  func filterUpdated(_ filter: Filter) {
    self.issues?.fetch()
    self.areaView?.fetch()
    self.areaView?.renderIssues()
    self.photos?.fetch()

  }

  func loadForm() {
    
  
    if let form = self.form {

      let pdfVC = FormViewController()
      pdfVC.document = form.document
      pdfVC.pagesViewController = self
      form.loadDataInto(pdfVC.document!)

      let nav = FormNavigationController(rootViewController: pdfVC)
      nav.view.autoresizingMask =  [.flexibleHeight, .flexibleWidth, .flexibleTopMargin, .flexibleBottomMargin]
      nav.navigationBar.isTranslucent = false
      nav.navigationBar.barTintColor = UIColor.wspNeutral()
      nav.modalPresentationStyle = .fullScreen
      
      let saveBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Done", comment: "Done"), style: .plain, target: self, action: #selector(PagesViewController.finishedUpdatingForm(_:)))
      saveBarButtonItem.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: UIControlState())
      pdfVC.navigationItem.rightBarButtonItems = [saveBarButtonItem]
      
      present(nav, animated: true, completion: nil)

      formNavController = nav

    }
  }
  
  @objc func finishedUpdatingForm(_ sender: AnyObject) {
    
    
    guard let pdfVc = formNavController?.visibleViewController as? ILPDFViewController else {
      Config.error()
      return
    }
    
    guard let form = self.form else {
      Config.error()
      return
    }
    
    form.document = pdfVc.document!
    Manager.sharedInstance.saveCurrentState(nil)
    
    formNavController?.dismiss(animated: true, completion: nil)
    formNavController = nil
    
    
  }
  
  func searchBarDidHide() {
    self.areaView?.refreshArea()
    
  }
  
  func jumpToIssueOnMap(_ issue: Issue) {
    
    self.issue = issue
    
    if self.area != issue.area {
      self.area = issue.area
    }
    
    self.pageViewController.navigateToPage(at: 0, animated: true, completion: nil)
    self.delay(0.1) { [unowned self] in
      self.areaView?.adjustMapForIssue(issue)
    }
    
  }
  
}

extension PagesViewController {
  
  func navModeWillChange() {
    if let areaView = self.areaView {
      self.areaView?.hideIssues()
      areaView.scrollView.zoom(to: CGRect(x: 0, y: 0, width: areaView.scrollView.frame.width, height: areaView.scrollView.frame.height), animated: false)
    }
  }
  
  func navModeDidChange() {
    self.areaView?.resize()
    self.areaView?.showIssues()
  }
  
  func navDidHide() {
    self.containerLeftConstraint.constant = -20 + toggleWidth
    self.toggleWidthConstraint.constant = toggleWidth
    self.resizeAreaViewContent()
  }
  
  func navDidShow() {
    self.containerLeftConstraint.constant = -20
    self.toggleWidthConstraint.constant = 0
    self.resizeAreaViewContent()
  }
  
  
  func resizeAreaViewContent() {
    
    self.delay(0.1, closure: { [unowned self] in
      if let image = self.area?.image {
        self.areaView?.resizeContentForImage(image) {
          
        }
      }
    })
  }
  
  
  @objc func swipeRight(_ sender: AnyObject) {
    self.delegate?.toggleNav()
  }
  
  @IBAction func toggleButtonPressed(_ sender: AnyObject) {
    self.rootView.shouldNavHide = false
    self.delegate?.toggleNav()
    
  }
  
}

extension PagesViewController: CommentImageViewControllerDelegate {

  func didPressIssuetLabel(_ issue: Issue) {

    self.jumpToIssueOnMap(issue)

  }

}
