//
//  ProfileHeaderViewModel.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/13.
//

import Foundation

struct ProfileHeaderViewModel {
    let user: User
    
    var fullname: String {
        return user.fullname
    }
    
    var profileImageUrl: URL? {
        return URL(string: user.profileImageUrl)
    }
    
    init(user: User) {
        self.user = user
    }
    
    
    
}

