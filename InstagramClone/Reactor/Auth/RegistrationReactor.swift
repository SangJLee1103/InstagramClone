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
            return Observable.concat([
                Observable.just(.setEmail(email)),
                validateForm()
            ])
            
        case .passwordChange(let password):
            return Observable.concat([
                Observable.just(.setPassword(password)),
                validateForm()
            ])
            
        case .fullnameChanged(let fullname):
            return Observable.concat([
                Observable.just(.setFullname(fullname)),
                validateForm()
            ])
            
        case .usernameChanged(let username):
            return Observable.concat([
                Observable.just(.setUsername(username)),
                validateForm()
            ])
            
        case .profileImageSelected(let profileImage):
            return Observable.concat([
                Observable.just(.setProfileImage(profileImage)),
                validateForm()
            ])
            
        case .signUp:
            return registerUser()
        }
    }
    
    private func validateForm() -> Observable<Mutation> {
        let isSignUpEnabled = !currentState.email.isEmpty &&
        !currentState.password.isEmpty &&
        !currentState.fullname.isEmpty &&
        !currentState.username.isEmpty &&
        currentState.profileImage != nil
        return Observable.just(Mutation.setSignUpEnabled(isSignUpEnabled))
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
            print("Signup completed mutation received")
            newstate.isSignupCompleted = true
        }
        
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
            .flatMap { _ -> Observable<Mutation> in
                print("User registered successfully")
                return Observable.just(.signupCompleted)
            }
            .catch { error in
                print("Error registering user: \(error.localizedDescription)")
                return Observable.just(Mutation.setError(error.localizedDescription))
            }
    }
}
