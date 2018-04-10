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
                return nil
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
                return nil
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
                return nil
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
                return nil
            }
            return token
        }
        set(token) {
            UserDefaults.standard.set(token, forKey: "token")
        }
    }
    
    
}
