//
//  LoginViewController.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/11.
//

import UIKit
import RxCocoa
import ReactorKit

protocol AuthenticationDelegate: class {
    func authenticationComplete()
}

final class LoginViewController: BaseViewController {
    
    private let reactor = LoginReactor()
    private let disposeBag = DisposeBag()
    
    weak var delegate: AuthenticationDelegate?
    
    private let iconImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "Instagram_logo_white"))
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    private let emailTextField: CustomTextField = {
        let tf = CustomTextField(placeholder: "이메일")
        tf.keyboardType = .emailAddress
        return tf
    }()
    
    private let passwordTextField: CustomTextField = {
        let tf = CustomTextField(placeholder: "비밀번호")
        tf.isSecureTextEntry = true
        return tf
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("로그인", for: .normal)
        button.setTitleColor(.white.withAlphaComponent(0.67), for: .normal)
        button.backgroundColor = #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1).withAlphaComponent(0.5)
        button.layer.cornerRadius = 5
        button.setHeight(50)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.isEnabled = false
        return button
    }()
    
    private let forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.attributedTitle(firstPart: "비밀번호를 잊으셨나요", secondPart: "")
        return button
    }()
    
    private let dontHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.attributedTitle(firstPart: "계정이 없으신가요? ", secondPart: "회원가입")
        button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind(reactor: reactor)
    }
    
    // MARK: - 액션
    @objc func handleShowSignUp() {
        let controller = RegistrationViewController()
        controller.delegate = delegate
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func configureUI() {
        configureGradientLayer()
        
        view.backgroundColor = .white
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.barStyle = .black
        
        
        view.addSubview(iconImage)
        iconImage.centerX(inView: view)
        iconImage.setDimensions(height: 80, width: 120)
        iconImage.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        
        let stack = UIStackView(arrangedSubviews: [emailTextField, passwordTextField, loginButton, forgotPasswordButton])
        stack.axis = .vertical
        stack.spacing = 20
        
        view.addSubview(stack)
        stack.anchor(top: iconImage.bottomAnchor, left: view.leftAnchor,
                     right: view.rightAnchor, paddingTop: 32, paddingLeft: 32, paddingRight: 32)
        
        view.addSubview(dontHaveAccountButton)
        dontHaveAccountButton.centerX(inView: view)
        dontHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor)
    }
    
    private func bind(reactor: LoginReactor) {
        // Input
        emailTextField.rx.text
            .orEmpty
            .distinctUntilChanged()
            .map { LoginReactor.Action.emailChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        passwordTextField.rx.text
            .orEmpty
            .distinctUntilChanged()
            .map { LoginReactor.Action.passwordChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        loginButton.rx.tap
            .map { LoginReactor.Action.login }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        
        // Output
        reactor.state
            .map { $0.isLoginEnabled }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, isEnabled in
                owner.loginButton.isEnabled = isEnabled
                owner.loginButton.backgroundColor = isEnabled ? #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1) : #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1).withAlphaComponent(0.5)
                owner.loginButton.setTitleColor(isEnabled ? .white : UIColor(white: 1, alpha: 0.67), for: .normal)
            })
            .disposed(by: disposeBag)
        
        reactor.state
            .map { $0.isLoginCompleted }
            .filter { $0 }
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.delegate?.authenticationComplete()
            })
            .disposed(by: disposeBag)
        
        reactor.state
            .map { $0.errorMessage }
            .distinctUntilChanged()
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, errorMessage in
                owner.showErrorAlert(message: errorMessage)
                owner.reactor.action.onNext(.setError(nil))
            })
            .disposed(by: disposeBag)
    }
}
