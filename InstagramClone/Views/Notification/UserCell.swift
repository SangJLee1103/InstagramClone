//
//  UserCell.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/13.
//

import UIKit
import RxSwift
import ReactorKit

final class UserCell: UITableViewCell {
    
    private let disposeBag = DisposeBag()
    
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .lightGray
        iv.image = #imageLiteral(resourceName: "venom-7")
        return iv
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.text = "venom"
        return label
    }()
    
    private let fullnameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.text = "Son"
        label.textColor = .lightGray
        return label
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        profileImageView.setDimensions(height: 48, width: 48)
        profileImageView.layer.cornerRadius = 48 / 2
        profileImageView.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 12)
        
        let stack = UIStackView(arrangedSubviews: [usernameLabel, fullnameLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        
        addSubview(stack)
        stack.centerY(inView: profileImageView, leftAnchor: profileImageView.rightAnchor, paddingLeft: 8)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bind(reactor: UserCellReactor) {
        reactor.state.map { URL(string: $0.user.profileImageUrl )}
            .compactMap { $0 }
            .bind(to: profileImageView.rx.setImageUrl)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.user.username }
            .bind(to: usernameLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.user.fullname }
            .bind(to: fullnameLabel.rx.text)
            .disposed(by: disposeBag)
    }
}
