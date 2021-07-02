//
//  ViewController.swift
//  BackgroundBle
//
//  Created by Brian Lin on 2021/6/28.
//

import UIKit
import CoreBluetooth
import UserNotifications

class ViewController: UIViewController, CBCentralManagerDelegate {

    private var centralManager : CBCentralManager!
    
    let BLEService = "00001901-0000-1000-8000-00805F9B34FD" // generic service

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("viewDidLoad")
        
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.requestAuthorization(options: [.sound, .alert]) { (granted, error) in
            if let error = error {
                print(error)
            }
        }

        
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth is On")
//            centralManager.scanForPeripherals(withServices: [CBUUID(string: BLEService)], options: nil)
            centralManager.scanForPeripherals(withServices: [CBUUID(string: BLEService)], options:[CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(value: true)])

//            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth is not active")
        }
    }
    
    func StopSearchBLE() {
        let when = DispatchTime.now() + 5 // change 5 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.centralManager.stopScan()
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("\nName   : \(peripheral.name ?? "(No name)")")
        print("RSSI   : \(RSSI)")
        for ad in advertisementData {
            print("AD Data: \(ad)")
        }
        print("------------------------------------------------------")
        
        notifyBeaconRanging()
    }
    
    
    fileprivate func notifyBeaconRanging() {
        NotificationCenter.default.post(name: NSNotification.Name("BLE"), object: nil)
        clearRangingNotifications {
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.getNotificationSettings { (notificationSettings) in
                if notificationSettings.authorizationStatus == .authorized {
                    let content = UNMutableNotificationContent()
                    content.title = "didDiscover()"
                    content.body = "didDiscoverServices"
                    content.sound = UNNotificationSound.default
                    content.categoryIdentifier = "didDiscoverServices"
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                } else {
                    print("Not authorized to show notification")
                }
            }
        }
    }

    
    private func clearRangingNotifications(completionHandler: @escaping () -> Void) {
        let unc = UNUserNotificationCenter.current()
        unc.getDeliveredNotifications { (deliveredNotifications) in
            let notificationsToRemove = deliveredNotifications.filter({ $0.request.content.categoryIdentifier == "didDiscoverServices" })
            unc.removeDeliveredNotifications(withIdentifiers: notificationsToRemove.map({ $0.request.identifier }))
            completionHandler()
        }
    }
    
}

