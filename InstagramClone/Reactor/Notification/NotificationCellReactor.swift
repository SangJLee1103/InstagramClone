//
//  NotificationCellReactor.swift
//  InstagramClone
//
//  Created by 이상준 on 10/8/24.
//

import ReactorKit
import RxSwift

final class NotificationCellReactor: Reactor {
    typealias Action = NoAction
    
    struct State {
        let notification: Notification
    }
    
    let initialState: State
    
    init(notification: Notification) {
        self.initialState = State(notification: notification)
    }
}
