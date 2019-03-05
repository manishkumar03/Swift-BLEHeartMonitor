//
//  BLEManager.swift
//  BLEHeartMonitor
//
//  Created by Manish Kumar on 2019-03-05.
//  Copyright © 2019 Manish Kumar. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol HeartRateMonitorDelegate: class {
  func heartRateMonitorDidUpdateHeartRate(_ heartRateBPM: Int)
}

/// CBUUID will automatically convert this 16-bit number to 128-bit UUID
let heartRateServiceUUID = CBUUID(string: "0x180D")
let heartRateCharacteristicUUID = CBUUID(string: "2A37")

class BLECentralManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
  var centralManager: CBCentralManager!
  var heartRatePeripheral: CBPeripheral!
  var delegate: HeartRateMonitorDelegate?
  
  override init() {
    super.init()
    centralManager = CBCentralManager(delegate: self, queue: nil)
  }
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
    case .poweredOn:
      print("Central manager is up and running")
      centralManager.scanForPeripherals(withServices: [heartRateServiceUUID], options: nil)
      
    default:
      print("Manager not yet running")
    }
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    print(peripheral)
    /// Let's make sure that we are getting the heart rate information from the right tracker. In this case, my other iPhone
    /// is acting as the HRM tracker.
    if (peripheral.name! == "Manish’s iPhone") {
      heartRatePeripheral = peripheral
      heartRatePeripheral.delegate = self
      centralManager.stopScan()
      centralManager.connect(heartRatePeripheral, options: nil)
    }
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    print("Connected to HRM")
    peripheral.discoverServices([heartRateServiceUUID])
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    /// Let's make sure that the HRM tracker is actually providing any services.
    guard let services = peripheral.services else {return}
    
    for service in services {
      print(service)
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }
  
  /// The characteristic with UUID 2A37 is the Heart Rate Measurement.
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    guard let characteristics = service.characteristics else {return}
    
    for characteristic in characteristics {
      if characteristic.uuid == heartRateCharacteristicUUID {
        peripheral.setNotifyValue(true, for: characteristic)
      }
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    switch characteristic.uuid {
    case heartRateCharacteristicUUID:
      let heartRateBPM = getHeartRate(from: characteristic)
      delegate?.heartRateMonitorDidUpdateHeartRate(heartRateBPM)
      print(heartRateBPM)
    default:
      print("Unknown characteristic")
    }
  }
  
  /// The value of a characteristic is returned as an array of 8-bit integers. If the value is small enough to fit in
  /// one byte (between 0 and 255), it is returned in two bytes where the first bit of the first byte is 0 and the second byte contains the
  /// actual value. In this case, the formula is:
  /// value = secondByte
  /// If the value is larger than 255, the first bit of the first byte is 1. In this case, the formula to get the value is:
  /// value = (firstByte * 256^0) + (secondByte * 256^1) + (thirdByte * 256^2)... and so on.
  func getHeartRate(from characteristic: CBCharacteristic) -> Int {
    guard let heartRateData = characteristic.value else {return 0}
    
    let heartRateByteArray = [UInt8](heartRateData)
    let firstBit = heartRateByteArray[0] & 0x01
    var heartRateBPM: Int = 0

    if firstBit == 0 {
      heartRateBPM = Int(heartRateByteArray[1])
    } else {
      for i in 0..<heartRateByteArray.count {
        let byte = Int(heartRateByteArray[i])
        heartRateBPM = heartRateBPM + (byte * Int(pow(256, Double(i))))
      }
    }
    
    return heartRateBPM
  }

} /// class end
