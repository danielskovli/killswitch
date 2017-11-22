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
    
    
}
