//
//  FeedController.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/10.
//

import UIKit
import Firebase
import RxSwift
import RxCocoa
import ReactorKit

private let reuseIdentifier = "Cell"

final class FeedViewController: UICollectionViewController {
    
    private let reactor = FeedReactor()
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind(reactor: reactor)
    }
    
    func handleRefresh() {
        reactor.action.onNext(.refresh)
    }
    
    @objc func handleLogout() {
        do {
            try Auth.auth().signOut()
            let controller = LoginViewController()
            controller.delegate = self.tabBarController as? MainTabViewController
            let nav = UINavigationController(rootViewController: controller)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
        } catch {
            print("DEBUG: Failed Logout")
        }
    }
    
    private func configureUI() {
        navigationItem.title = "피드"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        collectionView.backgroundColor = .white
        collectionView.register(FeedCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        let refresher = UIRefreshControl()
        collectionView.refreshControl = refresher
    }
    
    private func bind(reactor: FeedReactor) {
        // Input
        collectionView.refreshControl?.rx.controlEvent(.valueChanged)
            .map { FeedReactor.Action.refresh }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // Output
        reactor.action.onNext(.fetchPosts)
        
        reactor.state.map { $0.posts }
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .bind { owner, posts in
                owner.collectionView.reloadData()
                owner.collectionView.refreshControl?.endRefreshing()
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.posts }
            .filter { !$0.isEmpty }
            .distinctUntilChanged()
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.reactor.action.onNext(.checkIfUserLikedPosts)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: 컬렉션 뷰 데이터 소스
extension FeedViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return reactor.currentState.posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FeedCell
        cell.delegate = self
        
        let post = reactor.currentState.posts[indexPath.row]
        cell.reactor = FeedCellReactor(post: post)
        return cell
    }
}

// MARK: 컬렉션뷰 FlowLayout
extension FeedViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.width
        var height = width + 8 + 40 + 8
        height += 50
        height += 60
        
        return CGSize(width: width, height: height)
    }
}

extension FeedViewController: FeedCellDelegate {
    func cell(_ cell: FeedCell, wantsToShowProfileFor uid: String) {
        UserService.fetchUser(withUid: uid) { user in
            let controller = ProfileViewController(user: user)
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func cell(_ cell: FeedCell, wantsToShowCommentsFor post: Post) {
        let controller = CommentViewController(post: post)
        navigationController?.pushViewController(controller, animated: true)
    }
}
