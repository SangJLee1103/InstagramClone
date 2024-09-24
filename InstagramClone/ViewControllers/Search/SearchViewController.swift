//
//  SearchViewController.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/10.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit

private let reuseIdentifier = "UserCell"


final class SearchViewController: UITableViewController {
    
    //    private var users = [User]()
    //    private var filterUsers = [User]()
    
    private let reactor: SearchReactor
    private let disposeBag = DisposeBag()
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    private var inSearchMode: Bool {
        return searchController.isActive && !searchController.searchBar.text!.isEmpty
    }
    
    init(reactor: SearchReactor) {
        self.reactor = reactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
//        fetchUsers()
        configureSearchController()
        bind(reactor: reactor)
    }
    
    //    func fetchUsers() {
    //        UserService.fetchUsers { users in
    //            self.users = users
    //            self.tableView.reloadData()
    //        }
    //    }
    
    private func configureTableView() {
        view.backgroundColor = .white
        
        tableView.register(UserCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 64
    }
    
    private func configureSearchController() {
//        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "검색"
        navigationItem.searchController = searchController
        definesPresentationContext = false
    }
    
    private func bind(reactor: SearchReactor) {
        /// Input
        reactor.action.onNext(.fetchUsers)
        
        searchController.searchBar.rx.text
            .orEmpty
            .distinctUntilChanged()
            .map { SearchReactor.Action.search($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        tableView.rx.modelSelected(User.self)
            .withUnretained(self)
            .subscribe(onNext: { owner, user in
                let controller = ProfileViewController(user: user)
                owner.navigationController?.pushViewController(controller, animated: true)
            })
            .disposed(by: disposeBag)
        
        /// Output
        reactor.state.map { $0.isSearchMode ? $0.filteredUsers : $0.users}
            .bind(to: tableView.rx.items(cellIdentifier: reuseIdentifier, cellType: UserCell.self)) { index, user, cell in
                cell.viewModel = UserCellViewModel(user: user)
            }
            .disposed(by: disposeBag)
    }
}

// MARK: 테이블 뷰 데이터소스
//extension SearchViewController {
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return inSearchMode ? filterUsers.count : users.count
//    }
//    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! UserCell
//        
//        let user = inSearchMode ? filterUsers[indexPath.row] : users[indexPath.row]
//        cell.viewModel = UserCellViewModel(user: user)
//        return cell
//    }
//}

//extension SearchViewController {
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let user = inSearchMode ? filterUsers[indexPath.row] : users[indexPath.row]
//        let controller = ProfileViewController(user: user)
//        navigationController?.pushViewController(controller, animated: true)
//    }
//    
//}
//
//
//extension SearchViewController: UISearchResultsUpdating {
//    func updateSearchResults(for searchController: UISearchController) {
//        guard let searchText = searchController.searchBar.text?.lowercased() else { return }
//        filterUsers = users.filter { $0.username.contains(searchText) || $0.fullname.lowercased().contains(searchText) }
//        self.tableView.reloadData()
//    }
//}
