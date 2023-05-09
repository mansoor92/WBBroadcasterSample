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

class AccessoryDemoViewController: UIViewController {
    
    private let broadcaster = Broadcaster()
    
    @IBOutlet weak var connectionStateLabel: UILabel!
    @IBOutlet weak var uwbStateLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        broadcaster.start()
    }
}
