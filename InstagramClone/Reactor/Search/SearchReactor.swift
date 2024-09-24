//
//  SearchReactor.swift
//  InstagramClone
//
//  Created by 이상준 on 9/24/24.
//

import Foundation
import RxSwift
import ReactorKit

final class SearchReactor: Reactor {
    enum Action {
        case fetchUsers
        case search(String)
    }
    
    enum Mutation {
        case setUsers([User])
        case setFilteredUsers([User])
    }
    
    struct State {
        var users = [User]()
        var filteredUsers = [User]()
        var isSearchMode: Bool = false
    }
    
    let initialState = State()
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetchUsers:
            return fetchUsers().map { Mutation.setUsers($0) }
        case .search(let query):
            let filteredUsers = currentState.users.filter {
                $0.username.lowercased().contains(query.lowercased()) ||
                $0.fullname.lowercased().contains(query.lowercased())
            }
            return Observable.just(Mutation.setFilteredUsers(filteredUsers))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setUsers(let users):
            newState.users = users
        case .setFilteredUsers(let filteredUsers):
            newState.filteredUsers = filteredUsers
            newState.isSearchMode = !filteredUsers.isEmpty
        }
        return newState
    }
    
    private func fetchUsers() -> Observable<[User]> {
        return Observable.create { observer in
            UserService.fetchUsers { users in
                observer.onNext(users)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}
