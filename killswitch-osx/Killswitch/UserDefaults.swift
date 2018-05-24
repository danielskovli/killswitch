//
//  UserDefaults.swift
//  killswitch
//
//  Created by Daniel Skovli on 19/11/17.
//  Copyright © 2017 Daniel Skovli. All rights reserved.
//

import Foundation


class UserDefaultsManager {
    
    static let shared = UserDefaultsManager()
    
    var killAction: KillAction? {
        get {
            guard let killAction = UserDefaults.standard.value(forKey: "killAction") as? String else {
                //return nil
                return KillAction.sleep
            }
            return KillAction(rawValue: killAction)
        }
        set(killAction) {
            UserDefaults.standard.set(killAction?.rawValue, forKey: "killAction")
        }
    }
    
    var username: String? {
        get {
            guard let username = UserDefaults.standard.value(forKey: "username") as? String else {
                //return nil
                return ""
            }
            return username
        }
        set(username) {
            UserDefaults.standard.set(username, forKey: "username")
        }
    }
    
    var name: String? {
        get {
            guard let name = UserDefaults.standard.value(forKey: "name") as? String else {
                //return nil
                return ""
            }
            return name
        }
        set(name) {
            UserDefaults.standard.set(name, forKey: "name")
        }
    }
    
    var token: String? {
        get {
            guard let token = UserDefaults.standard.value(forKey: "token") as? String else {
                //return nil
                return ""
            }
            return token
        }
        set(token) {
            UserDefaults.standard.set(token, forKey: "token")
        }
    }
    
    var lastStatus: Bool? {
        get {
            guard let lastStatus = UserDefaults.standard.value(forKey: "lastStatus") as? Bool else {
                //return nil
                return false
            }
            return lastStatus
        }
        set(lastStatus) {
            UserDefaults.standard.set(lastStatus, forKey: "lastStatus")
        }
    }
    
    var launchAtLogin: Bool? {
        get {
            guard let launchAtLogin = UserDefaults.standard.value(forKey: "launchAtLogin") as? Bool else {
                //return true
                return false
            }
            return launchAtLogin
        }
        set(launchAtLogin) {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
        }
    }
    
}
