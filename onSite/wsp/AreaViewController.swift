//
//  AreaViewController.swift
//  wsp
//
//  Created by Jon Harding on 2015-07-29.
//  Copyright (c) 2015 Ubriety. All rights reserved.
//

import UIKit
import CoreData


class AreaViewController: Page, NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate {
  
  let doubleTapZoomScale: CGFloat = 2
  
  let manager: Manager = Manager.sharedInstance
  
  var thisAreaFrc: NSFetchedResultsController<NSFetchRequestResult>?
  
  var project: Project!
  var areaRect: CGRect!
  var areaZoom: CGFloat!
  var scale: CGFloat = 1
  
  @IBOutlet weak var imageViewTopLayoutGuide: NSLayoutConstraint!
  @IBOutlet weak var imageViewBottomLayoutGuide: NSLayoutConstraint!
  @IBOutlet weak var pillRackBackgroundView: UIView!
  
  
  @IBOutlet weak var recentlyUsedLabel: UILabel!
  @IBOutlet weak var recentlyUsedTrailingSpace: NSLayoutConstraint!
  
  
  @IBOutlet weak var lockedLabel: UILabel!
  @IBOutlet weak var lockedLabelTrailingSpace: NSLayoutConstraint!
  
  
  @IBOutlet weak var copiedLabel: UILabel!
  @IBOutlet weak var copiedLabelTrailingSpace: NSLayoutConstraint!
  
  
  var issueViewCache: IssueViewCache!
  var dragViewCache: DragViewCache!
  
  var heightAdjustmentForImageView: CGFloat {
    get {
      return self.imageViewTopLayoutGuide.constant
    }
  }
  
  var bottomAdjustmentForImageView: CGFloat {
    get {
      return self.imageViewBottomLayoutGuide.constant
    }
  }
  
  var area: Area? {
    get {
      return self.pages.area
    }
  }
  var issue: Issue? {
    get {
      return self.pages.issue
    } set {
      self.pages.issue = newValue
      if let issue = self.moveIssue {
        issue.moveDidCancel()
      }
      if let issue = self.moveArrow {
        issue.moveDidCancel()
      }
    }
  }

  var filter : Filter {
    return self.pages.filter
  }

  weak var pages: PagesViewController!
  
  weak var activeIssue: IssueView?
  weak var selectedIssue: IssueView?
  
  var drag: DragView? {
    didSet {
      self.redrawArrows()
    }
  }
  var moveIssue: IssueView? {
    didSet {
      self.redrawArrows()
    }
  }
  
  var moveArrow: ArrowHandleView? {
    didSet {
      self.redrawArrows()
    }
  }
  var issues: [Issue]?

  var imageCache: IssueImageCache {
    get {
      return self.issueViewCache.issueImageCache
    }
  }
  
  
  @IBOutlet weak var invisibleAnchor: UIButton!
  @IBOutlet weak var invisibleAnchorSizeConstraint: NSLayoutConstraint!
  
  @IBOutlet weak var main: UIView!
  @IBOutlet weak var empty: UIView!
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var scrollView: AreaScrollView!
  @IBOutlet var rec: UIPanGestureRecognizer!
  @IBOutlet weak var issueButtonPlaceholderImageView: UIImageView!
  @IBOutlet weak var issueButtonPlaceholder: UIView!
  
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var pills: UIView!
  @IBOutlet weak var handles: UIView!
  @IBOutlet weak var arrows: ArrowView!
  @IBOutlet weak var pillRack: UIView!
  
  @IBOutlet weak var contentHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var contentWidthConstraint: NSLayoutConstraint!
  
  
  @IBOutlet weak var noAreaLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.issueViewCache = IssueViewCache(withParentView: self.pills, andAVC: self, andArrowView: self.handles)
    self.dragViewCache = DragViewCache(withParentView: self.pillRack, andAVC: self, andImageCache: self.issueViewCache.issueImageCache)
    
    self.pos = 0
    self.rec.maximumNumberOfTouches = 1
    
