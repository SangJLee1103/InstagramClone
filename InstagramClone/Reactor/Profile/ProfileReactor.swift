//
//  ProfileReactor.swift
//  InstagramClone
//
//  Created by 이상준 on 10/19/24.
//

import Foundation
import ReactorKit
import RxSwift

final class ProfileReactor: Reactor {
    enum Action {
        case checkIfUserIsFollowed
        case follow
        case unfollow
        case fetchUserStats
        case fetchPosts
    }
    
    enum Mutation {
        case setFollowed(Bool)
        case setUserStats(UserStats)
        case setPosts([Post])
    }
    
    struct State {
        var user: User
        var posts = [Post]()
    }
    
    let initialState: State
    
    init(user: User) {
        self.initialState = State(user: user)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        let uid = currentState.user.uid
        
        switch action {
        case .checkIfUserIsFollowed:
            return checkIfUserIsFollowed(uid: uid)
                .map { isFollowed in
                    Mutation.setFollowed(isFollowed)
                }
        case .follow:
            return follow(uid: uid)
                .map {
                    Mutation.setFollowed(true)
                }
        case .unfollow:
            return unFollow(uid: uid)
                .map {
                    Mutation.setFollowed(false)
                }
        case .fetchUserStats:
            return fetchUserStats(uid: uid).map { Mutation.setUserStats($0) }
        case .fetchPosts:
            return fetchPosts(uid: uid).map { Mutation.setPosts($0) }
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setFollowed(let isFollowed):
            newState.user.isFollowed = isFollowed
        case .setUserStats(let userStats):
            newState.user.stats = userStats
        case .setPosts(let posts):
            newState.posts = posts
        }
        return newState
    }
    
    private func checkIfUserIsFollowed(uid: String) -> Observable<Bool> {
        return UserService.checkIfUserIsFollowed(uid: uid)
    }
    
    private func fetchUserStats(uid: String) -> Observable<UserStats> {
        return UserService.fetchUserStats(uid: uid)
    }
    
    private func follow(uid: String) -> Observable<Void> {
        return UserService.follow(uid: uid)
    }
    
    private func unFollow(uid: String) -> Observable<Void> {
        return UserService.unfollow(uid: uid)
    }
    
    private func fetchPosts(uid: String) -> Observable<[Post]> {
        return PostService.fetchPosts(forUser: uid)
    }
}
