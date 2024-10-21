//
//  ProfileHeaderViewReactor.swift
//  InstagramClone
//
//  Created by 이상준 on 10/20/24.
//

import Foundation
import RxSwift
import ReactorKit

final class ProfileHeaderViewReactor: Reactor {
    typealias Action = NoAction
    
    struct State {
        let user: User
    }
    
    let initialState: State
    
    init(user: User) {
        self.initialState = State(user: user)
    }
}
