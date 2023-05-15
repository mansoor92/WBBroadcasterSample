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

enum BluetoothLECentralError: Error {
    case noPeripheral
}

protocol BroadcasterDelegate: AnyObject {
    func didStartAdvertising()
    func didReceiveRead(_ value: String)
    func didReceiveWrite(_ value: String)
}

class Broadcaster: NSObject {
  
    private var bluetoothReady = false
    private var shouldStartWhenReady = false
    private var peripheralManager: CBPeripheralManager!
    private var service: CBUUID!
    private let value = "AD34E"
    private let logger = os.Logger(subsystem: "com.example.apple-samplecode.NINearbyAccessorySample", category: "Broadcaster")
    
    weak var delegate: BroadcasterDelegate?
    
    override init() {
        super.init()
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func start() {
        if bluetoothReady {
            addService()
        } else {
            shouldStartWhenReady = true
        }
    }
    
    private func addService() {
        let valueData = value.data(using: .utf8)
        let myChar1 = CBMutableCharacteristic(type: CBUUID(nsuuid: UUID()), properties: [.notify, .write, .read], value: nil, permissions: [.readable, .writeable])
          let myChar2 = CBMutableCharacteristic(type: CBUUID(nsuuid: UUID()), properties: [.read], value: valueData, permissions: [.readable])
        
        service = CBUUID(nsuuid: UUID())
        let myService = CBMutableService(type: service, primary: true)
        // 3. Add characteristics to the service
        myService.characteristics = [myChar1, myChar2]
        // 4. Add service to peripheralManager
        peripheralManager.add(myService)
        // 5. Start advertising
        startAdvertising()
    }
    
    private func startAdvertising() {
        peripheralManager.startAdvertising([CBAdvertisementDataLocalNameKey : "BLEPeripheralApp", CBAdvertisementDataServiceUUIDsKey : [service]])
        delegate?.didStartAdvertising()
    }
    
    private func cleanUp() {
        peripheralManager.removeAllServices()
        self.service = nil
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
            addService()
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
//        startAdvertising()
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        guard error == nil else {
            logger.log("Advertising failed: \(error)")
            cleanUp()
            return
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        logger.log("characteristic: \(characteristic.uuid) subscribed")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        logger.log("characteristic: \(characteristic.uuid) unsubscribed")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        delegate?.didReceiveRead(value)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        
        guard let value = requests.first?.value else { return }
        delegate?.didReceiveWrite(value.hexEncodedString())
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}
    
