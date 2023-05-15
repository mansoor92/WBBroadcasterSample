/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that facilitates the Nearby Interaction Accessory user experience.
*/

import UIKit
import NearbyInteraction
import os.log


enum MessageId: UInt8 {
    // Messages from the accessory.
    case accessoryConfigurationData = 0x1
    case accessoryUwbDidStart = 0x2
    case accessoryUwbDidStop = 0x3
    
    // Messages to the accessory.
    case initialize = 0xA
    case configureAndStart = 0xB
    case stop = 0xC
}

class ViewController: UIViewController {
    
    private let broadcaster = Broadcaster()
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var readValueLabel: UILabel!
    @IBOutlet weak var writeValueLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        broadcaster.delegate = self
        broadcaster.start()
    }
}

extension ViewController: BroadcasterDelegate {
    
    func didStartAdvertising() {
        messageLabel.text = "Advertising Data"
        print("Started Advertising")
    }
    
    func didReceiveRead(_ value: String) {
        messageLabel.text = "Data getting Read"
        readValueLabel.text = value
    }
    
    func didReceiveWrite(_ value: String) {
        messageLabel.text = "Writing Data"
        writeValueLabel.text = value
    }
}
