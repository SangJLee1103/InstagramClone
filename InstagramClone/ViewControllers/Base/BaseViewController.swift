//
//  BaseViewController.swift
//  InstagramClone
//
//  Created by 이상준 on 9/16/24.
//

import UIKit
import RxSwift
import RxCocoa

class BaseViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
