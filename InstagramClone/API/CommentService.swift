//
//  CommentService.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/18.
//

import Firebase
import FirebaseFirestore
import RxSwift

struct CommentService {
    
    static func uploadComment(comment: String, postID: String, user: User) -> Observable<Result<Void, FirebaseError>> {
        return .create { observer in
            guard let uid = Auth.auth().currentUser?.uid else {
                observer.onNext(.failure(.missingAppToken))
                observer.onCompleted()
                return Disposables.create()
            }
            
            let data: [String: Any] = [
                "uid": user.uid,
                "comment": comment,
                "timestamp": Timestamp(date: Date()),
                "username": user.username,
                "profileImageUrl": user.profileImageUrl
            ]
            
            COLLECTION_POSTS.document(postID).collection("comments").addDocument(data: data) { error in
                
                if let error = error {
                    let error = FirebaseError.from(error)
                    observer.onNext(.failure(error))
                } else {
                    observer.onNext(.success(()))
                }
                observer.onCompleted()
            }
        }
    }
    
    static func fetchComments(forPost postID: String) -> Observable<[Comment]> {
        return Observable.create { observer in
            let query = COLLECTION_POSTS.document(postID).collection("comments")
                .order(by: "timestamp", descending: true)
            
            query.addSnapshotListener { snapshot, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                var comments = [Comment]()
                snapshot?.documentChanges.forEach { change in
                    if change.type == .added {
                        let data = change.document.data()
                        let comment = Comment(dictionary: data)
                        comments.append(comment)
                    }
                }
                observer.onNext(comments)
            }
            return Disposables.create()
        }
    }
}
