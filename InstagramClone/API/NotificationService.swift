//
//  NotificationService.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/20.
//

import RxSwift
import Firebase
import FirebaseFirestore

struct NotificationService {
    
    /// uploadNotification Rx
    static func uploadNotificationRx(toUid uid: String, fromUser: User, type: NotificationType, post: Post? = nil) -> Observable<Result<Void, FirebaseError>> {
        return .create { observer in
            guard let currentUid = Auth.auth().currentUser?.uid else {
                observer.onNext(.failure(.missingAppToken))
                observer.onCompleted()
                return Disposables.create()
            }
            guard uid != currentUid else {
                return Disposables.create()
            }
            let docRef = COLLECTION_NOTIFICATIONS.document(uid).collection("user-notifications").document()
            
            var data: [String: Any] = [
                "timestamp": Timestamp(date: Date()),
                "uid": fromUser.uid,
                "type": type.rawValue,
                "id": docRef.documentID,
                "userProfileImageUrl": fromUser.profileImageUrl,
                "username": fromUser.username
            ]
            
            if let post = post {
                data["postId"] = post.postId
                data["postImageUrl"] = post.imageUrl
            }
            
            docRef.setData(data) { error in
                if let error = error {
                    observer.onNext(.failure(.from(error)))
                } else {
                    observer.onNext(.success(()))
                }
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    static func uploadNotification(toUid uid: String, fromUser: User, type: NotificationType, post: Post? = nil) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        guard uid != currentUid else { return }
        
        let docRef = COLLECTION_NOTIFICATIONS.document(uid).collection("user-notifications").document()
        
        var data: [String: Any] = [
            "timestamp": Timestamp(date: Date()),
            "uid": fromUser.uid,
            "type": type.rawValue,
            "id": docRef.documentID,
            "userProfileImageUrl": fromUser.profileImageUrl,
            "username": fromUser.username
        ]
        
        if let post = post {
            data["postId"] = post.postId
            data["postImageUrl"] = post.imageUrl
        }
        docRef.setData(data)
    }
    
    static func fetchNotifications(completion: @escaping([Notification]) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        COLLECTION_NOTIFICATIONS.document(uid).collection("user-notifications").getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            let notifications = documents.map({ Notification(dictionary: $0.data()) })
            completion(notifications)
        }
    }
    
    static func fetchNotification() -> Observable<[Notification]> {
        return .create { observer in
            guard let uid = Auth.auth().currentUser?.uid else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            COLLECTION_NOTIFICATIONS.document(uid).collection("user-notifications").getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else { return }
                    let notifications = documents.map({ Notification(dictionary: $0.data()) })
                    observer.onNext(notifications)
                    observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}
