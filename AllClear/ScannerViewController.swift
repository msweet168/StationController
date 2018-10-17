//
//  ScannerViewController.swift
//  AllClear
//
//  Created by Mitchell Sweet on 4/16/18.
//  Copyright © 2018 Mitchell Sweet. All rights reserved.
//

import UIKit
import CoreBluetooth

class ScannerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BluetoothSerialDelegate {
    
    // MARK: Outlets
    @IBOutlet var tableView: UITableView!
    @IBOutlet var cancelButton: UIButton!
    
    /// The peripherals that have been discovered (no duplicates and sorted by asc RSSI)
    var peripherals: [(peripheral: CBPeripheral, RSSI: Float)] = []
    
    /// The peripheral the user has selected
    var selectedPeripheral: CBPeripheral?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Loading...")
        serial.delegate = self
        if serial.centralManager.state != .poweredOn {
            title = "Bluetooth not turned on"
            return
        }
        serial.startScan()
        viewSetup()
        tableViewSetup()
    }
    
    // MARK: Functions
    
    /// Sets up runtime UI elements.
    func viewSetup() {
        cancelButton.layer.borderColor = UIColor.white.cgColor
        cancelButton.layer.borderWidth = 2
        cancelButton.layer.cornerRadius = 25
    }
    
    /// Sets up runtime table view UI elements.
    func tableViewSetup() {
        tableView.separatorColor = .white
        tableView.rowHeight = 60
    }
    
    // MARK: Bluetooth Serial Delegate
    @objc func connectTimeOut() {
        // don't if already connected
        if let _ = serial.connectedPeripheral {
            return
        }
        
        if let _ = selectedPeripheral {
            serial.disconnect()
            selectedPeripheral = nil
        }
        
        print("Connection failed: time out")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let count = peripherals.count
        
        if count == 0 {
            //TODO: Handle nothing found
        }
        
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let name = peripherals[(indexPath as NSIndexPath).row].peripheral.name
        
        if (name?.contains("Station"))! {
            cell.textLabel?.text = name
            cell.detailTextLabel?.text = "Ready to Connect"
            cell.detailTextLabel?.textColor = UIColor(red: 0/255, green: 165/255, blue: 0/255, alpha: 1)
        }
        else {
            cell.textLabel?.text = name
            cell.isUserInteractionEnabled = false
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        serial.stopScan()
        selectedPeripheral = peripherals[(indexPath as NSIndexPath).row].peripheral
        serial.connectToPeripheral(selectedPeripheral!)
        
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(connectTimeOut), userInfo: nil, repeats: false)
    }
    
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {
        // check whether it is a duplicate
        for exisiting in peripherals {
            if exisiting.peripheral.identifier == peripheral.identifier { return }
        }
        
        // add to the array, next sort & reload
        let theRSSI = RSSI?.floatValue ?? 0.0
        peripherals.append((peripheral: peripheral, RSSI: theRSSI))
        peripherals.sort { $0.RSSI < $1.RSSI }
        tableView.reloadData()
    }
    
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: NSError?) {
        print("Failed to connect.")
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        print("Disconnected.")
        
    }
    
    func serialIsReady(_ peripheral: CBPeripheral) {
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadStartViewController"), object: self)
        self.performSegue(withIdentifier: "toController", sender: self)
    }
    
    func serialDidChangeState() {
        
        if serial.centralManager.state != .poweredOn {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadStartViewController"), object: self)
            dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: Actions
    @IBAction func back() {
        serial.startScan()
        self.dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
