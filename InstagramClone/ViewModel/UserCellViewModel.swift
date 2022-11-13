//
//  UserCellViewModel.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/13.
//

import Foundation

struct UserCellViewModel {
    
    private let user : User
    
    var profileImageUrl: URL? {
        return URL(string: user.profileImageUrl)
    }
    
    var username: String {
        return user.username
    }
    
    var fullname: String {
        return user.fullname
    }
    
    init(user: User) {
        self.user = user
    }
    
}
