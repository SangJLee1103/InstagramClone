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
        case setError(String?)
    }
    
    enum Mutation {
        case setComments([Comment])
        case appendComment(Comment)
        case setLoading(Bool)
        case setError(String?)
    }
    
    struct State {
        var comments = [Comment]()
        var isLoading: Bool = false
        var errorMessage: String?
    }
    
    let initialState = State()
    private let post: Post
    
    init(post: Post) {
        self.post = post
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetchComments:
            return fetchComments(postId: post.postId)
                .map { Mutation.setComments($0) }
            
        case .uploadComment(let commentText):
            return handleLoading(uploadCommentAndNotify(commentText: commentText))
            
        case .setError(let errorMessage):
            return Observable.just(.setError(errorMessage))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setComments(let comments):
            newState.comments = comments
        case .appendComment(let comment):
            newState.comments.append(comment)
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setError(let error):
            newState.errorMessage = error
        }
        
        return newState
    }
    
    private func uploadCommentAndNotify(commentText: String) -> Observable<Mutation> {
        return uploadComment(comment: commentText)
            .flatMap { result in
                self.handleUploadResult(result)
            }
    }
    
    private func uploadComment(comment: String) -> Observable<Result<Comment, FirebaseError>> {
        guard let currentUser = UserManager.shared.currentUser else {
            return Observable.just(.failure(.missingAppToken))
        }
        
        return CommentService.uploadComment(comment: comment, postID: post.postId, user: currentUser).map { result in
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
                return .success(newComment)
            case .failure(let error):
                return .failure(error)
            }
        }
    }
    
    private func handleUploadResult(_ result: Result<Comment, FirebaseError>) -> Observable<Mutation> {
        switch result {
        case .success(let comment):
            return uploadNotification(comment: comment)
                .flatMap { notificationResult in
                    switch notificationResult {
                    case .success:
                        return Observable.just(Mutation.appendComment(comment))
                    case .failure(let error):
                        return Observable.just(Mutation.setError(error.localizedDescription))
                    }
                }
        case .failure(let error):
            return Observable.just(Mutation.setError(error.localizedDescription))
        }
    }
    
    private func fetchComments(postId: String) -> Observable<[Comment]> {
        return CommentService.fetchComments(forPost: postId)
    }
    
    private func handleLoading(_ action: Observable<Mutation>) -> Observable<Mutation> {
        return Observable.concat([
            Observable.just(Mutation.setLoading(true)),
            action,
            Observable.just(Mutation.setLoading(false))
        ])
    }
    
    private func uploadNotification(comment: Comment) -> Observable<Result<Void, FirebaseError>> {
        guard let currentUser = UserManager.shared.currentUser else {
            return Observable.just(.failure(.missingAppToken))
        }
        return NotificationService.uploadNotificationRx(toUid: post.ownerUid, fromUser: currentUser, type: .comment)
    }
}