    let contentInset = UIEdgeInsetsMake(0,0,150,0)
    self.scrollView.contentInset = contentInset
    self.scrollView.pages = self.pages
    
    self.invisibleAnchorSizeConstraint.constant = Config.speedrackSize
    self.arrows.avc = self
    
    let tapRec = UITapGestureRecognizer(target: self, action:#selector(AreaViewController.handleTap(_:)))
    tapRec.delegate = self
    tapRec.numberOfTapsRequired = 1
    self.view.addGestureRecognizer(tapRec)

    self.main.isHidden = true
    self.empty.isHidden = true

  }

  @objc func handleTap(_ rec: UITapGestureRecognizer) {
    if self.moveIssue != nil {
      self.moveDidEnd()
    } else if self.moveArrow != nil {
      self.arrowDidEnd(self.moveArrow!.center)
    }
    
    if self.issue != nil {
      self.issue = nil
    }
  }
  
  func updateSelectedIssue() {
    
    self.selectedIssue?.unfocus()
    
    if let issue = self.issue {
      if let matching =  self.issueViewCache.findIssueViewWithIssue(issue) {
        self.selectedIssue = matching
      }
      self.selectedIssue?.focus()
      
    } else {
      self.selectedIssue?.unfocus()
      self.selectedIssue = nil
    }
    
    self.redrawArrows()
    
  }
  
