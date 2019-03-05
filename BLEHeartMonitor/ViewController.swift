//
//  ViewController.swift
//  BLEHeartMonitor
//
//  Created by Manish Kumar on 2019-03-05.
//  Copyright © 2019 Manish Kumar. All rights reserved.
//

import UIKit

class ViewController: UIViewController, HeartRateMonitorDelegate {

  @IBOutlet weak var lblHeartRateBPM: UILabel!
  var bleCentralManager: BLECentralManager!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    bleCentralManager = BLECentralManager()
    bleCentralManager.delegate = self
    lblHeartRateBPM.layer.cornerRadius = 20
    lblHeartRateBPM.clipsToBounds = true
    lblHeartRateBPM.text = "___"
  }

  func heartRateMonitorDidUpdateHeartRate(_ heartRateBPM: Int) {
    DispatchQueue.main.async {
      self.lblHeartRateBPM.text = heartRateBPM.description
    }
  }

}

