//
//  AppDelegate.swift
//  Killswitch
//
//  Created by Daniel Skovli on 16/11/17.
//  Copyright © 2017 Daniel Skovli. All rights reserved.
//

import Cocoa
import ServiceManagement
//import FirebaseCommunity

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // Menu and status bar entry
    @IBOutlet weak var menuPreferences: NSMenuItem!
    @IBOutlet weak var menu: NSMenu!
    var statusItem: NSStatusItem?

    // Binds and trackers
    let launcherAppId = "com.danielskovli.killswitchLauncher"
    @objc dynamic var status : NSString = NSString(string: "Loading...")
    @objc dynamic var startStop : NSString = NSString(string: "")
    @IBOutlet weak var startStopButton: NSMenuItem!
    var firstLoad : Bool = true;
    var isRunning : Bool = false {
        didSet {
            updateTrayIcon()
        }
    }
    var authenticated : Bool = false {
        didSet {
            updateTrayIcon()
        }
    }
    
    // Listener object and API stuff
    var listener : Listener!
    let listenURL = "http://apps.danielskovli.com/killswitch/api/1.0/status/"
    let loginURL = "http://apps.danielskovli.com/killswitch/api/1.0/login/"
    let addUserURL = "http://apps.danielskovli.com/killswitch/api/1.0/user/"
    let changePasswordURL = "http://apps.danielskovli.com/killswitch/changePassword.php"
    let resetPasswordURL = "http://apps.danielskovli.com/killswitch/resetPassword.php"
    let deleteAccountURL = "http://apps.danielskovli.com/killswitch/deleteUser.php"
    let websiteURL = "http://apps.danielskovli.com/killswitch/"
    let downloadAppsURL = "http://apps.danielskovli.com/killswitch/#download"
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Register and style the status bar entry
        self.statusItem = NSStatusBar.system.statusItem(withLength: -1)
        self.statusItem?.image = NSImage(named: NSImage.Name(rawValue: "StatusIconDisabled"))
        
        // Menu associated with tray icon
        self.statusItem!.menu = self.menu
        
        // Should the tray icon change color when clicked?
        self.statusItem!.highlightMode = true
        
        // Default lock-method
        if (UserDefaultsManager.shared.killAction == nil) {
            UserDefaultsManager.shared.killAction = KillAction.lock
        }
        
        // Launch preference window if we don't have a user account signed in
        if (UserDefaultsManager.shared.token! == "") {
            let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
            let controller = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "prefWindowController")) as! NSWindowController
            controller.showWindow(self)
        }
        
        // Attempt to start the listener
        toggleStartStop(restart: false)
        
        // Tell the launcher app to terminate
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty        
        if isRunning {
            DistributedNotificationCenter.default().post(name: .killLauncher,
                                                         object: Bundle.main.bundleIdentifier!)
        }
        
        // Set launcher auto-run status
        SMLoginItemSetEnabled(launcherAppId as CFString, UserDefaultsManager.shared.launchAtLogin!)
    }

    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
    func updateTrayIcon() {
        if (authenticated && isRunning) {
            DispatchQueue.main.async {
                self.statusItem?.image = NSImage(named: NSImage.Name(rawValue: "StatusIconEnabled"))
                self.statusItem?.image?.isTemplate = true
                
            }
        } else {
            DispatchQueue.main.async {
                self.statusItem?.image = NSImage(named: NSImage.Name(rawValue: "StatusIconDisabled"))
                self.statusItem?.image?.isTemplate = false
            }
        }
    }
    
    
    func toggleStartStop(restart : Bool) {
        
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
            listener = Listener(url: listenURL, token: UserDefaultsManager.shared.token!, action: UserDefaultsManager.shared.killAction!)
        }
        
        // Toggle run state
        if (isRunning) {
            isRunning = !listener.Stop()
        } else {
            isRunning = listener.Start()
        }
        
        // UI
        updateGUI()
    }
    
    
    func updateGUI() {
        if (firstLoad || !authenticated) {
            startStopButton.isHidden = true
        } else if (isRunning) {
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

