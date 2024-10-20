//
//  ProfileCellReactor.swift
//  InstagramClone
//
//  Created by 이상준 on 10/20/24.
//

import Foundation
import RxSwift
import ReactorKit

final class ProfileCellReactor: Reactor {
    typealias Action = NoAction
    
    struct State {
        var post: Post
    }
    
    let initialState: State
    
    init(post: Post) {
        self.initialState = State(post: post)
    }
}
