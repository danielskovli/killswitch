//
//  ViewController.swift
//  Killswitch
//
//  Created by Daniel Skovli on 16/11/17.
//  Copyright © 2017 Daniel Skovli. All rights reserved.
//

import Cocoa
import Alamofire
import SwiftHash
import ServiceManagement


class ViewController: NSViewController {

    // Trackers and binds
    @IBOutlet var linkSystemPrefs: NSButton!
    @IBOutlet var linkDownload: NSButton!
    @IBOutlet var linkChangePass: NSButton!
    @IBOutlet var linkDeleteUser: NSButton!
    @IBOutlet var linkWebsite: NSButton!
    @IBOutlet var logoutButton: NSButton!
    @IBOutlet var signupButton: NSButton!
    @IBOutlet var loginButton: NSButton!
    @IBOutlet var copyrightBlurb: NSTextField!
    @IBOutlet var prefRunAtStartup: NSButton!
    @IBOutlet var signupSubmitButton: NSButton!
    @IBOutlet var signupPasswordRepeat: NSTextField!
    @IBOutlet var signupPassword: NSTextField!
    @IBOutlet var signupEmail: NSTextField!
    @IBOutlet var signupName: NSTextField!
    @IBOutlet var prefLoginForgotButton: NSButton!
    @IBOutlet var prefLoginLoginButton: NSButton!
    @IBOutlet var prefLoginGroupView: NSView!
    @IBOutlet var prefLoginGroup: NSBox!
    @IBOutlet var username: NSTextField!
    @IBOutlet var password: NSSecureTextField!
    @IBOutlet var killActionCombo: NSPopUpButton!
    @IBOutlet var prefAccountTextView: NSTextField!
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
            
            // Copyright blurb thing
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                let date = Date()
                let calendar = Calendar.current
                let year = calendar.component(.year, from: date)
                self.copyrightBlurb.stringValue = "Killswitch v\(version)  –  Daniel Skovli © \(year)"
            }
            
            // Links
            linkDownload.attributedTitle = formatLinks(text: linkDownload.title, offset: 1)
            linkChangePass.attributedTitle = formatLinks(text: linkChangePass.title, offset: 1)
            linkDeleteUser.attributedTitle = formatLinks(text: linkDeleteUser.title, offset: 1)
            linkWebsite.attributedTitle = formatLinks(text: linkWebsite.title, offset: 1)
            linkSystemPrefs.attributedTitle = formatLinks(text: linkSystemPrefs.title, offset: 0)
            
            // Toggle some stuff based on login status
            updateGUI()
            
            // Correct window size
            self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height)
            
        } else if (self.identifier?.rawValue == "loginWindow") {
            // Links
            prefLoginForgotButton.attributedTitle = formatLinks(text: prefLoginForgotButton.title)
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.level = .floating
        view.window?.makeKey()
    }
    
    
    @objc func hackyShit(_ notification: Notification) {
        updateGUI()
    }
    
    
    override func viewWillAppear() {
        if (self.identifier?.rawValue == "mainPrefWindow") {
            NotificationCenter.default.addObserver(self, selector: #selector(hackyShit), name: Notification.Name(rawValue: "updateGUI"), object: nil)
        }
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
            self.prefAccountTextView.stringValue = UserDefaultsManager.shared.name! + " <" + UserDefaultsManager.shared.username! + ">"
            self.loginButton.isHidden = true
            self.signupButton.isHidden = true
            self.logoutButton.isHidden = false
        } else {
            self.prefAccountTextView.stringValue = "Not signed in. Please register or sign in below"
            self.loginButton.isHidden = false;
            self.signupButton.isHidden = false;
            self.logoutButton.isHidden = true
        }
        
        if (UserDefaultsManager.shared.launchAtLogin!) {
            prefRunAtStartup.state = .on
        } else {
            prefRunAtStartup.state = .off
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
            // yeehaw! aka pass, for now. Maybe alert the user if this doesn't succeed?
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
        //print("Username: " + username.stringValue)
        //print("Password: " + password.stringValue)
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

                // Invalid creds
                if let _ = parsed["error"] as? String {
                    print("invalid creds")
                    _ = self.messageBox(message: "Invalid credentials, please try again. If you've forgotten your password, please click the 'forgotten password' link", title: "Login error")
                
                // Success
                } else {
                    UserDefaultsManager.shared.name = (parsed["name"] as! String)
                    UserDefaultsManager.shared.token = (parsed["token"] as! String)
                    UserDefaultsManager.shared.username = (parsed["username"] as! String)
                    self.ad.authenticated = true
                    print("login ok")
                }
            
            // server issue -- unreachable
            } else {
                print("server unreachable")
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
        if (!signupEmail.stringValue.matches("\\S+@\\S+\\.\\S+")) {
            print("Username doesn't even remotely match an email address")
            signupEmail.becomeFirstResponder()
            _ = self.messageBox(message: "The email address you supplied doesn't look very legit. Please check your input and try again", title: "Invalid email address")
            return
        }
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
                
                // Unsuccessful
                if let error = parsed["error"] as? String {
                    print("server rejected new user")
                    print(error)
                    _ = self.messageBox(message: "Sorry, but something went wrong. The server said: " + error, title: "User registration failed")
                
                // Successful
                } else {
                    UserDefaultsManager.shared.name = (parsed["name"] as! String)
                    UserDefaultsManager.shared.token = (parsed["token"] as! String)
                    UserDefaultsManager.shared.username = (parsed["username"] as! String)
                    self.ad.authenticated = true
                    print("signup ok")
                    _ = self.messageBox(message: "Welcome aboard " + UserDefaultsManager.shared.name! + "! It's a pleasure to make your acquaintance 👌👊", title: "User registration successful")
                }
            
            // Server issue -- unreachable or other weirdness
            } else {
                print("server unreachable")
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
    
    
    @IBAction func runAtStartup(_ sender: NSButton) {
        switch sender.state {
        case .on:
            UserDefaultsManager.shared.launchAtLogin = true
            SMLoginItemSetEnabled(ad.launcherAppId as CFString, true)
        case .off:
            UserDefaultsManager.shared.launchAtLogin = false
            SMLoginItemSetEnabled(ad.launcherAppId as CFString, false)
        default: break
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
    
    @IBAction func hyperlinkSystemPrefs(_ sender: NSButton) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security"), NSWorkspace.shared.open(url) {
            //print("default browser was successfully opened")
        }
    }
    
    func formatLinks(text: String, offset: Int = 0) -> NSMutableAttributedString {
        let attrs = [
                        NSAttributedStringKey.foregroundColor: NSColor.blue,
                        NSAttributedStringKey.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
                    ]
        let title = NSMutableAttributedString(string: text, attributes: nil)
        let range = NSRange(location: offset, length: text.count-offset)
        title.setAttributes(attrs, range: range)
        
        return title
    }
}

