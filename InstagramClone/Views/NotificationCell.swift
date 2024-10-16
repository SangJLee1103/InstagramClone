//
//  NotificationCell.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/20.
//

import UIKit
import RxSwift

protocol NotificationCellDelegate: class {
    func cell(_ cell: NotificationCell, wantsToFollow uid: String)
    func cell(_ cell: NotificationCell, wantsToUnfollow uid: String)
    func cell(_ cell: NotificationCell, wantsToViewPost postId: String)
}

final class NotificationCell: UITableViewCell {
    
    let disposeBag = DisposeBag()
    weak var delegate: NotificationCellDelegate?
    
    var reactor: NotificationCellReactor? {
        didSet {
            guard let reactor = reactor else { return }
            bind(reactor: reactor)
        }
    }
    
    private lazy var profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .lightGray
        return iv
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.text = "venom"
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var postImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 7
        iv.backgroundColor = .lightGray
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handlePostTapped))
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(tap)
        return iv
    }()
    
    private lazy var followButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Loading", for: .normal)
        button.layer.cornerRadius = 7
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 0.5
        button.titleLabel?.font = .boldSystemFont(ofSize: 14)
        button.setTitleColor(.black, for: .normal)
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        
        addSubview(profileImageView)
        profileImageView.setDimensions(height: 48, width: 48)
        profileImageView.layer.cornerRadius = 48 / 2
        profileImageView.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 12)
        
        contentView.addSubview(followButton)
        followButton.centerY(inView: self)
        followButton.anchor(right: rightAnchor, paddingRight: 12, width: 88, height: 32)
        
        contentView.addSubview(postImageView)
        postImageView.centerY(inView: self)
        postImageView.anchor(right: rightAnchor, paddingRight: 12, width: 40, height: 40)
        
        contentView.addSubview(infoLabel)
        infoLabel.centerY(inView: profileImageView, leftAnchor: profileImageView.rightAnchor, paddingLeft: 8)
        infoLabel.anchor(right: followButton.leftAnchor, paddingRight: 4)
        
        followButton.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bind(reactor: NotificationCellReactor) {
        if let profileImageUrl = URL(string: reactor.currentState.notification.userProfileImageUrl) {
            profileImageView.sd_setImage(with: profileImageUrl)
        }
        
        if let postImageUrl =  URL(string: reactor.currentState.notification.postImageUrl ?? "") {
            postImageView.sd_setImage(with: postImageUrl)
        }
        
        let username = reactor.currentState .notification.username
        let message = reactor.currentState.notification.type.notificationMessage
        let attributedText = NSMutableAttributedString(string: username, attributes: [.font: UIFont.boldSystemFont(ofSize: 14)])
        attributedText.append(NSAttributedString(string: message, attributes: [. font: UIFont.systemFont(ofSize: 14)]))
        attributedText.append(NSAttributedString(string: "  2m", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.lightGray]))
        infoLabel.attributedText = attributedText
        
        reactor.state.map { $0.notification.type == .follow }
            .withUnretained(self)
            .subscribe(onNext: { owner, shouldHidePostImage in
                owner.followButton.isHidden = !shouldHidePostImage
                owner.postImageView.isHidden = shouldHidePostImage
            })
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.notification.userIsFollwed }
            .withUnretained(self)
            .subscribe(onNext: { owner, isFollowed in
                owner.followButton.setTitle(isFollowed ? "팔로잉" : "팔로우", for: .normal)
                owner.followButton.backgroundColor = isFollowed ? .lightGray : .systemBlue
                owner.followButton.setTitleColor(isFollowed ? .black : .white, for: .normal)
            })
            .disposed(by: disposeBag)
        
        followButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                if self.reactor?.currentState.notification.userIsFollwed == true {
                    delegate?.cell(self, wantsToUnfollow: reactor.currentState.notification.uid)
                } else {
                    delegate?.cell(self, wantsToFollow: reactor.currentState.notification.uid)
                }
            })
            .disposed(by: disposeBag)
    }
    
    
//    @objc func handleFollowTapped() {
//        guard let reactor = reactor else { return }
//        let action: NotificationCellReactor.Action = reactor.currentState.isFollowed ? .followTapped : .followTapped
//        reactor.action.onNext(action)
//    }
//    
    @objc func handlePostTapped() {
        guard let postId = reactor?.currentState.notification.postId else { return }
        delegate?.cell(self, wantsToViewPost: postId)
    }
    
    //    @objc func handleFollowTapped() {
    //        guard let viewModel = viewModel else { return }
    //        if viewModel.notification.userIsFollwed {
    //            delegate?.cell(self, wantsToUnfollow: viewModel.notification.uid)
    //        } else {
    //            delegate?.cell(self, wantsToFollow: viewModel.notification.uid)
    //        }
    //    }
    //
    //    @objc func handlePostTapped() {
    //        guard let postId = viewModel?.notification.postId else { return }
    //        delegate?.cell(self, wantsToViewPost: postId)
    //    }
    //
    //    func configure() {
    //        guard let viewModel = viewModel else { return }
    //        profileImageView.sd_setImage(with: viewModel.profileImageUrl)
    //        postImageView.sd_setImage(with: viewModel.postImageUrl)
    //        infoLabel.attributedText = viewModel.notificationMessage
    //
    //        followButton.isHidden = !viewModel.shouldHidePostImage
    //        postImageView.isHidden = viewModel.shouldHidePostImage
    //
    //        followButton.setTitle(viewModel.followButtonText, for: .normal)
    //        followButton.backgroundColor = viewModel.followButtonBackgroundColor
    //        followButton.setTitleColor(viewModel.followButtonTextColor, for: .normal)
    //    }
    
}
