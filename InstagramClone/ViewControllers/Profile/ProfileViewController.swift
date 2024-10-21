//
//  ProfileViewController.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/10.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import ReactorKit

private let cellIdentifier = "ProfileCell"
private let headerIdentifier = "ProfileHeader"

final class ProfileViewController: UICollectionViewController {
    
    private let disposeBag = DisposeBag()
    private let reactor: ProfileReactor
    
    init(reactor: ProfileReactor) {
        self.reactor = reactor
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        bind()
    }
    
    private func configureCollectionView() {
        collectionView.dataSource = nil
        
        collectionView.backgroundColor = .white
        collectionView.register(ProfileCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.register(ProfileHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: headerIdentifier)
    }
    
    private func bind() {
        /// Input
        reactor.action.onNext(.checkIfUserIsFollowed)
        reactor.action.onNext(.fetchPosts)
        reactor.action.onNext(.fetchUserStats)
        
        /// CollectionView DataSource
        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, Post>>(
            configureCell: { (dataSource, collectionView, indexPath, post) -> UICollectionViewCell in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ProfileCell
                cell.bind(reactor: ProfileCellReactor(post: post))
                return cell
            },
            configureSupplementaryView: { [weak self] (dataSource, collectionView, kind, indexPath) -> UICollectionReusableView in
                guard let self = self else { return UICollectionReusableView() }
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerIdentifier, for: indexPath) as! ProfileHeader
                header.delegate = self
                header.reactor = ProfileHeaderViewReactor(user: reactor.currentState.user)
                return header
            }
        )
        
        /// Output
        reactor.state.map { $0.user.username }
            .bind(to: navigationItem.rx.title)
            .disposed(by: disposeBag)
        
        reactor.state.map { state -> [SectionModel<String, Post>] in
            return [SectionModel(model: "Profile", items: state.posts)]
        }
        .bind(to: collectionView.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                let controller = FeedViewController(reactor: FeedReactor(initialPost: reactor.currentState.posts[indexPath.row]), collectionViewLayout: UICollectionViewFlowLayout())
                navigationController?.pushViewController(controller, animated: true)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: 컬렉션뷰 DelegateFlowLayout
extension ProfileViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 2) / 3
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 240)
    }
}

extension ProfileViewController: ProfileHeaderDelegate {
    func header(_ profileHeader: ProfileHeader, didTapActionButtonFor user: User) {
        guard tabBarController is MainTabViewController else { return }
        guard let currentUser = UserManager.shared.currentUser else { return }
        
        if user.isCurrentUser {
            
        } else if user.isFollowed {
            reactor.action.onNext(.unfollow)
            self.collectionView.reloadData()
        } else {
            reactor.action.onNext(.follow)
            self.collectionView.reloadData()
            NotificationService.uploadNotification(toUid: user.uid, fromUser: currentUser, type: .follow)
        }
    }
}