  override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
    self.scrollView.zoom(to: CGRect(x: 0, y: 0, width: self.scrollView.frame.width, height: self.scrollView.frame.height), animated: false)
  }
  
  func fetch() {
    if let area = self.area {
      var pred = NSPredicate(format: "area = %@", area)
      
      if let filter = self.filter.issuePredicate {
        pred = NSCompoundPredicate(andPredicateWithSubpredicates: [filter, pred])
      }
      
      self.issues = Issue.mr_findAllSorted(by: "createdDate", ascending: true, with: pred) as? [Issue]
      
    }
  }
 
  var drawLighter: Bool {
    get {
      let issueSelected =  self.issueViewCache.movingIssue != nil || self.moveArrow != nil || self.drag != nil
      if Config.fadeOnSelection {
        return issueSelected || self.issue != nil
      } else {
        return issueSelected
      }
    }
  }
  
  var hideDragIssues: Bool {
    get {
      return self.issueViewCache.movingIssue != nil || self.moveArrow != nil || self.drag != nil
    }
  }
  
  func darkerIssue(_ issue: Issue) -> Bool {
    
    if issue == self.issueViewCache.movingIssue {
      return true
    }
    
    if issue == self.moveArrow?.issue {
      return true
    }
    
    if Config.fadeOnSelection && issue == self.issue {
      return true
    }
    
    return false
    
  }
  
  func refreshArea() {


    if self.area != nil {
      self.loadArea()
      
    } else {
      self.showNoAreaScreen()
    }
  }
  
  func showNoAreaScreen() {
    
    let numberOfAreas = Area.mr_countOfEntities(with: NSPredicate(format: "project = %@", self.project))
    
    if numberOfAreas == 0 {
      self.noAreaLabel.text = NSLocalizedString("No areas have been defined", comment: "No areas have been defined")
      
    } else {
      self.noAreaLabel.text = NSLocalizedString("No area selected", comment: "No area selected")
      
    }
    
    self.main.isHidden = true
    self.empty.isHidden = false
    
    
  }
  
  func resizeContentForImage(_ image: UIImage, cb:(()->())? = nil) {
    
    let nonImageHeight: CGFloat = self.heightAdjustmentForImageView + self.bottomAdjustmentForImageView
    let size = image.size
    let frameSize = self.view.frame.size
    
    let imageAspect = size.width / size.height
    let frameAspect = frameSize.width / frameSize.height
    
    var height: CGFloat!
    var width: CGFloat!
    
    // image is wider
    if imageAspect >= frameAspect {
      height = frameSize.height
      width = imageAspect * height
      
      // image is taller
    } else {
      width = frameSize.width
      height = width / imageAspect
    }
    
    
    self.contentHeightConstraint.constant = height + nonImageHeight
    self.contentWidthConstraint.constant = width

    self.scrollView.setZoomScale(1, animated: false)
    self.scrollView.setContentOffset(CGPoint.zero, animated: false)

    self.imageView.setNeedsUpdateConstraints()
    self.pills.setNeedsUpdateConstraints()
    self.arrows.setNeedsUpdateConstraints()
    self.contentView.setNeedsUpdateConstraints()
    self.imageView.setNeedsDisplay()
    

    self.delay(0.1) {
      self.resize()
      cb?()
    }
  }
  
  func loadArea() {

    self.empty.isHidden = true
    self.main.isHidden = false
    
    self.view.alpha = 0
    self.arrows.project = self.project
    self.arrows.area = self.area
    self.issueViewCache.removeAllIssues()
    if let area = self.area, let image = area.image {
      
      self.resizeContentForImage(image) {
        self.imageView.image = image
        self.fetch()
        self.renderIssues()
        self.updateSelectedIssue()
        Manager.sharedInstance.stopActivity()
      }
    } else {
      Manager.sharedInstance.stopActivity()
    }
    
  }
  
  func renderIssues() {
    
    self.issueViewCache.removeAllIssues()
    self.dragViewCache.updateAnchors()
    self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    self.resize()
    self.areaZoom = self.calculateImageZoom(self.imageView)
    self.areaRect = self.calculateClientRectOfImageInUIImageView(self.imageView, zoom: self.areaZoom)
    
    if let i = self.issues {
      for obj in i {
        if !obj.isDeleted {
          self.loadIssue(obj)
        }
      }
      self.redrawArrows()
    }
    
    self.updateIssueLocations(true)
    UIView.animate(withDuration: 0.1, delay: 0, options: UIViewAnimationOptions(), animations: {
      self.view.alpha = 1
      }, completion: nil)
    
  }
  
  func loadIssue(_ issue: Issue) {
    let issueView = self.issueViewCache.addIssue(self.project, issue: issue, area: self, areaRect: areaRect, zoom: areaZoom, originalSize: self.imageView.image!.size)
    issueView.delegate = self
    
    
  }
  
  func startDrag(_ aDragView: DragView) {
    if (self.issue != nil ) { self.issue = nil }
    self.drag = aDragView
    self.activeIssue = nil
  }
  
  func startMove(_ issueView: IssueView) {
    
    
    self.scrollView.isScrollEnabled = false
    issueView.moveDidStart()
    self.moveIssue = issueView
  }
  
  func arrowPositionUpdated(_ position: Position) {
    
    self.redrawArrows()
    
  }
  
  func enterArrowMode(_ issue: Issue) {
    
    if let arrow = self.issueViewCache.arrowViewForIssue(issue) {
      self.moveArrow = arrow
      let bottomSpace = self.view.frame.height - arrow.frame.origin.y - arrow.frame.size.height/2
      self.moveArrow!.enterArrowMode(withBottomSpace: bottomSpace)
      
    } else {
      Config.error("Couldn't find issue views!")
    }
    
  }
  
  func moveDidEnd() {
    self.scrollView.isScrollEnabled = true
    
    self.areaZoom = self.calculateImageZoom(self.imageView)
    self.areaRect = self.calculateClientRectOfImageInUIImageView(self.imageView, zoom: self.areaZoom)
    self.moveIssue?.moveDidEnd(self.moveIssue!.center, areaRect: self.areaRect, zoom: self.areaZoom, originalSize: self.imageView.image!.size)
    self.moveIssue = nil
    
  }
  
  func startArrow(_ issueView: IssueView) {
    self.scrollView.isScrollEnabled = false
    issueView.startArrow()
  }
  
  func arrowDidEnd(_ pos: CGPoint) {
    self.scrollView.isScrollEnabled = true
    self.moveArrow?.moveDidEnd(pos)
    self.moveArrow?.issue.setModified()
    self.manager.saveCurrentState(nil)
    self.moveArrow = nil
    
  }
  
  func dragDidEnd(_ pos: CGPoint) {
    if let drag = self.drag {
      let areaPosition = self.calcPositionFromAreaView(pos)
      if !self.area!.positionInArea(areaPosition) {
        self.resetIssueButton(false, cb: nil)
        self.drag!.handle.isHidden = true
        self.drag!.dragDidCancel()
        self.drag = nil
        return
        
      }
      if drag.aTag == nil {
        if self.activeIssue == nil {
          let issue = self.addIssue(pos)
          self.activeIssue = issue
          self.activeIssue?.isHidden = true
        }
        self.performSegue(withIdentifier: "ShowLibrary", sender: self)
      } else {
        drag.shrink {
          let issueView = self.addIssue(pos, copyingCollection: drag.aTag!.tagsCollection)
          
          if drag.mode == .copied {
            issueView.issue.copyCommentsFromIssue(drag.aTag!)
            issueView.issue.createdDate = drag.aTag!.createdDate
            drag.finishedCopying()
          }
          
          self.activeIssue = issueView
          
          issueView.update(nil)
          issueView.isHidden = false
          issueView.issue.setModified()
          self.manager.saveCurrentState(nil)

          drag.isHidden = true
          self.drag = nil
          self.activeIssue = nil
          self.issues?.append(issueView.issue)
          self.issue = issueView.issue
          self.pages.rootView.nav.autoComments()
        }
      }
    }
  }
  
  func addIssue(_ pos: CGPoint, copyingCollection: TagCollection? = nil) -> IssueView {
    
    let areaPosition = self.calcPositionFromAreaView(pos)
    let originX = areaPosition.x
    let originY = areaPosition.y
    
    let issue = Issue.mr_createEntity()!
    issue.user = self.manager.getCurrentUser()
    issue.issueNumber = Issue.getNextIssueNumberForProject(self.project)
    issue.area = self.area!
    issue.setModified()
    
    if let cp = copyingCollection {
      issue.copyFromTagCollection(cp)
    }
    
    let position = Position.mr_createEntity()!
    position.x = originX as NSNumber
    position.y = originY as NSNumber
    position.markerX = position.x
    position.markerY = position.y
    position.issue = issue
    position.setModified()
    
    let issueView = self.issueViewCache.addIssue(self.project, issue: issue, area: self, areaRect: areaRect, zoom: areaZoom, originalSize: self.imageView.image!.size)
    issueView.delegate = self
    issueView.position = position
    
    issueView.isHidden = true
    
    return issueView
    
  }
  
  func calcPositionFromAreaView(_ pos: CGPoint) -> CGPoint {
    var pos = pos
    
    self.areaZoom = self.calculateImageZoom(self.imageView)
    self.areaRect = self.calculateClientRectOfImageInUIImageView(self.imageView, zoom: self.areaZoom)
    
    pos.x = pos.x + self.scrollView.contentOffset.x
    pos.y = pos.y + self.scrollView.contentOffset.y
    pos.y -= 88
    
    let originX = (pos.x - self.areaRect.origin.x) * (self.imageView.image!.size.width) / self.areaRect.width
    let originY = (pos.y - self.areaRect.origin.y) * (self.imageView.image!.size.height) / self.areaRect.height
    
    
    return CGPoint(x: originX, y: originY)
    
  }
  
  func removeIssue() {
    // removing issue
    
    self.resetIssueButton(true) {
      self.drag!.handle.isHidden = true
      self.drag!.dragDidEnd(false)
      self.drag = nil
      if self.issueViewCache.count != 0 {
        self.activeIssue?.isHidden = true
        self.issueViewCache.removeLastAddedIssue()

        self.activeIssue?.issue.removeWithFiles()
        self.activeIssue = nil
      }
    }
  }
  
  func cancelIssue() {
    self.removeIssue()
    self.activeIssue = nil
  }
  
  func resetIssueButton(_ withAdjustingFrame: Bool, cb: (() -> ())?) {
    
    let yAdjust: CGFloat = withAdjustingFrame ? self.drag!.handle.frame.origin.y : 0
    
    UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
      self.drag!.center = CGPoint(x: self.drag!.anchor.x + self.drag!.size/2, y: self.drag!.anchor.y + self.drag!.size/2 - yAdjust)
      }, completion: { finished in
        cb?()
    })
    
  }
  
  @IBAction func pan(_ rec: UIPanGestureRecognizer) {
    
    var pos = rec.location(in: self.view)
    
    var movingView: IssueBaseView!
    var term: ((CGPoint) -> ())!
    var adjustForScroll = true
    let heightAdjust:CGFloat = -88
    var adjustPointOnArea = true
    
    if self.drag != nil {
      self.drag!.dragDidStart()
      
      movingView = self.drag!
      
      term = { (pos: CGPoint) in
        var pos = pos
        pos.y -= self.heightAdjustmentForImageView
        self.dragDidEnd(pos)
      }
      adjustForScroll = false
      adjustPointOnArea = false
      
    } else if self.moveIssue != nil {
      
      guard self.moveIssue!.tapped == true else {
        return
      }
      
      movingView = self.moveIssue!
      term = { (pos: CGPoint) in
        self.moveDidEnd()
      }
      
    } else if self.moveArrow != nil {
      
      movingView = self.moveArrow!
      term = { (pos: CGPoint) in
        self.arrowDidEnd(pos)
      }
      
    } else {
      return
    }
    
    let issueSize = Config.draggingHandleSize
    
    let minX = issueSize  / 2
    let maxX = self.view.frame.width - issueSize / 2
    if pos.x < minX {
      pos.x = minX
    } else if pos.x > maxX {
      pos.x = maxX
    }
    let minY = issueSize / 2 - movingView.offset + movingView.draggingOffset
    let maxY = self.view.frame.height - issueSize / 2
    if pos.y < minY {
      pos.y = minY
    } else if pos.y > maxY {
      pos.y = maxY
    }
    
    pos.y += heightAdjust
    var adjPos = pos
    adjPos.x = pos.x + self.scrollView.contentOffset.x
    adjPos.y = pos.y + self.scrollView.contentOffset.y
    
    var pointOnArea = self.pointOnAreaForZoomAndPan(adjPos, withAdjust: adjustForScroll)
    if adjustPointOnArea {
      pointOnArea = self.area!.issuePositionInArea(pointOnArea)
    }
    var pointOnScreen = self.pointOnScreenForZoomAndPan(pointOnArea, withAdjust: adjustForScroll)
    
    if !adjustForScroll {
      pointOnScreen.x -= self.scrollView.contentOffset.x
      pointOnScreen.y -= self.scrollView.contentOffset.y
    }
  
    pointOnScreen.y -= heightAdjust
    
    let centerOnScreen = pointOnScreen
    
    movingView.center = centerOnScreen
    movingView.move(centerOnScreen)
    if rec.state == .ended {
      term(centerOnScreen)
    }
    
  }
  
  func resize() {
    if self.area != nil {
      self.updateIssueLocations(true)
      self.dragViewCache.updateAnchors()
    }
  }
  
  func updateIssueLocations(_ forced: Bool = false) {
    if self.area != nil {
      let zoom = self.calculateImageZoom(self.imageView)
      if self.areaZoom == zoom  && !forced {
        return
      }
      self.areaZoom = zoom
      if self.areaZoom != nil {
        self.areaRect = self.calculateClientRectOfImageInUIImageView(self.imageView, zoom: self.areaZoom)
        self.issueViewCache.updateIssueLocations(self.areaRect, areaZoom: self.areaZoom)
      }
      self.redrawArrows()
    }
  }
  
  func updateIssueLabels() {
    self.issueViewCache.updateIssueLabels()
    if let image = self.imageView.image {
      self.arrows.redraw(self.areaRect, originalSize: image.size, issues: self.issues)
    }
  }
  
  func updateFrames() {
    self.arrows.frame = self.imageView.frame
    self.handles.frame = self.imageView.frame
    self.pills.frame = self.imageView.frame
    self.redrawArrows()
  }
  
  func showIssueMenuPopover(_ issueView: IssueView) {
    
    if self.presentedViewController != nil {
      return
    }
    
    self.issue = issueView.issue
    
    self.performSegue(withIdentifier: "IssueMenuSegue", sender: self)
    
  }
  
  func showIssues() {
    self.issueViewCache.showIssues()
    self.arrows.isHidden = false
    self.dragViewCache.showViews()
    
  }
  
  func hideIssues() {
    self.issueViewCache.hideIssues()
    self.arrows.isHidden = true
    self.dragViewCache.hideViews()
    
  }
  
  func redrawArrows() {
    
    if let image = self.imageView.image {
      
      self.arrows.redraw(self.areaRect, originalSize: image.size, issues: self.issues)
      self.issueViewCache.redrawIssueLighterOrDarker()
      self.dragViewCache.redrawDragHiddenOrNot()
      
    }
    
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    DispatchQueue.main.async {
      self.resize()
      self.delay(0.1, closure: {
        if let image = self.area?.image {
          self.resizeContentForImage(image) {
          }
        }
      })
    }
    self.presentedViewController?.dismiss(animated: false, completion: nil)
    
  }
  
  func pointOnAreaForZoomAndPan( _ point: CGPoint, withAdjust: Bool) -> CGPoint {
    var point = point
    
    point.x = (point.x - self.areaRect.origin.x)  / self.areaZoom
    if !withAdjust {
      point.y -= self.heightAdjustmentForImageView
    }
    point.y = (point.y - self.areaRect.origin.y) / self.areaZoom
    
    return point
    
  }
  
  func pointOnScreenForZoomAndPan( _ point: CGPoint, withAdjust: Bool) -> CGPoint {
    var point = point
    
    point.x = (point.x * self.areaZoom) + self.areaRect.origin.x
    point.y = (point.y * self.areaZoom) + self.areaRect.origin.y
    if !withAdjust {
      point.y += self.heightAdjustmentForImageView
    }
    
    return point
    
  }
  
  
  func calculateImageZoom(_ image: UIImageView) -> CGFloat? {
    if let uiImage = image.image {
      let imgViewSize = image.frame.size
      let imgSize = uiImage.size
      
      // Calculate the aspect, assuming imgView.contentMode==UIViewContentModeScaleAspectFit
      let scaleW = imgViewSize.width / imgSize.width
      let scaleH = imgViewSize.height / imgSize.height
      return fmin(scaleW, scaleH)
    }
    
    return nil
    
  }
  
  func calculateClientRectOfImageInUIImageView(_ image: UIImageView, zoom: CGFloat) -> CGRect {
    let imgViewSize = image.frame.size
    let imgSize = image.image!.size
    
    let x = (imgViewSize.width - imgSize.width * zoom) / 2 + (self.imageView.frame.origin.x)
    let y = (imgViewSize.height - imgSize.height * zoom) / 2 + (self.imageView.frame.origin.y) - self.heightAdjustmentForImageView
    
    let imageRect = CGRect(x: x, y: y, width: imgSize.width * zoom, height: imgSize.height * zoom)
    
    return imageRect
    
  }
  
  func adjustMapForIssue(_ issue: Issue) {
    
    guard let issueView = self.issueViewCache.findIssueViewWithIssue(issue) else {
      return
    }
    
    let x = issueView.frame.origin.x / self.areaZoom
    let y = issueView.frame.origin.y / self.areaZoom
   
    let clientWidth = self.areaRect.size.width / self.areaZoom / 2
    let clientHeight = self.areaRect.size.height / self.areaZoom / 2
    
    self.scrollView.zoom(to: CGRect(x: x - clientWidth, y: y - clientHeight,  width: 2 * clientWidth , height: 2 * clientHeight), animated: false)
    
  }
  
  
  @IBAction func doubleTap(_ rec: UITapGestureRecognizer) {
    
    if self.scrollView.zoomScale == 1.0 {
      let point = rec.location(in: self.scrollView)
      
      let w = self.scrollView.frame.width/self.doubleTapZoomScale
      let h = self.scrollView.frame.height/self.doubleTapZoomScale
      let x = point.x - (w/2)
      let y = point.y - (h/2)
      
      self.scrollView.zoom(to: CGRect(x: x, y: y, width: w, height: h), animated: true)
      
    } else {
      
      let point = rec.location(in: self.scrollView)
      
      let w = self.scrollView.frame.width
      let h = self.scrollView.frame.height
      let x = point.x - (w/2)
      let y = point.y - (h/2)
      
      self.scrollView.zoom(to: CGRect(x: x, y: y, width: self.scrollView.frame.width, height: self.scrollView.frame.height), animated: true)
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier! == "ShowLibrary" {
      
      if self.drag != nil {
        
        self.invisibleAnchor.center = self.activeIssue!.center
        self.invisibleAnchor.center.y += self.heightAdjustmentForImageView
        
        if let libraryPopover = segue.destination as? LibraryPopover {
          libraryPopover.popoverPresentationController?.sourceRect = libraryPopover.popoverPresentationController!.sourceView!.bounds
          libraryPopover.delegate = self
          libraryPopover.project = self.project
          libraryPopover.imageCache = self.imageCache
        }
      self.drag!.shrink(nil)
      }
    
    } else if segue.identifier == "IssueMenuSegue" {
      
      self.invisibleAnchorSizeConstraint.constant = self.selectedIssue!.size
      self.invisibleAnchor.center = self.selectedIssue!.center
      self.invisibleAnchor.center.y += self.heightAdjustmentForImageView
      
      let issueMenuPopover = segue.destination as! IssueMenuTableViewController
      issueMenuPopover.popoverPresentationController?.sourceRect = issueMenuPopover.popoverPresentationController!.sourceView!.bounds
      issueMenuPopover.issueView = self.selectedIssue!
      issueMenuPopover.delegate = self
    }
  }
  
  
}

