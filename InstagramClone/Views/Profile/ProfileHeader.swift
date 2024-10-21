//
//  ProfileHeader.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/12.
//

import UIKit
import SDWebImage
import RxSwift
import ReactorKit

protocol ProfileHeaderDelegate: class {
    func header(_ profileHeader: ProfileHeader, didTapActionButtonFor user: User)
}

final class ProfileHeader: UICollectionReusableView {
    
    weak var delegate: ProfileHeaderDelegate?
    
    var reactor: ProfileHeaderViewReactor? {
        didSet {
            guard let reactor = reactor else { return }
            bind(reactor: reactor)
        }
    }
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Properties
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .lightGray
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 14)
        return label
    }()
    
    private lazy var editProfileFollowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Loading", for: .normal)
        button.layer.cornerRadius = 3
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 0.5
        button.titleLabel?.font = .boldSystemFont(ofSize: 14)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(handleEditProfileFollowTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var postsLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private lazy var followersLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private lazy var followingsLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    let gridButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "grid"), for: .normal)
        return button
    }()
    
    let listButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "list"), for: .normal)
        button.tintColor = UIColor(white: 0, alpha: 0.2)
        return button
    }()
    
    let bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "ribbon"), for: .normal)
        button.tintColor = UIColor(white: 0, alpha: 0.2)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        backgroundColor = .white
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: 16, paddingLeft: 12)
        profileImageView.setDimensions(height: 80, width: 80)
        profileImageView.layer.cornerRadius = 80 / 2
        
        addSubview(nameLabel)
        nameLabel.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, paddingTop: 12, paddingLeft: 12)
        
        addSubview(editProfileFollowButton)
        editProfileFollowButton.anchor(top: nameLabel.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 16, paddingLeft: 24, paddingRight: 24)
        
        let stack = UIStackView(arrangedSubviews: [postsLabel, followersLabel, followingsLabel])
        stack.distribution = .fillEqually
        
        addSubview(stack)
        stack.centerY(inView: profileImageView)
        stack.anchor(left: profileImageView.rightAnchor, right: rightAnchor, paddingLeft: 12, paddingRight: 12, height: 50)
        
        let topDivider = UIView()
        topDivider.backgroundColor = .lightGray
        
        let bottomDivider = UIView()
        bottomDivider.backgroundColor = .lightGray
        
        let buttonStack = UIStackView(arrangedSubviews: [gridButton, listButton, bookmarkButton])
        buttonStack.distribution = .fillEqually
        
        addSubview(buttonStack)
        addSubview(topDivider)
        addSubview(bottomDivider)
        
        buttonStack.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, height: 50)
        
        topDivider.anchor(top: buttonStack.topAnchor, left: leftAnchor, right: rightAnchor, height: 0.5)
        bottomDivider.anchor(top: buttonStack.bottomAnchor, left: leftAnchor, right: rightAnchor, height: 0.5)
    }
    
    @objc func handleEditProfileFollowTapped() {
        guard let reactor = reactor else { return }
        delegate?.header(self, didTapActionButtonFor: reactor.currentState.user)
    }
    
    private func bind(reactor: ProfileHeaderViewReactor) {
        reactor.state.map { $0.user.fullname }
            .bind(to: nameLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { URL(string: $0.user.profileImageUrl) }
            .compactMap { $0 }
            .bind(to: profileImageView.rx.setImageUrl)
            .disposed(by: disposeBag)
        
        reactor.state.map { reactor in
                if reactor.user.isCurrentUser {
                    return "프로필 편집"
                } else {
                    return reactor.user.isFollowed ? "팔로잉" : "팔로우"
                }
            }
            .bind(to: editProfileFollowButton.rx.title(for: .normal))
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.user.isCurrentUser ? UIColor.white : ($0.user.isFollowed ? UIColor.systemGray : UIColor.systemBlue) }
            .bind(to: editProfileFollowButton.rx.backgroundColor)
            .disposed(by: disposeBag)
        
        // 팔로우/팔로잉 버튼 텍스트 색상 바인딩
        reactor.state.map { $0.user.isCurrentUser ? UIColor.black : UIColor.white }
            .subscribe(onNext: { [weak self] color in
                self?.editProfileFollowButton.setTitleColor(color, for: .normal)
            })
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.user.stats.posts }
            .map { [weak self] in
                self?.postsLabel.attributedStatText(value: $0, label: "게시물")
            }
            .bind(to: postsLabel.rx.attributedText)
            .disposed(by: disposeBag)

        reactor.state.map { $0.user.stats.followers }
            .map { [weak self] in
                self?.followersLabel.attributedStatText(value: $0, label: "팔로워")
            }
            .bind(to: followersLabel.rx.attributedText)
            .disposed(by: disposeBag)

        reactor.state.map { $0.user.stats.following }
            .map { [weak self] in
                self?.followingsLabel.attributedStatText(value: $0, label: "팔로잉")
            }
            .bind(to: followingsLabel.rx.attributedText)
            .disposed(by: disposeBag)
    }
}
