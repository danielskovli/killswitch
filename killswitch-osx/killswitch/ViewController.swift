//
//  ViewController.swift
//  Killswitch
//
//  Created by Daniel Skovli on 16/11/17.
//  Copyright © 2017 Daniel Skovli. All rights reserved.
//

import Cocoa
//import FirebaseCommunity

class ViewController: NSViewController {

    @IBOutlet var username: NSTextField!
    @IBOutlet var password: NSSecureTextField!
    @IBOutlet var killActionCombo: NSPopUpButton!
    @IBOutlet var prefAccountTextView: NSTextField!
    @IBOutlet var prefAccountButtonsView: NSStackView!
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
            prefAccountTextView.isHidden = true
        }
    }
    
    override func viewWillAppear() {
        // pass
    }
    
    override func viewWillDisappear() {
        // pass
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func forgotPassword(_ sender: NSButton) {
        print("oh hey. Sloppy")
    }
    
    @IBAction func killActionButton(_ sender: NSPopUpButton) {
        let newAction = KillAction(rawValue: sender.itemTitle(at: sender.indexOfSelectedItem))
        UserDefaultsManager.shared.killAction = newAction
        ad.toggleStartStop(restart: true)
    }
    
    @IBAction func loginButton(_ sender: NSButton) {
        print("Username: " + username.stringValue)
        print("Password: " + password.stringValue)
        
        // Connect to server here
        // Then change prefAccountText, plus toggle visibility
        //prefAccountText.isHidden = !prefAccountText.isHidden
        //prefAccountButtons.isHidden = !prefAccountButtons.isHidden
        
        self.view.window?.close()
    }
}

