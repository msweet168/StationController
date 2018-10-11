//
//  MemberViewController.swift
//  AllClear
//
//  Created by Mitchell Sweet on 4/16/18.
//  Copyright © 2018 Mitchell Sweet. All rights reserved.
//

import UIKit
import CoreBluetooth
import QuartzCore
import MultipeerConnectivity

class MemberViewController: UIViewController, MCSessionDelegate, BluetoothSerialDelegate {
    
    // MARK: Outlets
    @IBOutlet var liftSlider: UISlider!
    @IBOutlet var liftValue: UILabel!
    @IBOutlet var presetLabel: UILabel!
    @IBOutlet var savePresetButton: UIButton!
    @IBOutlet var setPresetButton: UIButton!
    @IBOutlet var liftStopButton: UIButton!
    @IBOutlet var stationIndicator: UIView!
    @IBOutlet var gateSelector: UISegmentedControl!
    @IBOutlet var dispatchButton: UIButton!
    @IBOutlet var EStopButton: UIButton!
    @IBOutlet var guestSwitch: UISwitch!
    @IBOutlet var autoDispatchSwitch: UISwitch!
    @IBOutlet var backBlur: UIView!
    
    var dispatchTimer: Timer?
    
    //MARK: Multipeer Variables
    let serviceType = "LOCAL-Chat"
    
    var assistant: MCAdvertiserAssistant!
    var session: MCSession!
    var peerID: MCPeerID!
    
    var preset = 0
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewSetup()
        bluetoothInitalization()
        multipeerSetup()
        
