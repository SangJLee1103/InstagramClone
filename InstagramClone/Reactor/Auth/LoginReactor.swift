//
//  LoginReactor.swift
//  InstagramClone
//
//  Created by 이상준 on 9/15/24.
//

import Foundation
import ReactorKit

final class LoginReactor: Reactor {
    
    enum Action {
        case emailChanged(String)
        case passwordChanged(String)
        case setError(String?)
        case login
    }
    
    enum Mutation {
        case setEmail(String)
        case setPassword(String)
        case setLoginEnabled(Bool)
        case setError(String?)
        case loginCompleted
    }
    
    struct State {
        var email: String = ""
        var password: String = ""
        var isLoginEnabled: Bool = false
        var errorMessage: String?
        var isLoginCompleted: Bool = false
    }
    
    let initialState = State()
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .emailChanged(let email):
            return Observable.just(.setEmail(email))
        case .passwordChanged(let password):
            return Observable.just(.setPassword(password))
        case .setError(let errorMessage):
            return Observable.just(.setError(errorMessage))
        case .login:
            return login()
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newstate = state
        
        switch mutation {
        case .setEmail(let email):
            newstate.email = email
        case .setPassword(let password):
            newstate.password = password
        case .setLoginEnabled(let isEnabled):
            newstate.isLoginEnabled = isEnabled
        case .setError(let error):
            newstate.errorMessage = error
        case .loginCompleted:
            newstate.isLoginCompleted = true
        }
        
        newstate.isLoginEnabled = !newstate.email.isEmpty && !newstate.password.isEmpty
        return newstate
    }
    
    private func login() -> Observable<Mutation> {
        let email = currentState.email
        let password = currentState.password
        
        return AuthService.loginUserIn(withEmail: email, password: password)
            .map { _ in
                return Mutation.loginCompleted
            }
            .catch { error in
                let authError = FirebaseError.from(error)
                let errorMessage = authError.errorMessage
                print("DEBUG: Error Login user: \(error.localizedDescription)")
                return Observable.just(Mutation.setError(errorMessage))
            }
    }
}
