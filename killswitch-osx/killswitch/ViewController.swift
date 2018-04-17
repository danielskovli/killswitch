//
//  ViewController.swift
//  Killswitch
//
//  Created by Daniel Skovli on 16/11/17.
//  Copyright © 2017 Daniel Skovli. All rights reserved.
//

import Cocoa
//import FirebaseCommunity
import Alamofire
import SwiftHash

class ViewController: NSViewController {

    @IBOutlet var prefWindowRef: NSView!
    @IBOutlet var prefLoginForgotButton: NSButton!
    @IBOutlet var prefLoginLoginButton: NSButton!
    @IBOutlet var prefLoginGroupView: NSView!
    @IBOutlet var prefLoginGroup: NSBox!
    @IBOutlet var username: NSTextField!
    @IBOutlet var password: NSSecureTextField!
    @IBOutlet var killActionCombo: NSPopUpButton!
    @IBOutlet var prefAccountTextView: NSTextField!
    @IBOutlet var prefAccountButtonsView: NSStackView!
    @IBOutlet var prefAccountLogoutView: NSStackView!
    @IBOutlet var prefAccountText: NSTextField!
    @IBOutlet var loginWindowRef: NSView!
    let ad = NSApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Only apply the following if we're in the main preferences view
        if (self.identifier?.rawValue == "mainPrefWindow") {
          
            // Initiate the dropdown box
            killActionCombo.removeAllItems()
            for action in KillAction.allValues {
                killActionCombo.addItem(withTitle: action.rawValue)
            }
            if let killAction = UserDefaultsManager.shared.killAction {
                killActionCombo.selectItem(withTitle: killAction.rawValue)
            }
            
            // Toggle some stuff based on login status
            updateGUI()
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.level = .floating
    }
    
    @objc func hackyShit(_ notification: Notification) {
        print("got notification")
        updateGUI()
    }
    
    override func viewWillAppear() {
        if (self.identifier?.rawValue == "mainPrefWindow") {
            NotificationCenter.default.addObserver(self, selector: #selector(hackyShit), name: Notification.Name(rawValue: "updateGUI"), object: nil)        }
    }
    
    override func viewWillDisappear() {
        if (self.identifier?.rawValue == "mainPrefWindow") {
            NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "updateGUI"), object: nil)
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func updateGUI() {
        if (self.ad.authenticated) {
            self.prefAccountTextView.isHidden = false
            self.prefAccountTextView.stringValue = UserDefaultsManager.shared.name! + " <" + UserDefaultsManager.shared.username! + ">"
            self.prefAccountLogoutView.isHidden = false
            self.prefAccountButtonsView.isHidden = true
        } else {
            self.prefAccountTextView.isHidden = true
            self.prefAccountLogoutView.isHidden = true
            self.prefAccountButtonsView.isHidden = false
        }
    }
    
    func toggleLoginGUI(enable : Bool) {
        self.username.isEnabled = enable
        self.password.isEnabled = enable
        self.prefLoginLoginButton.isEnabled = enable
        self.prefLoginForgotButton.isEnabled = enable
    }
    
    @IBAction func killActionButton(_ sender: NSPopUpButton) {
        let newAction = KillAction(rawValue: sender.itemTitle(at: sender.indexOfSelectedItem))
        UserDefaultsManager.shared.killAction = newAction
        if (ad.authenticated) {
            ad.toggleStartStop(restart: true)
        }
    }
    
    @IBAction func forgotPassword(_ sender: NSButton) {
        if let url = URL(string: ad.resetPasswordURL), NSWorkspace.shared.open(url) {
            print("default browser was successfully opened")
        }
    }
    
    @IBAction func logoutButton(_ sender: NSButton) {
        UserDefaultsManager.shared.name = ""
        UserDefaultsManager.shared.token = ""
        UserDefaultsManager.shared.username = ""
        ad.authenticated = false
        updateGUI()
    }
    
    @IBAction func loginButton(_ sender: NSButton) {
        
        print("Username: " + username.stringValue)
        print("Password: " + password.stringValue)
        toggleLoginGUI(enable: false)
        
        print("Pass hash: " + MD5(password.stringValue).lowercased())
        
        let parameters: [String: String] = [
            "username" : username.stringValue,
            "password" : MD5(password.stringValue).lowercased()
        ]
        
        Alamofire.request(ad.loginURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            if let json = response.result.value {
                let parsed = json as! NSDictionary
                //print("Got JSON: " + String(parsed.count))
                print(parsed)
                //let error = parsed["error"] as! Bool
                //if (!parsed.value(forKey: "error").isKindOfClass(String)) {
                if let _ = parsed["error"] as? String {
                    // invalid creds
                    print("invalid creds")
                } else {
                    UserDefaultsManager.shared.name = parsed["name"] as! String
                    UserDefaultsManager.shared.token = parsed["token"] as! String
                    UserDefaultsManager.shared.username = parsed["username"] as! String
                    self.ad.authenticated = true
                    print("all is well")
                }
            } else {
                // server issue - unreachable
                print("server unreachable")
            }
            
            // all done
            // do stuff
            self.toggleLoginGUI(enable: true)
            
            if (self.ad.authenticated) {
                //self.updateGUI()
                NotificationCenter.default.post(name: Notification.Name(rawValue: "updateGUI"), object: nil)
                self.ad.toggleStartStop(restart: true)
                self.view.window?.close()
            } else {
                //pass
            }
        }
    }
}

