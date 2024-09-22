//
//  CommentReactor.swift
//  InstagramClone
//
//  Created by 이상준 on 9/21/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import RxSwift
import ReactorKit

final class CommentReactor: Reactor {
    
    enum Action {
        case fetchComments
        case uploadComment(String)
    }
    
    enum Mutation {
        case setComments([Comment])
        case appendComment(Comment)
        case setLoading(Bool)
    }
    
    struct State {
        var comments = [Comment]()
        var isLoading: Bool = false
    }
    
    let initialState = State()
    private let post: Post
    
    init(post: Post) {
        self.post = post
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetchComments:
            return fetchComments(postId: post.postId).map { Mutation.setComments($0) }
        case .uploadComment(let commentText):
            return Observable.concat([
                Observable.just(Mutation.setLoading(true)),
                uploadComment(comment: commentText).map { result in
                    switch result {
                    case .success(let comment):
                        return Mutation.appendComment(comment)
                    case .failure(let error):
                        print("Uploaded Failed: \(error.localizedDescription)")
                        return Mutation.setLoading(false)
                    }
                },
                Observable.just(Mutation.setLoading(false))
            ])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newstate = state
        
        switch mutation {
        case .setComments(let comments):
            newstate.comments = comments
        case .appendComment(let comment):
            newstate.comments.append(comment)
        case .setLoading(let isLoading):
            newstate.isLoading = isLoading
        }
        return newstate
    }
    
    private func fetchComments(postId: String) -> Observable<[Comment]> {
        return CommentService.fetchComments(forPost: postId)
    }
    
    private func uploadComment(comment: String) -> Observable<Result<Comment, FirebaseError>> {
        guard let currentUser = UserManager.shared.currentUser else {
            return Observable.just(.failure(.missingAppToken))
        }
        
        return CommentService.uploadComment(comment: comment, postID: post.postId, user: currentUser).flatMap { result -> Observable<Result<Comment, FirebaseError>> in
            switch result {
            case .success:
                let commentData: [String: Any] = [
                    "uid": currentUser.uid,
                    "username": currentUser.username,
                    "profileImageUrl": currentUser.profileImageUrl,
                    "timestamp": Timestamp(date: Date()),
                    "comment": comment
                ]
                let newComment = Comment(dictionary: commentData)
                return Observable.just(.success((newComment)))
            case .failure(let error):
                return Observable.just(.failure(error))
            }
        }
    }
}
