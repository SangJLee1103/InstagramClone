//
//  Constants.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/12.
//

import Firebase

let COLLECTION_USERS = Firestore.firestore().collection("users")
let COLLECTION_FOLLOWERS = Firestore.firestore().collection("followers")
let COLLECTION_FOLLOWING = Firestore.firestore().collection("followings")
let COLLECTION_POSTS = Firestore.firestore().collection("posts")
let COLLECTION_NOTIFICATIONS = Firestore.firestore().collection("notifications")
