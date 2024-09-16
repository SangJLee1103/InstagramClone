//
//  RegistrationReactor.swift
//  InstagramClone
//
//  Created by 이상준 on 9/13/24.
//

import RxSwift
import ReactorKit

final class RegistrationReactor: Reactor {
    
    enum Action {
        case emailChanged(String)
        case passwordChange(String)
        case fullnameChanged(String)
        case usernameChanged(String)
        case profileImageSelected(UIImage)
        case signUp
        case setError(String?)
    }
    
    enum Mutation {
        case setEmail(String)
        case setPassword(String)
        case setFullname(String)
        case setUsername(String)
        case setProfileImage(UIImage)
        case setSignUpEnabled(Bool)
        case signupCompleted
        case setError(String?)
    }
    
    struct State {
        var email: String = ""
        var password: String = ""
        var fullname: String = ""
        var username: String = ""
        var profileImage: UIImage?
        var isSignUpEnabled: Bool = false
        var errorMessage: String?
        var isSignupCompleted: Bool = false
    }
    
    let initialState = State()
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .emailChanged(let email):
            return Observable.just(.setEmail(email))
        case .passwordChange(let password):
            return Observable.just(.setPassword(password))
        case .fullnameChanged(let fullname):
            return Observable.just(.setFullname(fullname))
        case .usernameChanged(let username):
            return Observable.just(.setUsername(username))
        case .profileImageSelected(let profileImage):
            return Observable.just(.setProfileImage(profileImage))
        case .signUp:
            return registerUser()
        case .setError(let errorMessage):
            return Observable.just(Mutation.setError(errorMessage))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newstate = state
        
        switch mutation {
        case .setEmail(let email):
            newstate.email = email
        case .setPassword(let password):
            newstate.password = password
        case .setFullname(let fullname):
            newstate.fullname = fullname
        case .setUsername(let username):
            newstate.username = username
        case .setProfileImage(let profileImage):
            newstate.profileImage = profileImage
        case .setSignUpEnabled(let isEnabled):
            newstate.isSignUpEnabled = isEnabled
        case .setError(let errorMessage):
            newstate.errorMessage = errorMessage
        case .signupCompleted:
            newstate.isSignupCompleted = true
        }
        
        newstate.isSignUpEnabled = !newstate.email.isEmpty && !newstate.password.isEmpty && !newstate.fullname.isEmpty && !newstate.username.isEmpty && newstate.profileImage != nil
        
        return newstate
    }
    
    private func registerUser() -> Observable<Mutation> {
        let email = currentState.email
        let password = currentState.password
        let fullname = currentState.fullname
        let username = currentState.username
        
        guard let profileImage = currentState.profileImage else {
            return Observable.empty()
        }
        
        let credentials = AuthCredentials(email: email, password: password, fullname: fullname, username: username, profileImage: profileImage)
        
        return AuthService.registerUser(withCredential: credentials)
            .map { _ in
                return Mutation.signupCompleted
            }
            .catch { error in
                let authError = AuthError.from(error)
                let errorMessage = authError.errorMessage
                print("DEBUG: Error registering user: \(error.localizedDescription)")
                return Observable.just(Mutation.setError(errorMessage))
            }
    }
}
