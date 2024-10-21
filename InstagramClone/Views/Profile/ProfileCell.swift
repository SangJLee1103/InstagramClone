//
//  ProfileCell.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/12.
//

import UIKit
import RxSwift
import ReactorKit

final class ProfileCell: UICollectionViewCell {
    private let disposeBag = DisposeBag()
    
    private let postImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = #imageLiteral(resourceName: "venom-7")
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        backgroundColor = .lightGray
        
        addSubview(postImageView)
        postImageView.fillSuperview()
    }
    
    func bind(reactor: ProfileCellReactor) {
        reactor.state.map { $0.post.imageUrl }
            .compactMap { URL(string: $0) }
            .bind(to: postImageView.rx.setImageUrl)
            .disposed(by: disposeBag)
    }
}
