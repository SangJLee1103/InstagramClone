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
        case setSinglePost(Post)
        case refreshPosts([Post])
        case updatePostLikeStatus(postId: String, didLike: Bool)
    }
    
    struct State {
        var posts = [Post]()
        var post: Post? = nil
    }
    
    let initialState: State
    
    init(initialPost: Post?) {
        self.initialState = State(posts: [], post: initialPost)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetchPosts:
            if let post = currentState.post {
                return .just(.setSinglePost(post))
            } else {
                return fetchPosts().map { Mutation.setPosts($0) }
            }
        case .refresh:
            return fetchPosts().map { Mutation.setPosts($0) }
        case .checkIfUserLikedPosts:
            return checkIfUserLikedPosts()
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setPosts(let posts):
            newState.posts = posts
        case .setSinglePost(let post):
            newState.post = post
        case .refreshPosts(let posts):
            newState.posts = posts
        case .updatePostLikeStatus(let postId, let didLike):
            if let post = newState.post, post.postId == postId {
                newState.post?.didLike = didLike
            } else if let index = newState.posts.firstIndex(where: { $0.postId == postId }) {
                newState.posts[index].didLike = didLike
            }
        }
        return newState
    }
    
    private func fetchPosts() -> Observable<[Post]> {
        return PostService.fetchPosts()
    }
    
    private func checkIfUserLikedPosts() -> Observable<Mutation> {
        if let post = currentState.post {
            return PostService.checkIfUserLikedPost(post: post)
                .map { didLike in
                    return Mutation.updatePostLikeStatus(postId: post.postId, didLike: didLike)
                }
        } else {
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
}
