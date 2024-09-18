//
//  FeedReactor.swift
//  InstagramClone
//
//  Created by 이상준 on 9/16/24.
//

import Foundation
import RxSwift
import ReactorKit

final class FeedReactor: Reactor {
    
    enum Action {
        case fetchPosts
        case refresh
        case checkIfUserLikedPosts
    }
    
    enum Mutation {
        case setPosts([Post])
        case refreshPosts([Post])
        case updatePostLikeStatus(postId: String, didLike: Bool)
    }
    
    struct State {
        var posts = [Post]()
    }
    
    let initialState = State()
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetchPosts:
            return fetchPosts().map { Mutation.setPosts($0) }
        case .refresh:
            return fetchPosts().map { Mutation.setPosts($0) }
        case .checkIfUserLikedPosts:
            return checkIfUserLikedPosts()
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newstate = state
        
        switch mutation {
        case .setPosts(let posts):
            newstate.posts = posts
        case .refreshPosts(let posts):
            newstate.posts = posts
        case .updatePostLikeStatus(let postId, let didLike):
            if let index = newstate.posts.firstIndex(where: { $0.postId == postId }) {
                newstate.posts[index].didLike = didLike
            }
        }
        
        return newstate
    }
    
    private func fetchPosts() -> Observable<[Post]> {
        return PostService.fetchPosts()
    }
    
    private func checkIfUserLikedPosts() -> Observable<Mutation> {
        let posts = currentState.posts
        let observables = posts.map { post in
            PostService.checkIfUserLikedPost(post: post)
                .map { didLike in
                    return Mutation.updatePostLikeStatus(postId: post.postId, didLike: didLike)
                }
        }
        return Observable.concat(observables)
    }
}