        if let savedPreset = UserDefaults.standard.object(forKey: "preset") as? Int {
            preset = savedPreset
            presetLabel.text = "Saved Preset: \(preset)"
        }
        else {
            print("Setting preset for first time.")
            UserDefaults.standard.set(preset, forKey: "preset")
        }

    }
    
    /// Setup runtime UI elements.
    func viewSetup() {
        backBlur.backgroundColor = UIColor(red: 0/255, green: 118/255, blue: 255/255, alpha: 0.85)
        liftValue.text = "0"
        savePresetButton.layer.cornerRadius = 8
        setPresetButton.layer.cornerRadius = 8
        liftStopButton.layer.cornerRadius = 8
        stationIndicator.layer.cornerRadius = 25
        stationIndicator.backgroundColor = UIColor.red
        dispatchButton.layer.cornerRadius = 8
        EStopButton.layer.cornerRadius = 8
        
    }
    
    /// Set settings for multipeer.
    func multipeerSetup() {
        self.peerID = MCPeerID(displayName: "Master: \(UIDevice.current.name)")
        self.session = MCSession(peer: self.peerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        self.session.delegate = self
        self.assistant = MCAdvertiserAssistant(serviceType:serviceType,
                                               discoveryInfo:nil, session:self.session)
        self.assistant.start()
    }
    
    /// Sends message to connected guest controllers.
    func sendMessage(msg: String) {
        let _ : NSError?
        do {
            if let message = msg.data(using: String.Encoding.utf8,
                                      allowLossyConversion: false) {
                try self.session.send(message, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
            }
            else {
                print("Error getting message data.")
            }
            
        } catch {
            print("Error sending message: \(error.localizedDescription)")
        }
        
    }
    
    /// Called when a guest sends a data
    func session(_ session: MCSession, didReceive data: Data,
                 fromPeer peerID: MCPeerID)  {
        DispatchQueue.main.async {
            let msg = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)
            //TODO: Fix this force unwrap!
            self.recievedCommand(command: String(msg!))
        }
    }
    
    /// Handle recieved command
    func recievedCommand(command: String) {
        if guestSwitch.isOn {
            print("Received: " + command)
            
            let recieved = guestCommand(rawValue: command)
            
            if recieved == .dispatch {
                dispatch()
            }
            else if recieved == .open {
                serial.sendMessageToDevice("O")
                dispatchTimer?.invalidate()
                gateSelector.selectedSegmentIndex = 1
            }
            else if recieved == .close {
                serial.sendMessageToDevice("C")
                dispatchTimer?.invalidate()
                gateSelector.selectedSegmentIndex = 0
            }
            else {
                print("Unrecognized command recieved.")
            }
        }
        else {
            print("Recieved command \"\(command)\" from guest, but guest is not enabled.")
        }
        
    }
    
    
    //MARK: Bluetooth Serial
    
    func bluetoothInitalization() {
        serial.delegate = self
        
        reloadView()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadView), name: NSNotification.Name(rawValue: "reloadStartViewController"), object: nil)
    }
    
    
    // Remove notification observer when view deinitalizes.
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Checks the state of the serial connection and changes UI accordingly.
    @objc func reloadView() {
        serial.delegate = self
        
        if serial.isReady {
            print("Connected: \(serial.connectedPeripheral!.name ?? "Unknown Device")")
        } else if serial.centralManager.state == .poweredOn {
            print("Not Connected")
        } else {
            print("Bluetooth Off")
        }
    }
    
    func serialDidReceiveString(_ message: String) {
        //TODO: Handle recieved
        
        print("Recieved: " + message)
        
        if message.contains("arrived") {
            arrived()
        }
        else if message.contains("departed") {
            departed()
        }
        
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        reloadView()
        print("Device Disconnected")
    }
    
    func serialDidChangeState() {
        reloadView()
        if serial.centralManager.state != .poweredOn {
            print("Bluetooth off.")
        }
    }
    
    //MARK: Functions
    
    func dispatch() {
        dispatchTimer?.invalidate()
        serial.sendMessageToDevice("D")
    }
    
    func arrived() {
        print("Train arrived")
        sendMessage(msg: "arrived")
        stationIndicator.backgroundColor = UIColor.green
        if autoDispatchSwitch.isOn {
            if let running = dispatchTimer?.isValid {
                if !running {
                    dispatchTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: false, block: { (Timer) in
                        print("Auto dispatching...")
                        serial.sendMessageToDevice("D")
                    })
                }
            }
        }
    }
    
    func departed() {
        print("Train departed")
        sendMessage(msg: "departed")
        stationIndicator.backgroundColor = UIColor.red
    }
    
    //MARK: Actions
    
    @IBAction func changeSpeedLabel(Sender: UISlider) {
        if (Int(Sender.value) == 10) {
            liftValue.text = "\(Int(Sender.value))"
            serial.sendMessageToDevice("0")
            return
        }
        
        liftValue.text = "\(Int(Sender.value))"
        serial.sendMessageToDevice("\(Int(Sender.value))")
    }
    
    @IBAction func stopLift() {
        serial.sendMessageToDevice("S")
        liftValue.text = "0"
        liftSlider.value = 0
    }
    
    @IBAction func changeGates(Sender: UISegmentedControl) {
        dispatchTimer?.invalidate()
        if Sender.selectedSegmentIndex == 0 {
            serial.sendMessageToDevice("C")
            sendMessage(msg: "closed")
        }
        else {
            serial.sendMessageToDevice("O")
            sendMessage(msg: "opened")
        }
    }
    
    @IBAction func dispatchTapped() {
        dispatch()
    }
    
    @IBAction func eStop() {
        serial.sendMessageToDevice("E")
        gateSelector.selectedSegmentIndex = 0
        liftSlider.value = 0
        liftValue.text = "0"
    }
    
    @IBAction func savePreset() {
        preset = Int(liftSlider.value)
        UserDefaults.standard.set(preset, forKey: "preset")
        presetLabel.text = "Saved Preset: \(preset)"
    }
    
    @IBAction func setToPreset() {
        serial.sendMessageToDevice("\(preset)")
        liftSlider.value = Float(preset)
        liftValue.text = "\(preset)"
    }
    
    
    
    
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // The following methods don't do much, but the MCSessionDelegate protocol
    // requires that we implement them.
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Called when a peer starts sending a file to us
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Called when a file has finished transferring from another peer
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Called when a peer establishes a stream with us
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID,
                 didChange state: MCSessionState)  {
        // Called when a connected peer changes state (for example, goes offline)
        OperationQueue.main.addOperation({
            switch (state) {
            case .connected:
                print("Connected to guest device.")
            case .connecting:
                break
            case .notConnected:
                print("Disconnected from guest device.")
            }
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    

}
