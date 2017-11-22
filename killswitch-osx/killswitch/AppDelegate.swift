//
//  AppDelegate.swift
//  Killswitch
//
//  Created by Daniel Skovli on 16/11/17.
//  Copyright © 2017 Daniel Skovli. All rights reserved.
//

import Cocoa
//import FirebaseCommunity

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // Menu and status bar entry
    @IBOutlet weak var menu: NSMenu!
    var statusItem: NSStatusItem?

    // Data binds
    @objc dynamic var status : NSString = NSString(string: "Loading...")
    @objc dynamic var startStop : NSString = NSString(string: "")
    @IBOutlet weak var startStopButton: NSMenuItem!
    var isRunning : Bool = false
    let defaults = UserDefaults.standard
    
    // Listener object
    var listener : Listener!
    let listenURL = "http://danielskovli.com/killswitch/"
    var token = "nothing"
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        /*
            Register and style the status bar entry
        */
        self.statusItem = NSStatusBar.system.statusItem(withLength: -1)
        self.statusItem?.image = NSImage(named: NSImage.Name(rawValue: "StatusIcon"))

        // image should be set as tempate so that it changes when the user sets the menu bar to a dark theme
        self.statusItem?.image?.isTemplate = true
        
        // Set the menu that should appear when the item is clicked
        self.statusItem!.menu = self.menu
        
        // Set if the item should change color when clicked
        self.statusItem!.highlightMode = true
        
        /*
            Defaults
         */
        if UserDefaultsManager.shared.killAction == nil {
            UserDefaultsManager.shared.killAction = KillAction.lock
        }
        
        
        /*
            Attempt to start the Listener
         */
        toggleStartStop(restart: false)
    }

    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
    func toggleStartStop(restart : Bool) {
        
        // Temp limitations -- ADD LOGIN FEATURES AND STUFF HERE
        let killAction = UserDefaultsManager.shared.killAction
        if (killAction != KillAction.lock) {
            status = "Please complete setup"
            //startStopButton.isEnabled = false
            startStopButton.isHidden = true
            startStop = ""
            return
        }
        
        // Restart listener - aka Stop() and destroy
        if (restart) {
            if (listener != nil) {
                _ = listener.Stop()
            }
            listener = nil
        }
        
        // Initialise if needed
        if (listener == nil) {
            isRunning = false
            listener = Listener(url: listenURL, token: token, action: killAction!)
        }
        
        // Toggle run state
        if (isRunning) {
            isRunning = !listener.Stop()
        } else {
            isRunning = listener.Start()
        }
        
        // UI
        if (isRunning) {
            status = "System running"
            startStop = "Stop"
            startStopButton.isHidden = false
        } else {
            status = "System paused"
            startStop = "Start"
            startStopButton.isHidden = false
        }
    }
    
    
    @IBAction func startStopButton(_ sender: NSMenuItem) {
        toggleStartStop(restart: false)
    }
}

