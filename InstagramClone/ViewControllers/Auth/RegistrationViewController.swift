//
//  RegistrationViewController.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/11.
//

import UIKit
import Toast_Swift
import RxCocoa
import ReactorKit

final class RegistrationViewController: UIViewController {
    
    private let reactor = RegistrationReactor()
    private let disposeBag = DisposeBag()
    
    weak var delegate: AuthenticationDelegate?
    
    private let plusPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "plus_photo"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleProfilePhotoSelect), for: .touchUpInside)
        return button
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
    
    private let fullnameTextField = CustomTextField(placeholder: "이름")
    private let usernameTextField = CustomTextField(placeholder: "성")
    
    private let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("회원가입", for: .normal)
        button.setTitleColor(.white.withAlphaComponent(0.67), for: .normal)
        button.backgroundColor = #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1).withAlphaComponent(0.5)
        button.layer.cornerRadius = 5
        button.setHeight(50)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.isEnabled = false
        return button
    }()
    
    private let alreadyHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.attributedTitle(firstPart: "이미 계정이 있으신가요? ", secondPart: "로그인")
        button.addTarget(self, action: #selector(handleShowLogin), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind(reactor: reactor)
    }
    
    @objc func handleShowLogin() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func handleProfilePhotoSelect() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    private func configureUI() {
        configureGradientLayer()
        
        view.addSubview(plusPhotoButton)
        plusPhotoButton.centerX(inView: view)
        plusPhotoButton.setDimensions(height: 140, width: 140)
        plusPhotoButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        
        let stack = UIStackView(arrangedSubviews: [emailTextField, passwordTextField, fullnameTextField, usernameTextField, signUpButton])
        stack.axis = .vertical
        stack.spacing = 20
        
        view.addSubview(stack)
        stack.anchor(top: plusPhotoButton.bottomAnchor, left: view.leftAnchor,
                     right: view.rightAnchor, paddingTop: 32, paddingLeft: 32, paddingRight: 32)
        
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.centerX(inView: view)
        alreadyHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor)
    }
    
    private func bind(reactor: RegistrationReactor) {
        /// Input
        emailTextField.rx.text
            .orEmpty
            .distinctUntilChanged()
            .map { RegistrationReactor.Action.emailChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        passwordTextField.rx.text
            .orEmpty
            .distinctUntilChanged()
            .map { RegistrationReactor.Action.passwordChange($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        fullnameTextField.rx.text
            .orEmpty
            .distinctUntilChanged()
            .map { RegistrationReactor.Action.fullnameChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        usernameTextField.rx.text
            .orEmpty
            .distinctUntilChanged()
            .map { RegistrationReactor.Action.usernameChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        signUpButton.rx.tap
            .map { RegistrationReactor.Action.signUp }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        /// Output
        reactor.state
            .map { $0.profileImage }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .withUnretained(self) // 순환 참조 피하기
            .subscribe(onNext: { owner, image in
                guard let image = image else { return }
                owner.plusPhotoButton.layer.cornerRadius = owner.plusPhotoButton.frame.width / 2
                owner.plusPhotoButton.layer.masksToBounds = true
                owner.plusPhotoButton.layer.borderColor = UIColor.white.cgColor
                owner.plusPhotoButton.layer.borderWidth = 2
                owner.plusPhotoButton.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
            })
            .disposed(by: disposeBag)
        
        reactor.state
            .map { $0.isSignUpEnabled }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, isEnabled in
                owner.signUpButton.isEnabled = isEnabled
                owner.signUpButton.backgroundColor = isEnabled ? #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1) : #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1).withAlphaComponent(0.5)
                owner.signUpButton.setTitleColor(isEnabled ? .white : UIColor(white: 1, alpha: 0.67), for: .normal)
            })
            .disposed(by: disposeBag)
        
        reactor.state
            .map { $0.isSignupCompleted }
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
                /// ReactorKit의 상태관리 방식: 같은 에러가 다시 발생해도 State의 값이 변경되지 않으면 UI에 변화가 반영되지 않음
                owner.view.makeToast(errorMessage, position: .top) { [weak self] _ in
                    self?.reactor.action.onNext(.setError(nil))
                }
            })
            .disposed(by: disposeBag)
    }
}

extension RegistrationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.editedImage] as? UIImage else { return }
        reactor.action.onNext(.profileImageSelected(selectedImage))
        
        self.dismiss(animated: true, completion: nil)
    }
}
