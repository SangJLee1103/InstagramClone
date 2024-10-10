//
//  NotificationVIewContorller.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/10.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit

private let reuseIdentifier = "NotificationCell"

final class NotificationViewContorller: UITableViewController {
    
    private let reactor = NotificationReactor()
    private let disposeBag = DisposeBag()
    private let refresher = UIRefreshControl()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        bind(reactor: reactor)
    }
    
    //
    //    func checkIfUserIsFollowed() {
    //        notifications.forEach { notification in
    //            guard notification.type == .follow else { return }
    //
    //            UserService.checkIfUserIsFollowed(uid: notification.uid) { isFollowed in
    //                if let index = self.notifications.firstIndex(where: { $0.id == notification.id }) {
    //                    self.notifications[index].userIsFollwed = isFollowed
    //                }
    //            }
    //        }
    //    }
    
    // MARK: - 액션
    @objc func handleRefreesh() {
        reactor.action.onNext(.refresh)
    }
    
    private func configureTableView() {
        view.backgroundColor = .white
        navigationItem.title = "알림"
        
        tableView.register(NotificationCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.dataSource = nil
        tableView.delegate = nil
        
        tableView.rowHeight = 80
        tableView.separatorStyle = .none
        
        refresher.addTarget(self, action: #selector(handleRefreesh), for: .valueChanged)
        tableView.refreshControl = refresher
    }
    
    private func bind(reactor: NotificationReactor) {
        
        /// Input
        reactor.action.onNext(.fetchNotifications)
        
        /// Output
        reactor.state.map { $0.isLoading }
            .distinctUntilChanged()
            .bind(to: refresher.rx.isRefreshing)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.notifications }
            .distinctUntilChanged()
            .bind(to: tableView.rx.items(cellIdentifier: reuseIdentifier, cellType: NotificationCell.self)) { index, notification, cell in
                let cellReactor = NotificationCellReactor(notification: notification)
                cell.reactor = cellReactor
                cell.delegate = self
            }
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.showLoader(true)
                let notification = reactor.currentState.notifications[indexPath.row]
                
                UserService.fetchUser(withUid: notification.uid) { user in
                    self?.showLoader(false)
                    let controller = ProfileViewController(user: user)
                    self?.navigationController?.pushViewController(controller, animated: true)
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: UITableViewDataSource
//extension NotificationViewContorller {
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return notifications.count
//    }
//    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! NotificationCell
//        cell.viewModel = NotificationViewModel(notification: notifications[indexPath.row])
//        cell.delegate = self
//        return cell
//    }
//}

//extension NotificationViewContorller {
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        showLoader(true)
//        
//        UserService.fetchUser(withUid: notifications[indexPath.row].uid) { user in
//            self.showLoader(false)
//            
//            let controller = ProfileViewController(user: user)
//            self.navigationController?.pushViewController(controller, animated: true)
//        }
//    }
//}

extension NotificationViewContorller: NotificationCellDelegate {
    func cell(_ cell: NotificationCell, wantsToFollow uid: String) {
        reactor.action.onNext(.follow(uid))
        
        //        UserService.follow(uid: uid) { _ in
        //            self.showLoader(false)
        //            cell.viewModel?.notification.userIsFollwed.toggle()
        //        }
    }
    
    func cell(_ cell: NotificationCell, wantsToUnfollow uid: String) {
        showLoader(true)
        reactor.action.onNext(.unfollow(uid))
        //        UserService.unfollow(uid: uid) { _ in
        //            self.showLoader(false)
        //            cell.viewModel?.notification.userIsFollwed.toggle()
        //        }
    }
    
    func cell(_ cell: NotificationCell, wantsToViewPost postId: String) {
        showLoader(true)
        
        //        PostService.fetchPost(withPostId: postId) { post in
        //            self.showLoader(false)
        //            let controller = FeedViewController(collectionViewLayout: UICollectionViewFlowLayout())
        //            controller.post = post
        //            self.navigationController?.pushViewController(controller, animated: true)
        //        }
    }
}
