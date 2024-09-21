//
//  UserManager.swift
//  InstagramClone
//
//  Created by 이상준 on 9/21/24.
//

import Foundation
import Firebase

final class UserManager {
    
    static let shared = UserManager()
    
    init() { }
    
    var currentUser: User?
    
    func fetchCurrentUser(completion: @escaping (User?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        
        UserService.fetchUser(withUid: uid) { user in
            self.currentUser = user
            completion(user)
        }
    }
    
}
