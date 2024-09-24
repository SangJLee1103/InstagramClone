//
//  CommentViewController.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/17.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit

private let reuseIdentifier = "CommentCell"

final class CommentViewController: UICollectionViewController {
    
    private let reactor: CommentReactor
    private let disposeBag = DisposeBag()
    
    private lazy var commentInputView: CommentInputAccesoryView = {
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        let cv = CommentInputAccesoryView(frame: frame)
        cv.delegate = self
        return cv
    }()
    
    init(reactor: CommentReactor) {
        self.reactor = reactor
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        bind(reactor: reactor)
    }
    
    override var inputAccessoryView: UIView? {
        get { return commentInputView }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func configureCollectionView() {
        navigationItem.title = "댓글"
        
        collectionView.backgroundColor = .white
        collectionView.register(CommentCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .interactive
    }
    
    private func bind(reactor: CommentReactor) {
        /// Input
        reactor.action.onNext(.fetchComments)
        
        /// Output
        reactor.state.map { $0.comments }
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .bind { owner, comments in
                owner.collectionView.reloadData()
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.isLoading }
            .withUnretained(self)
            .asDriver(onErrorJustReturn: (self, false))
            .drive(onNext: { owner, isLoading in
                owner.showLoader(isLoading)
            })
            .disposed(by: disposeBag)
        
        reactor.state
            .map { $0.errorMessage }
            .distinctUntilChanged()
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, errorMessage in
                owner.view.makeToast(errorMessage, position: .top) { [weak self] _ in
                    self?.reactor.action.onNext(.setError(nil))
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - 컬렉션 뷰 데이터소스
extension CommentViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return reactor.currentState.comments.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CommentCell
        let comment = reactor.currentState.comments[indexPath.row]
        cell.configure(with: comment)
        return cell
    }
}

// MARK: - UICOllectionViewDelegate
extension CommentViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let uid = reactor.currentState.comments[indexPath.row].uid
        UserService.fetchUser(withUid: uid) { user in
            let controller = ProfileViewController(user: user)
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}

// MARK: - 컬렉션 뷰 델리게이트 FlowLayout
extension CommentViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let comment = reactor.currentState.comments[indexPath.row]
        let height = estimateHeightForComment(comment.commentText, width: view.frame.width).height + 32
        return CGSize(width: view.frame.width, height: height)
    }
    
    private func estimateHeightForComment(_ text: String, width: CGFloat) -> CGSize {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = text
        label.lineBreakMode = .byWordWrapping
        label.setWidth(width)
        return label.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
}


// MARK: - CommentInputAccesoryViewDelegate
extension CommentViewController: CommentInputAccesoryViewDelegate {
    func inputView(_ inputView: CommentInputAccesoryView, wantsToUploadComment comment: String) {
        inputView.clearCommentTextView()
        reactor.action.onNext(.uploadComment(comment))
    }
}
