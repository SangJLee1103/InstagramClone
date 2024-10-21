//
//  UserCellReactor.swift
//  InstagramClone
//
//  Created by 이상준 on 10/22/24.
//

import Foundation
import RxSwift
import ReactorKit

final class UserCellReactor: Reactor {
    typealias Action = NoAction

    struct State {
        var user: User
    }
    
    let initialState: State
    
    init(user: User) {
        self.initialState = State(user: user)
    }
}
