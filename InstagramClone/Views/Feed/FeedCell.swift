//
//  FeedCell.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/10.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit

protocol FeedCellDelegate: class {
    func cell(_ cell: FeedCell, wantsToShowCommentsFor post: Post)
    func cell(_ cell: FeedCell, wantsToShowProfileFor uid: String)
}

class FeedCell: UICollectionViewCell {
    
    var reactor: FeedCellReactor? {
        didSet {
            guard let reactor = reactor else { return }
            bind(reactor: reactor)
        }
    }
    
    private let disposeBag = DisposeBag()
    
    weak var delegate: FeedCellDelegate?
    
    private lazy var profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        iv.backgroundColor = .lightGray
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(showUserProfile))
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(tap)
        
        return iv
    }()
    
    private lazy var usernameButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 13)
        button.addTarget(self, action: #selector(showUserProfile), for: .touchUpInside)
        return button
    }()
    
    private let postImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        iv.image = #imageLiteral(resourceName: "venom-7")
        return iv
    }()
    
    private lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage( UIImage(named: "like_unselected") , for: .normal)
        button.tintColor = .black
        return button
    }()
    
    private lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "comment"), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(didTapComments), for: .touchUpInside)
        return button
    }()
    
    private let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "send2"), for: .normal)
        button.tintColor = .black
        return button
    }()
    
    private let likesLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 13)
        return label
    }()
    
    private let captionLabel: UILabel = {
        let label = UILabel()
        label.text = "Some test caption for now.."
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let postTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "2 days ago"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .lightGray
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: 20, paddingLeft: 12)
        profileImageView.setDimensions(height: 40, width: 40)
        profileImageView.layer.cornerRadius = 40 / 2
        
        addSubview(usernameButton)
        usernameButton.centerY(inView: profileImageView,leftAnchor: profileImageView.rightAnchor, paddingLeft: 8)
        
        addSubview(postImageView)
        postImageView.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 8)
        
        postImageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        
        configureActionButton()
        
        addSubview(likesLabel)
        likesLabel.anchor(top: likeButton.bottomAnchor, left: leftAnchor, paddingTop: -4, paddingLeft: 12)
        
        addSubview(captionLabel)
        captionLabel.anchor(top: likesLabel.bottomAnchor, left: leftAnchor, paddingTop: 8, paddingLeft: 12)
        
        addSubview(postTimeLabel)
        postTimeLabel.anchor(top: captionLabel.bottomAnchor, left: leftAnchor, paddingTop: 8, paddingLeft: 12)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func showUserProfile() {
        guard let reactor = reactor else { return }
        delegate?.cell(self, wantsToShowProfileFor: reactor.currentState.post.ownerUid)
    }
    
    @objc func didTapComments() {
        guard let reactor = reactor else { return }
        delegate?.cell(self, wantsToShowCommentsFor: reactor.currentState.post)
    }
    
    func configureActionButton() {
        let stackView = UIStackView(arrangedSubviews: [likeButton, commentButton, shareButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        
        addSubview(stackView)
        stackView.anchor(top: postImageView.bottomAnchor, left: leftAnchor, paddingLeft: 4, width: 120, height: 50)
    }
    
    private func bind(reactor: FeedCellReactor) {
        // Input
        likeButton.rx.tap
            .map { FeedCellReactor.Action.likeButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // Output
        reactor.state.map { $0.post.imageUrl }
            .compactMap { URL(string: $0) }
            .subscribe(onNext: { [weak self] url in
                self?.postImageView.sd_setImage(with: url)
            })
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.post.ownerImageUrl }
            .compactMap { URL(string: $0) }
            .subscribe(onNext: { [weak self] url in
                self?.profileImageView.sd_setImage(with: url)
            })
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.post.ownerUsername }
            .bind(to: usernameButton.rx.title(for: .normal))
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.post.caption }
            .bind(to: captionLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { "좋아요 \($0.likesCount) 개" }
            .bind(to: likesLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.isLiked }
            .subscribe(onNext: { [weak self] isLiked in
                let imageName = isLiked ? "like_selected" : "like_unselected"
                self?.likeButton.setImage(UIImage(named: imageName), for: .normal)
                self?.likeButton.tintColor = isLiked ? .red : .black
            })
            .disposed(by: disposeBag)
    }
}
