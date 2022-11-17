//
//  CommentViewController.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/17.
//

import UIKit

private let reuseIdentifier = "CommentCell"

class CommentViewController: UICollectionViewController {
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}


// MARK: - 컬렉션 뷰 데이터소스
extension CommentViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        return cell
    }
}


extension CommentViewController {
    
}
