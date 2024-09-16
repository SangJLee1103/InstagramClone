//
//  AuthError.swift
//  InstagramClone
//
//  Created by 이상준 on 9/14/24.
//

import Foundation
import Firebase

enum AuthError: Error {
    case unknown
    case invalidEmail
    case emailAlreadyInUse
    case weakPassword
    case wrongPassword
    case userNotFound
    case networkError
    case userDisabled
    
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
        case .unknown:
            return "로그인에 실패 하였습니다."
        }
    }
    
    static func from(_ error: Error) -> AuthError {
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
            default:
                return .unknown
            }
        }
        return .unknown
    }
}
