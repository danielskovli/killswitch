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

    // Trackers and binds
    @IBOutlet var signupSubmitButton: NSButton!
    @IBOutlet var signupPasswordRepeat: NSTextField!
    @IBOutlet var signupPassword: NSTextField!
    @IBOutlet var signupEmail: NSTextField!
    @IBOutlet var signupName: NSTextField!
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
        //print("got notification")
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
    
    
    func toggleSignupGUI(enable: Bool) {
        self.signupName.isEnabled = enable
        self.signupEmail.isEnabled = enable
        self.signupPassword.isEnabled = enable
        self.signupPasswordRepeat.isEnabled = enable
        self.signupSubmitButton.isEnabled = enable
    }
    
    
    func messageBox(message: String, title: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        return alert.runModal() == .alertFirstButtonReturn
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
            //print("default browser was successfully opened")
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
        //print("Pass hash: " + MD5(password.stringValue).lowercased())
        
        // Check that we got something from the user
        if (username.stringValue == "") {
            print("Username is empty")
            username.becomeFirstResponder()
            return
        }
        if (password.stringValue == "") {
            print("Password is empty")
            password.becomeFirstResponder()
            return
        }
        
        // Disable the GUI while we work
        toggleLoginGUI(enable: false)
        
        // Prepare and fire a HTTP request. Payload and reply are both JSON
        let parameters: [String: String] = [
            "username" : username.stringValue,
            "password" : MD5(password.stringValue).lowercased()
        ]
        
        Alamofire.request(ad.loginURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            if let json = response.result.value {
                let parsed = json as! NSDictionary
                //print("Got JSON: " + String(parsed.count))
                //print(parsed)
                //let error = parsed["error"] as! Bool
                //if (!parsed.value(forKey: "error").isKindOfClass(String)) {
                if let _ = parsed["error"] as? String {
                    // invalid creds
                    print("invalid creds")
                    // ALERT USER HERE
                    _ = self.messageBox(message: "Invalid credentials, please try again. If you've forgotten your password, please click the 'forgotten password' link", title: "Login error")
                } else {
                    UserDefaultsManager.shared.name = (parsed["name"] as! String)
                    UserDefaultsManager.shared.token = (parsed["token"] as! String)
                    UserDefaultsManager.shared.username = (parsed["username"] as! String)
                    self.ad.authenticated = true
                    print("login ok")
                }
            } else {
                // server issue - unreachable
                print("server unreachable")
                // ALERT USER HERE
                _ = self.messageBox(message: "Could not connect to the server. Please try again, and if the problem persists, check your internet connection", title: "Network error")
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
    
    
    @IBAction func signUpButton(_ sender: NSButton) {
        
        // Check that we got something from the user
        if (signupName.stringValue == "") {
            print("Name is empty")
            signupName.becomeFirstResponder()
            _ = self.messageBox(message: "You can't leave the name field blank. I mean, the least you can do is make up something fun, right?", title: "No name supplied")
            return
        }
        if (signupEmail.stringValue == "") {
            print("Username is empty")
            signupEmail.becomeFirstResponder()
            _ = self.messageBox(message: "You have to specify an email address. This will become your username, and it's super handy for everyone if you spell it correctly", title: "No email address")
            return
        }
        /*
        if (signupPassword.stringValue == "") {
            print("Password is empty")
            signupPassword.becomeFirstResponder()
            return
        }
        if (signupPasswordRepeat.stringValue == "") {
            print("Password repeat is empty")
            signupPasswordRepeat.becomeFirstResponder()
            return
        }
        */
        if (signupPassword.stringValue == "" || signupPasswordRepeat.stringValue == "" || signupPassword.stringValue != signupPasswordRepeat.stringValue) {
            print("Passwords empty or don't match")
            signupPassword.becomeFirstResponder()
            _ = self.messageBox(message: "The password fields are either empty or non-matching. Give it another shot", title: "Empty or non-matching passwords")
            return
        }
        
        // Disable the GUI while we work
        toggleSignupGUI(enable: false)
        
        // Prepare and fire a HTTP request. Payload and reply are both JSON
        let parameters: [String: String] = [
            "username" : signupEmail.stringValue,
            "password" : MD5(signupPassword.stringValue).lowercased(),
            "name"     : signupName.stringValue
        ]
        
        Alamofire.request(ad.addUserURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            if let json = response.result.value {
                let parsed = json as! NSDictionary
                //print("Got JSON: " + String(parsed.count))
                //print(parsed)
                //let error = parsed["error"] as! Bool
                //if (!parsed.value(forKey: "error").isKindOfClass(String)) {
                if let error = parsed["error"] as? String {
                    // invalid creds
                    print("server rejected new user")
                    print(error)
                    // ALERT USER HERE
                    _ = self.messageBox(message: "Sorry, but something went wrong. The server said: " + error, title: "User registration failed")
                } else {
                    UserDefaultsManager.shared.name = (parsed["name"] as! String)
                    UserDefaultsManager.shared.token = (parsed["token"] as! String)
                    UserDefaultsManager.shared.username = (parsed["username"] as! String)
                    self.ad.authenticated = true
                    print("signup ok")
                    _ = self.messageBox(message: "Welcome aboard " + UserDefaultsManager.shared.name! + "! It's a pleasure to make your acquaintance 👌👊", title: "User registration successful")
                }
            } else {
                // server issue - unreachable
                print("server unreachable")
                // ALERT USER HERE
                _ = self.messageBox(message: "Could not connect to the server. Please try again, and if the problem persists, check your internet connection", title: "Network error")
            }
            
            // all done
            // do stuff
            self.toggleSignupGUI(enable: true)
            
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
    
    
    @IBAction func hyperlinkWebsite(_ sender: NSButton) {
        if let url = URL(string: ad.websiteURL), NSWorkspace.shared.open(url) {
            //print("default browser was successfully opened")
        }
    }
    @IBAction func hyperlinkDeleteAccount(_ sender: NSButton) {
        if let url = URL(string: ad.deleteAccountURL), NSWorkspace.shared.open(url) {
            //print("default browser was successfully opened")
        }
    }
    @IBAction func hyperlinkChangePass(_ sender: NSButton) {
        if let url = URL(string: ad.changePasswordURL), NSWorkspace.shared.open(url) {
            //print("default browser was successfully opened")
        }
    }
    @IBAction func hyperlinkDownload(_ sender: NSButton) {
        if let url = URL(string: ad.downloadAppsURL), NSWorkspace.shared.open(url) {
            //print("default browser was successfully opened")
        }
    }
}

