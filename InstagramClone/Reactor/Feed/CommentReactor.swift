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
        var comments: [Comment] = []
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
            return fetchComments()
                .map { fetchedComments in
                    let allComments = fetchedComments + self.currentState.comments
                    return Mutation.setComments(allComments)
                }
            
        case .uploadComment(let commentText):
            return Observable.concat([
                setLoading(true),
                setLoading(false),
                uploadCommentAndNotify(commentText),
            ])
            
        case .setError(let errorMessage):
            return .just(.setError(errorMessage))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setComments(let comments):
            newState.comments = comments
        case .appendComment(let comment):
            newState.comments.insert(comment, at: 0)
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setError(let error):
            newState.errorMessage = error
        }
        
        return newState
    }
    
    // 댓글 업로드 후 알림 처리
    private func uploadCommentAndNotify(_ commentText: String) -> Observable<Mutation> {
        return uploadComment(commentText)
            .flatMap(handleUploadResult)
            .catch { error in
                return .just(.setError(error.localizedDescription))
            }
    }
    
    // 댓글 업로드
    private func uploadComment(_ commentText: String) -> Observable<Result<Comment, FirebaseError>> {
        guard let currentUser = UserManager.shared.currentUser else {
            return .just(.failure(.missingAppToken))
        }
        
        return CommentService.uploadComment(comment: commentText, postID: post.postId, user: currentUser)
            .map { result in
                switch result {
                case .success:
                    let commentData: [String: Any] = [
                        "uid": currentUser.uid,
                        "username": currentUser.username,
                        "profileImageUrl": currentUser.profileImageUrl,
                        "timestamp": Timestamp(date: Date()),
                        "comment": commentText
                    ]
                    let newComment = Comment(dictionary: commentData)
                    return .success(newComment)
                case .failure(let error):
                    return .failure(error)
                }
            }
    }
    
    // 업로드 후 결과 처리
    private func handleUploadResult(_ result: Result<Comment, FirebaseError>) -> Observable<Mutation> {
        switch result {
        case .success(let comment):
            return uploadNotification(comment)
                .flatMap { notificationResult -> Observable<Mutation> in
                    switch notificationResult {
                    case .success:
                        return Observable.empty()
                    case .failure(let error):
                        return Observable.just(Mutation.setError(error.localizedDescription))
                    }
                }
        case .failure(let error):
            return .just(Mutation.setError(error.localizedDescription))
        }
    }
    
    // 알림 업로드
    private func uploadNotification(_ comment: Comment) -> Observable<Result<Void, FirebaseError>> {
        guard let currentUser = UserManager.shared.currentUser else {
            return .just(.failure(.missingAppToken))
        }
        
        return NotificationService.uploadNotificationRx(
            toUid: post.ownerUid,
            fromUser: currentUser,
            type: .comment,
            post: post
        )
    }
    
    // 댓글 불러오기
    private func fetchComments() -> Observable<[Comment]> {
        return CommentService.fetchComments(forPost: post.postId)
    }
    
    // 로딩 상태 업데이트
    private func setLoading(_ isLoading: Bool) -> Observable<Mutation> {
        return .just(.setLoading(isLoading))
    }
}
