//
//  FormViewController.swift
//  wsp
//
//  Created by Filip Wolanski on 2016-05-26.
//  Copyright © 2016 Ubriety. All rights reserved.
//

import UIKit


class FormViewController: ILPDFViewController {
  
  weak var pagesViewController: PagesViewController?
  var timer: DispatchSource?

  override func viewDidAppear(_ animated: Bool) {

    super.viewDidAppear(animated)
    startTimer()


  }

  func startTimer() {
    timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: DispatchQueue.main) /*Migrator FIXME: Use DispatchSourceTimer to avoid the cast*/ as? DispatchSource
    timer?.schedule(deadline: DispatchTime.now(), repeating: DispatchTimeInterval.seconds(Int(5 * NSEC_PER_SEC)), leeway: DispatchTimeInterval.seconds(Int(1 * NSEC_PER_SEC)))
    // timer!.setTimer(start: DispatchTime.now(), interval: 5 * NSEC_PER_SEC, leeway: 1 * NSEC_PER_SEC) // every 5 seconds, with leeway of 1 second
    timer!.setEventHandler { [weak self] in

      guard let document = self?.document else {
        Config.error()
        return
      }

      guard let form = self?.pagesViewController?.form else {
        Config.error()
        return
      }

      form.document = document
      Manager.sharedInstance.saveCurrentState(nil)
    }
    timer!.resume()
  }

  func stopTimer() {
    if let timer = timer {
      timer.cancel()
      self.timer = nil
    }
  }

  deinit {
    stopTimer()
  }


}
