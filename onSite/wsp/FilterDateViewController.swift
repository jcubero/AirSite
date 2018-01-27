//
//  FilterDateViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2017-01-24.
//  Copyright © 2017 Ubriety. All rights reserved.
//

import UIKit
import GLCalendarView

class FilterDateViewController: UIViewController, GLCalendarViewDelegate {
  
  @IBOutlet weak var calendarView: GLCalendarView!
  @IBOutlet weak var emptyStateView: UIView!
  @IBOutlet weak var fromDate: UILabel!
  @IBOutlet weak var fromYear: UILabel!
  @IBOutlet weak var toDate: UILabel!
  @IBOutlet weak var toYear: UILabel!
  @IBOutlet weak var submitButton: UIButton!

  var project: Project!
  var beginDate: Date?
  var endDate: Date?
  var filter: Filter?

  lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()

    formatter.dateFormat = "MMM d"
    return formatter

  }()

  lazy var yearFormatter: DateFormatter = {
    let formatter = DateFormatter()

    formatter.dateFormat = "y"
    return formatter

  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    let predicate = NSPredicate(format: "area.project = %@", project)
    let issues = Issue.mr_findAll(with: predicate) as! [Issue]

    let dates = issues.map { $0.createdDate! }

    let last: Date = Date()
    var first: Date = GLDateUtils.date(byAddingDays: -60, to: last)

    
    if dates.min() != nil{
      first = dates.min()!
    }

    calendarView.firstDate = first
    calendarView.lastDate = last
    calendarView.delegate = self
    calendarView.backgroundColor = UIColor.clear

    GLCalendarDayCell.appearance().rangeDisplayMode = RANGE_DISPLAY_MODE.CONTINUOUS
    GLCalendarDayCell.appearance().editCoverBorderWidth = 1
    GLCalendarDayCell.appearance().editCoverBorderColor = UIColor.wspLightBlue()

    submitButton.addShadow()


  }

  func formatDateLabelsWithBeginDate(_ beginDate: Date, endDate: Date) {

    fromDate.text = dateFormatter.string(from: beginDate)
    fromYear.text = yearFormatter.string(from: beginDate)

    toDate.text = dateFormatter.string(from: endDate)
    toYear.text = yearFormatter.string(from: endDate)

    self.beginDate = beginDate
    self.endDate = endDate

  }

  @IBAction func submitPressed(_ sender: AnyObject) {

    if let bd = beginDate, let ed = endDate, let filter = self.filter {
      self.dismiss(animated: true, completion: {
        filter.addDateRangeFilter(bd, endDate: ed)
      })
    }
  }

  func calenderView(_ calendarView: GLCalendarView!, canAddRangeWithBegin beginDate: Date!) -> Bool {

    if calendarView.ranges.count > 0 {
      return false
    } else {
      return true
    }

  }

  func calenderView(_ calendarView: GLCalendarView!, beginToEdit range: GLCalendarDateRange!) {


  }

  func calenderView(_ calendarView: GLCalendarView!, finishEdit range: GLCalendarDateRange!, continueEditing: Bool) {


  }

  func calenderView(_ calendarView: GLCalendarView!, rangeToAddWithBegin beginDate: Date!) -> GLCalendarDateRange! {

    let endDate = GLDateUtils.date(byAddingDays: 0, to: beginDate)
    let range = GLCalendarDateRange(begin: beginDate, end: endDate)
    range?.backgroundColor = UIColor.wspLightBlue()
    range?.editable = true

    formatDateLabelsWithBeginDate(beginDate, endDate: endDate!)
    self.submitButton.alpha = 0
    self.submitButton.isHidden = false

    UIView.animate(withDuration: 0.25, animations: {
      self.emptyStateView.alpha = 0
      self.submitButton.alpha = 1
      }, completion: { _ in
        self.emptyStateView.isHidden = true
        self.calendarView.begin(toEdit: range)
    })

    return range

  }

  func calenderView(_ calendarView: GLCalendarView!, didUpdate range: GLCalendarDateRange!, toBegin beginDate: Date!, end endDate: Date!) {
    formatDateLabelsWithBeginDate(beginDate, endDate: endDate)

  }

  func calenderView(_ calendarView: GLCalendarView!, canUpdate range: GLCalendarDateRange!, toBegin beginDate: Date!, end endDate: Date!) -> Bool {

    return true

  }


}