extension AreaViewController: UIScrollViewDelegate {
  
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return self.imageView
  }
  
  func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
    self.arrows.isHidden = true
  }
  
  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    self.updateIssueLocations()
  }
  
  func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
    self.updateFrames()
    self.arrows.isHidden = false
  }
  
}

extension AreaViewController: CategoryPopoverDelegate {
  
  func tagDidCancel() { self.removeIssue() }
  
  func tagDidSet(_ tagCollection: TagCollection) {
    if let issueView = self.activeIssue {
      issueView.isHidden = false
      issueView.update(tagCollection)
      issueView.issue.setModified()
      self.manager.saveCurrentState(nil)
      self.issues?.append(issueView.issue)
      self.activeIssue = nil
      self.drag = nil
      self.issue = issueView.issue
    }
    self.pages.rootView.nav.autoComments()
    self.updateIssueLocations()
  }
  
  func tagDidChange(_ tagCollection: TagCollection?) {
    
    if tagCollection == nil {
      self.drag?.isHidden = false
      self.activeIssue?.isHidden = true
    } else {
      self.drag?.isHidden = true
      self.activeIssue?.isHidden = false
      self.activeIssue?.update(tagCollection!)
    }
  }
  
  func filterByTag(_ tagCollection: TagCollection) { }

  func filterByAggregate(_ filter: AggregateFilter) { }
  
}

extension AreaViewController: IssueViewDelegate {
  
  func issueDidLongPress(_ issueView: IssueView) { }
  
  func issueDidLoseFocus(_ issueView: IssueView) { }
  
  
}

extension AreaViewController: IssueMenuViewControllerDelegate {
  
  func deletedIssue(_ issue: Issue, renumbering: Bool) {
    
    if self.issues == nil {
      Config.error("Called with no issues defined??")
      return
    }
    
    if let index = self.issues!.index( where: {$0 == issue} ){
      self.issues?.remove(at: index)
    } else {
      Config.error("Couldn't find issue in issues list?")
    }
    
    self.issueViewCache.removeViewWithIssue(issue)
    
    if renumbering {
      self.issueViewCache.updateIssueLabels()
    }
    
    self.activeIssue = nil
    self.issue = nil
    
  }
  
  func relabeledIssue(_ issue: Issue?) {
    
    self.pages.rootView.updateActiveIssueLabel()
    
  }
}
