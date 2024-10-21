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
        configureSearchController()
        bind(reactor: reactor)
    }
    
    private func configureTableView() {
        view.backgroundColor = .white
        
        tableView.delegate = nil
        tableView.dataSource = nil
        tableView.register(UserCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 64
    }
    
    private func configureSearchController() {
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
                let controller = ProfileViewController(reactor: ProfileReactor(user: user))
                owner.navigationController?.pushViewController(controller, animated: true)
            })
            .disposed(by: disposeBag)
        
        /// Output
        reactor.state.map { $0.isSearchMode ? $0.filteredUsers : $0.users}
            .bind(to: tableView.rx.items(cellIdentifier: reuseIdentifier, cellType: UserCell.self)) { index, user, cell in
                cell.bind(reactor: UserCellReactor(user: user))
            }
            .disposed(by: disposeBag)
    }
}
