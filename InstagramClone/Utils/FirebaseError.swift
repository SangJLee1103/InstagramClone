//
//  AuthError.swift
//  InstagramClone
//
//  Created by 이상준 on 9/14/24.
//

import Foundation
import Firebase

enum FirebaseError: Error {
    case invalidEmail
    case emailAlreadyInUse
    case weakPassword
    case wrongPassword
    case userNotFound
    case networkError
    case userDisabled
    case userTokenExpired
    case missingAppToken
    case unknown
    
    // 에러 메시지를 한글로 반환하는 메서드
    var errorMessage: String {
        switch self {
        case .invalidEmail:
            return "잘못된 이메일 형식입니다."
        case .emailAlreadyInUse:
            return "이미 사용 중인 이메일입니다."
        case .weakPassword:
            return "비밀번호는 6자 이상이어야 합니다."
        case .wrongPassword, .userNotFound:
            return "이메일 혹은 비밀번호가 일치하지 않습니다."
        case .networkError:
            return "네트워크 연결에 실패 하였습니다."
        case .userDisabled:
            return "해당 계정은 비활성화되어 있습니다."
        case .userTokenExpired:
            return "로그인이 만료되었습니다. 다시 로그인해주세요."
        case .missingAppToken:
            return "인증 정보가 없습니다. 다시 로그인해주세요."
        case .unknown:
            return "로그인에 실패 하였습니다."
        }
    }
    
    static func from(_ error: Error) -> FirebaseError {
        let errorCode = (error as NSError).code
        if let authErrorCode = AuthErrorCode.Code(rawValue: errorCode) {
            switch authErrorCode {
            case .invalidEmail:
                return .invalidEmail
            case .emailAlreadyInUse:
                return .emailAlreadyInUse
            case .weakPassword:
                return .weakPassword
            case .wrongPassword, .userNotFound:
                return .wrongPassword
            case .networkError:
                return .networkError
            case .userDisabled:
                return .userDisabled
            case .userTokenExpired:
                return .userTokenExpired
            case .missingAppToken:
                return .missingAppToken
            default:
                return .unknown
            }
        }
        return .unknown
    }
}
