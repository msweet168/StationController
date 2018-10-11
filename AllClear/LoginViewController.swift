//
//  LoginViewController.swift
//  AllClear
//
//  Created by Mitchell Sweet on 4/16/18.
//  Copyright © 2018 Mitchell Sweet. All rights reserved.
//

import UIKit
import CoreBluetooth


class LoginViewController: UIViewController, BluetoothSerialDelegate {
    
    //MARK: Outlets
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var backgroundBlur: UIView!
    @IBOutlet var buttonContainer: UIView!
    @IBOutlet var member: UIButton!
    @IBOutlet var guest: UIButton!
    @IBOutlet var cancel: UIButton!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet weak var center: NSLayoutConstraint!
    @IBOutlet weak var top: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewSetup()
    }
    
    //MARK: Bluetooth Serial
    func serialDidChangeState() {
        print("Loaded: State Changed")
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        fatalError("Error: Disconnect on startup")
    }
    
    
    //MARK: Functions
    
    /// Sets up runtime UI elements.
    func viewSetup() {
        backgroundBlur.backgroundColor = UIColor(red: 0/255, green: 118/255, blue: 255/255, alpha: 0.5)
        member.layer.cornerRadius = 10
        guest.layer.cornerRadius = 10
        cancel.layer.cornerRadius = 10
        passwordField.layer.cornerRadius = 10
        
        serial = BluetoothSerial(delegate: self)
    }
    
    
    func showLogin() {
        animate(show: false)
    }
    
    func hideLogin() {
        animate(show: true)
    }
    
    func animate(show: Bool) {
        center.priority = UILayoutPriority(rawValue: (show ? 2 : 1))
        top.priority = UILayoutPriority(rawValue: (show ? 1 : 2))
        UIView.animate(withDuration: 0.5) {
            self.buttonContainer.alpha = (show ? 1 : 0)
            self.view.layoutIfNeeded()
            self.cancel.alpha = (show ? 0 : 1)
            self.passwordField.alpha = (show ? 0 : 1)
        }
    }
    
    func validatePassword(entered: String, completion: @escaping (Bool) -> Void) {
        let url = URL(string: "https://www.masprojects.site/tpetemp/clearcheck.txt")
        var urlRequest = URLRequest(url: url!)
        urlRequest.httpMethod = "GET"
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            
            guard error == nil else {
                print("Error connecting to server: \(error?.localizedDescription ?? "description not available.")")
                return
            }
            
            guard let content = data else {
                print("Error: There was no data returned.")
                return
            }
            

            if let pass = String(data: content, encoding: String.Encoding.utf8) {
                DispatchQueue.main.async {
                    print(pass)
                    completion(entered == pass.trimmingCharacters(in: CharacterSet.newlines) ? true : false)
                }
                
            }
            else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
            
        })
        task.resume()
        
    }
    
    func goMember() {
        self.performSegue(withIdentifier: "toScan", sender: self)
    }
    
    func goGuest() {
        self.performSegue(withIdentifier: "toGuest", sender: self)
    }
    
    
    //MARK: Actions
    
    @IBAction func memberTapped() {
        showLogin()
    }
    
    @IBAction func guestTapped() {
        goGuest()
    }
    
    @IBAction func cancelTapped() {
        hideLogin()
    }
    
    @IBAction func passwordEntered(sender: UITextField) {
        guard let text = sender.text else {
            sender.backgroundColor = .red
            return
        }
        
        validatePassword(entered: text, completion: { (result) in
            if result {
                print("passed")
                DispatchQueue.main.async {
                    self.goMember()
                }
            }
            else {
                sender.backgroundColor = .red
                sender.text = ""
                sender.becomeFirstResponder()
            }
        })
    }
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
