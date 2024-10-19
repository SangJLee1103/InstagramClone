//
//  UserService.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/12.
//

import Firebase
import RxSwift

typealias FirestoreCompletion = (Error?) -> Void

struct UserService {
    
    // 유저 정보 가져오기
    static func fetchUser(withUid uid: String, completion: @escaping(User) -> Void ) {
        COLLECTION_USERS.document(uid).getDocument { snapshot, error in
            guard let dictionary = snapshot?.data() else { return }
            let user = User(dictionary: dictionary)
            completion(user)
        }
    }
    
    // 전체 유저 정보 가져오기
    static func fetchUsers(completion: @escaping([User]) -> Void) {
        COLLECTION_USERS.getDocuments { snapshot, error in
            guard let snapshot = snapshot else { return }
            let users = snapshot.documents.map{ User(dictionary: $0.data())}
            completion(users)
        }
    }
    
    static func follow(uid: String) -> Observable<Void> {
        return .create { observer in
            guard let currentUid = Auth.auth().currentUser?.uid else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            COLLECTION_FOLLOWING.document(currentUid).collection("user-following").document(uid).setData([:]) { error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                COLLECTION_FOLLOWERS.document(uid).collection("user-followers").document(currentUid).setData([:]) { error in
                    if let error = error {
                        observer.onError(error)
                    } else {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                }
            }
            return Disposables.create()
        }
        
    }
    
    static func unfollow(uid: String) -> Observable<Void> {
        return .create { observer in
            guard let currentUid = Auth.auth().currentUser?.uid else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            COLLECTION_FOLLOWING.document(currentUid).collection("user-following").document(uid).delete { error in
                
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                COLLECTION_FOLLOWERS.document(uid).collection("user-followers").document(currentUid).delete() { error in
                    if let error = error {
                        observer.onError(error)
                    } else {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                }
            }
            return Disposables.create()
        }
    }
    
    // 유저를 팔로우 했는지 안했는지 체크하는 함수
    static func checkIfUserIsFollowed(uid: String) -> Observable<Bool> {
        return .create { observer in
            guard let currentUid = Auth.auth().currentUser?.uid else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            COLLECTION_FOLLOWING.document(currentUid).collection("user-following").document(uid).getDocument { (snapshot, error) in
                if let error = error {
                    observer.onError(error)
                } else {
                    let isFollowed = snapshot?.exists ?? false
                    observer.onNext(isFollowed)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    // 유저의 팔로우, 팔로잉, 포스팅 정보 가져오기
    static func fetchUserStats(uid: String) -> Observable<UserStats> {
        return .create { observer in
            
            COLLECTION_FOLLOWERS.document(uid).collection("user-followers").getDocuments { snapshot, error in
                let followers = snapshot?.documents.count ?? 0
                
                COLLECTION_FOLLOWING.document(uid).collection("user-following").getDocuments { snapshot, error in
                    let following = snapshot?.documents.count ?? 0
                    
                    COLLECTION_POSTS.whereField("ownerUid", isEqualTo: uid).getDocuments { snapshot, error in
                        let posts = snapshot?.documents.count ?? 0
                        observer.onNext(UserStats(followers: followers, following: following, posts: posts))
                        observer.onCompleted()
                    }
                }
            }
            
            return Disposables.create()
        }
    }
}
