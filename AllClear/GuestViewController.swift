//
//  GuestViewController.swift
//  AllClear
//
//  Created by Mitchell Sweet on 4/16/18.
//  Copyright © 2018 Mitchell Sweet. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class GuestViewController: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate {
    
    //MARK: Outlets
    @IBOutlet var dispatchGuestButton: UIButton!
    @IBOutlet var gateToggleButton: UIButton!
    @IBOutlet var blurView: UIView!
    @IBOutlet weak var bottomConst: NSLayoutConstraint!
    
    //MARK Variables
    var gatesOpen = false;
    let defaultBottomConst = 60;
    let extendedBottomConst = -550;
    
    //MARK: Multipeer variables
    let serviceType = "LOCAL-Chat"
    
    var browser: MCBrowserViewController!
    var assistant: MCAdvertiserAssistant!
    var session: MCSession!
    var peerID: MCPeerID!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewSetup()
        multipeerSetup()
    }
    
    /// Sets up runtime UI elements.
    func viewSetup() {
        blurView.backgroundColor = UIColor(red: 248/255, green: 148/255, blue: 6/255, alpha: 0.8)
        gateToggleButton.layer.cornerRadius = 15
        dispatchGuestButton.layer.cornerRadius = 15
        
    }
    
    
    //MARK: Multipeer Functions
    
    /// Configures the basic settings of and starts the multipeer service.
    func multipeerSetup() {
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: self.peerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        self.session.delegate = self
        self.browser = MCBrowserViewController(serviceType:serviceType,
                                               session:self.session)
        self.browser.delegate = self;
        self.assistant = MCAdvertiserAssistant(serviceType:serviceType,
                                               discoveryInfo:nil, session:self.session)
        self.assistant.start()
    }
    
    /// Sends a multipeer message out to connected peers using a passed in String.
    func sendMessage(message: String) {
        let msg = message.data(using: String.Encoding.utf8,
                                        allowLossyConversion: false)
        let _ : NSError?
        do {
            try self.session.send(msg!, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print("Error sending message: \(error.localizedDescription)")
        }
    }
    
    /// Takes guestCommand enum and sends it as a multipeer message.
    func sendCommand(command: guestCommand) {
        
        let msg = command.rawValue.data(using: String.Encoding.utf8,
                               allowLossyConversion: false)
        let _ : NSError?
        do {
            try self.session.send(msg!, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print("Error sending command: \(error.localizedDescription)")
        }
    }
    
    func browserViewControllerDidFinish(
        _ browserViewController: MCBrowserViewController)  {
        // Called when the browser view controller is dismissed
        self.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(
        _ browserViewController: MCBrowserViewController)  {
        // Called when the browser view controller is cancelled
        self.dismiss(animated: true, completion: nil)
    }
    
    func session(_ session: MCSession, didReceive data: Data,
                 fromPeer peerID: MCPeerID)  {
        DispatchQueue.main.async {
            let msg = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)
            
            if msg == "arrived" {
                self.didArrive()
            }
            else if msg == "departed" {
                self.didDispatch()
            }
            else if msg == "opened" {
                self.gatesOpen = true
                self.gateToggleButton.setTitle("Close Gates", for: .normal)
                self.animateOver()
            }
            else if msg == "closed" {
                self.gatesOpen = false
                self.gateToggleButton.setTitle("Open Gates", for: .normal)
                self.animateBack()
            }
        }
    }
    
    
    //MARK: Functions
    func animateOver() {
        bottomConst.constant = CGFloat(extendedBottomConst)
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
            self.dispatchGuestButton.alpha = 0
        }
    }
    
    func animateBack() {
        bottomConst.constant = CGFloat(defaultBottomConst)
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
            self.dispatchGuestButton.alpha = 1
        }
    }
    
    func didArrive() {
        animateBack()
        gateToggleButton.isEnabled = true
        gateToggleButton.setTitle("Open Gates", for: .normal)
    }
    
    func didDispatch() {
        animateOver()
        gateToggleButton.isEnabled = false
        gateToggleButton.setTitle("Waiting for train to return...", for: .disabled)
    }
    
    //MARK: Actions
    @IBAction func connect() {
        self.present(self.browser, animated: true, completion: nil)
    }
    
    @IBAction func open() {
        sendCommand(command: .open)
    }
    
    @IBAction func close() {
        sendCommand(command: .close)
    }
    
    @IBAction func dispatch() {
        sendCommand(command: .dispatch)
    }
    
    @IBAction func gateToggle() {
        sendCommand(command: (gatesOpen ? .close : .open))
        sendMessage(message: (gatesOpen ? "closed" : "opened"))
        gateToggleButton.setTitle((gatesOpen ? "Open Gates" : "Close Gates"), for: .normal)
        gatesOpen ? animateBack() : animateOver()
        gatesOpen = !gatesOpen
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // The following functions do nothing, but the MCSessionDelegate protocol
    // requires that they are implemented.
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Called when a peer starts sending a file
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Called when a file has finished transferring from another peer
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Called when a peer establishes a stream
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID,
                 didChange state: MCSessionState)  {
        // Called when a connected peer changes state
        OperationQueue.main.addOperation({
            switch (state) {
            case .connected:
                print("Guest connected")
            case .connecting:
                break
            case .notConnected:
                print("Guest disconnected")
            }
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
}

enum guestCommand: String {
    case dispatch
    case open
    case close
}
