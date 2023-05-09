//
//  Broadcaster.swift
//  NINearbyAccessorySample
//
//  Created by Mansoor Ali on 09/05/2023.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit
import os

struct TransferService {
    static let serviceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
//    static let rxCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
//    static let txCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    static let heartRateMeasurementUUID = CBUUID(string: "2A37")
}

enum BluetoothLECentralError: Error {
    case noPeripheral
}

class Broadcaster: NSObject {
  
    private var bluetoothReady = false
    private var shouldStartWhenReady = false
    private var service: CBMutableService?
    private var peripheralManager: CBPeripheralManager!
    private var characteristic: CBMutableCharacteristic!
    private let logger = os.Logger(subsystem: "com.example.apple-samplecode.NINearbyAccessorySample", category: "Broadcaster")
    
    override init() {
        super.init()
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func start() {
        if bluetoothReady {
            createService()
        } else {
            shouldStartWhenReady = true
        }
    }
    
    private func createService() {
//        let bytes = [0x1,0x2,0x3,0xA,0xB,0xC]
//        let data = Data.init(bytes: bytes, count: bytes.count)
        let service = CBMutableService(type: TransferService.serviceUUID, primary: true)
//        let characteristic = CBMutableCharacteristic(type: TransferService.txCharacteristicUUID, properties: [.read, .notify], value: nil, permissions: [.readable])
        let heartRateMeasurementCharacteristic = CBMutableCharacteristic(type: TransferService.heartRateMeasurementUUID, properties: [.notify], value: nil, permissions: [.readable])
        service.characteristics = [heartRateMeasurementCharacteristic]
        peripheralManager?.add(service)
        self.service = service
        self.characteristic = heartRateMeasurementCharacteristic
    }
    
    private func cleanUp() {
        if let service = service {
            peripheralManager.remove(service)
            self.service = nil
            characteristic = nil
        }
    }
    
    private func sendData(_ data: Data, toCharacteristic characteristic: CBMutableCharacteristic) throws {
        guard let peripheralManager = peripheralManager else {
            throw(BluetoothLECentralError.noPeripheral)
        }
        
//        peripheralManager.updateValue(heartRateMeasurementData, for: heartRateMeasurementCharacteristic, onSubscribedCentrals: nil)
        
        let success = peripheralManager.updateValue(data, for: characteristic, onSubscribedCentrals: nil)
        if success {
            logger.log("Data sent successfully")
        } else {
            logger.log("Failed to send data")
        }
    }
}

extension Broadcaster: CBPeripheralManagerDelegate {
 
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            createService()
        default: break
            
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil else {
            logger.log("add service failed: \(error)")
            cleanUp()
            start()
            return
        }
        
        let data: [String: Any] = [
            CBAdvertisementDataLocalNameKey: "Mansoor Device",
            CBAdvertisementDataServiceUUIDsKey: [TransferService.serviceUUID]
        ]
        peripheralManager?.startAdvertising(data)
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        guard error == nil else {
            logger.log("Advertising failed: \(error)")
            cleanUp()
            return
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        guard characteristic.uuid == TransferService.heartRateMeasurementUUID, let mutableCharacteristic = self.characteristic else { return }
        logger.log("characteristic: \(characteristic.uuid) subscribed")
        
//        let data = "Initial value".data(using: .utf8)!
//        var msg = Data([MessageId.configureAndStart.rawValue])
//        msg.append(data)
        
        let heartRateValue: UInt16 = 60
        let sensorContactStatus: UInt8 = 2 // "not supported"
        let heartRateMeasurementData = Data([UInt8(heartRateValue & 0xFF), UInt8(heartRateValue >> 8), sensorContactStatus])
        
        do {
            try sendData(heartRateMeasurementData, toCharacteristic: mutableCharacteristic)
        } catch {
            print(error)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        guard characteristic.uuid == TransferService.heartRateMeasurementUUID else { return }
        logger.log("characteristic: \(characteristic.uuid) unsubscribed")
    }
}
    
