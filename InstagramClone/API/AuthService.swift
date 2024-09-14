//
//  AuthService.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/12.
//

import UIKit
import Firebase
import RxSwift

struct AuthCredentials {
    let email: String
    let password: String
    let fullname: String
    let username: String
    let profileImage: UIImage
}

struct AuthService {
    static func loginUserIn(withEmail email: String, password: String, completion: @escaping(AuthDataResult?, Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password, completion: completion )
    }
    
    static func registerUser(withCredential credentials: AuthCredentials) -> Observable<Void> {
        return .create { observer in
            ImageUploader.uploadImage(image: credentials.profileImage) { imageUrl in
                Auth.auth().createUser(withEmail: credentials.email, password: credentials.password) { (result, error) in
                    if let error = error {
                        observer.onError(error)
                        return
                    }
                    
                    guard let uid = result?.user.uid else { return }
                    
                    let data: [String: Any] = [
                        "email": credentials.email,
                        "fullname": credentials.fullname,
                        "profileImageUrl": imageUrl,
                        "uid": uid,
                        "username": credentials.username
                    ]
                    
                    COLLECTION_USERS.document(uid).setData(data) { error in
                        if let error = error {
                            observer.onError(error)
                        } else {
                            observer.onCompleted()
                        }
                    }
                }
            }
            return Disposables.create()
        }
    }
}
