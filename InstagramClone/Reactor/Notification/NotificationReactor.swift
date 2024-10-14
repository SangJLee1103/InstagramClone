//
//  NotificationReactor.swift
//  InstagramClone
//
//  Created by 이상준 on 10/4/24.
//

import Foundation
import RxSwift
import ReactorKit

final class NotificationReactor: Reactor {
    enum Action {
        case fetchNotifications
        case checkIfUserIsFollowed(String)
        case follow(String)
        case unfollow(String)
        case fetchPostWithId(String)
        case refresh
    }
    
    enum Mutation {
        case setNotifications([Notification])
        case setFollowed(Bool, index: Int)
        case showPost(Post)
        case refresh([Notification])
        case setLoading(Bool)
        case setError(String?)
    }
    
    struct State {
        var notifications = [Notification]()
        var isLoading: Bool = false
        var errorMessage: String?
        var selectedPost: Post?
    }
    
    let initialState = State()
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetchNotifications:
            return Observable.concat([
                Observable.just(Mutation.setLoading(true)),
                Observable.just(Mutation.setLoading(false)),
                fetchNotifications().map { Mutation.setNotifications($0) }
            ])
        case .checkIfUserIsFollowed(let uid):
            return Observable.from(currentState.notifications.enumerated())
                .filter { index, notification in
                    notification.type == .follow && notification.uid == uid
                }
                .flatMap { index, notification in
                    self.checkIfUserIsFollowed()
                        .map { isFollowed in
                            return Mutation.setFollowed(isFollowed, index: index)
                        }
                }
                .catch { error in
                    return .just(Mutation.setError(error.localizedDescription))
                }
            
        case .follow(let uid):
            return follow(uid: uid)
                .flatMap { _ -> Observable<Mutation> in
                    if let index = self.currentState.notifications.firstIndex(where: { $0.uid == uid }) {
                        return .just(Mutation.setFollowed(true, index: index))
                    }
                    return .empty()
                }
                .catch { error in
                    return .just(Mutation.setError(error.localizedDescription))
                }
        case .unfollow(let uid):
            return unFollow(uid: uid)
                .flatMap { _ -> Observable<Mutation> in
                    if let index = self.currentState.notifications.firstIndex(where: { $0.uid == uid }) {
                        return .just(Mutation.setFollowed(false, index: index))
                    }
                    return .empty()
                }
                .catch { error in
                    return .just(Mutation.setError(error.localizedDescription))
                }
        case .fetchPostWithId(let postId):
            return PostService.fetchPost(withPostId: postId)
                .map {
                    return Mutation.showPost($0)
                }
                .catch { error in
                    return .just(Mutation.setError(error.localizedDescription))
                }
        case .refresh:
            return Observable.concat([
                Observable.just(Mutation.setLoading(true)),
                Observable.just(Mutation.setLoading(false)),
                fetchNotifications().map { Mutation.refresh($0) },
            ])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setNotifications(let notifications):
            newState.notifications = notifications
        case .setFollowed(let isFollowed, let index):
            newState.notifications[index].userIsFollwed = isFollowed
        case .showPost(let post):
            newState.selectedPost = post
        case .refresh(let notifications):
            newState.notifications = notifications
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setError(let errorMessage):
            newState.errorMessage = errorMessage
        }
        return newState
    }
    
    private func fetchNotifications() -> Observable<[Notification]> {
        return NotificationService.fetchNotification()
    }
    
    private func checkIfUserIsFollowed() -> Observable<Bool> {
        return UserService.checkIfUserIsFollowedRx()
    }
    
    private func follow(uid: String) -> Observable<Void> {
        return UserService.followRx(uid: uid)
    }
    
    private func unFollow(uid: String) -> Observable<Void> {
        return UserService.unfollowRx(uid: uid)
    }
}
