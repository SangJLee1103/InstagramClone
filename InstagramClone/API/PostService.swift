//
//  PostService.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/16.
//

import UIKit
import RxSwift
import Firebase
import FirebaseFirestore

struct PostService {
    
    static func uploadPost(caption: String, image: UIImage, user: User, completion: @escaping(FirestoreCompletion)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        ImageUploader.uploadImage(image: image) { imageUrl in
            let data = [
                "caption": caption,
                "timestamp": Timestamp(date: Date()),
                "likes": 0,
                "imageUrl": imageUrl,
                "ownerUid": uid,
                "ownerImageUrl": user.profileImageUrl,
                "ownerUsername": user.username + user.fullname
            ] as [String : Any]
            
            COLLECTION_POSTS.addDocument(data: data, completion: completion)
        }
    }
    
    static func fetchPosts() -> Observable<[Post]> {
        return .create { observer in
            COLLECTION_POSTS.order(by: "timestamp", descending: true).getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let posts = documents.map({ Post(postId: $0.documentID, dictionary: $0.data()) })
                observer.onNext(posts)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    static func fetchPosts(forUser uid: String, completion: @escaping([Post]) -> Void) {
        let query = COLLECTION_POSTS.whereField("ownerUid", isEqualTo: uid)
        
        query.getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            
            var posts = documents.map({ Post(postId: $0.documentID, dictionary: $0.data()) })
            
            posts.sort { (post1, post2) -> Bool in
                return post1.timestamp.seconds > post2.timestamp.seconds
            }
            completion(posts)
        }
    }
    
    static func fetchPost(withPostId postId: String) -> Observable<Post> {
        return Observable.create { observer in
            let document = COLLECTION_POSTS.document(postId)
            
            document.getDocument { snapshot, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                guard let snapshot = snapshot, let data = snapshot.data() else {
                    observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Data not found."]))
                    return
                }
                
                let post = Post(postId: snapshot.documentID, dictionary: data)
                observer.onNext(post)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    static func likePost(post: Post) -> Observable<Result<Void, FirebaseError>> {
        return .create { observer in
            guard let uid = Auth.auth().currentUser?.uid else {
                observer.onNext(.failure(.missingAppToken))
                observer.onCompleted()
                return Disposables.create()
            }
            
            COLLECTION_POSTS.document(post.postId).updateData(["likes": post.likes + 1])
            
            COLLECTION_POSTS.document(post.postId).collection("post-likes").document(uid).setData([:]) { _ in
                COLLECTION_USERS.document(uid).collection("user-likes").document(post.postId)
                    .setData([:]) { error in
                        if let error = error {
                            let error = FirebaseError.from(error)
                            observer.onNext(.failure(error))
                        } else {
                            observer.onNext(.success(()))
                        }
                        observer.onCompleted()
                    }
            }
            return Disposables.create()
        }
    }
    
    static func unlikePost(post: Post) -> Observable<Result<Void, FirebaseError>> {
        return .create { observer in
            guard let uid = Auth.auth().currentUser?.uid else {
                observer.onNext(.failure(.missingAppToken))
                observer.onCompleted()
                return Disposables.create()
            }
            
            guard post.likes > 0 else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            COLLECTION_POSTS.document(post.postId).updateData(["likes": post.likes - 1])
            
            COLLECTION_POSTS.document(post.postId).collection("post-likes").document(uid).delete { _ in
                COLLECTION_USERS.document(uid).collection("user-likes").document(post.postId)
                    .delete { error in
                        if let error = error {
                            let error = FirebaseError.from(error)
                            observer.onNext(.failure(error))
                        } else {
                            observer.onNext(.success(()))
                        }
                        observer.onCompleted()
                    }
            }
            return Disposables.create()
        }
    }
    
    static func checkIfUserLikedPost(post: Post) -> Observable<Bool> {
        return Observable.create { observer in
            guard let uid = Auth.auth().currentUser?.uid else {
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }
            
            COLLECTION_USERS.document(uid).collection("user-likes").document(post.postId).getDocument { (snapshot, _) in
                let didLike = snapshot?.exists ?? false
                observer.onNext(didLike)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
}
