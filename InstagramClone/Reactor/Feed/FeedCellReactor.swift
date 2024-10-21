//
//  FeedCellReactor.swift
//  InstagramClone
//
//  Created by 이상준 on 9/18/24.
//

import Foundation
import RxSwift
import ReactorKit

final class FeedCellReactor: Reactor {
    enum Action {
        case likeButtonTapped
    }
    
    enum Mutation {
        case setLiked(Bool)
        case setLikesCount(Int)
    }
    
    struct State {
        var post: Post
        var isLiked: Bool
        var likesCount: Int
    }
    
    let initialState: State
    
    init(post: Post) {
        self.initialState = State(post: post, isLiked: post.didLike, likesCount: post.likes)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .likeButtonTapped:
            let isLiked = !currentState.isLiked
            let post = currentState.post
            
            let likeObservable: Observable<Mutation> =
            
            isLiked ? PostService.likePost(post: post).map { result in
                switch result {
                case .success(_):
                    return Mutation.setLiked(true)
                case .failure(_):
                    return Mutation.setLiked(false)
                }
            } : PostService.unlikePost(post: post)
                .map { result in
                    switch result {
                    case .success(_):
                        return Mutation.setLiked(false)
                    case .failure(_):
                        return Mutation.setLiked(true)
                    }
                }
            
            let likesCountMutation = isLiked ? Mutation.setLikesCount(currentState.likesCount + 1) : Mutation.setLikesCount(currentState.likesCount - 1)
            
            return Observable.concat([
                likeObservable,
                Observable.just(likesCountMutation)
            ])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newstate = state
        
        switch mutation {
        case .setLiked(let isLiked):
            newstate.isLiked = isLiked
        case .setLikesCount(let likesCount):
            newstate.likesCount = likesCount
        }
        return newstate
    }
}
