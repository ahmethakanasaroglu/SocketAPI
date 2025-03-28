import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {
    let viewModel = LoginViewModel()
    
    let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        return textField
    }()
    
    let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Şifre"
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        textField.isSecureTextEntry = true
        return textField
    }()
    
    let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Name"
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        return textField
    }()
    
    let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Giriş Yap", for: .normal)
        button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        return button
    }()
    
    let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Kayıt Ol", for: .normal)
        button.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        bindViewModel()
    }
    
    func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [nameTextField, emailTextField, passwordTextField, loginButton, registerButton])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(equalToConstant: 250)
        ])
    }
    
    func bindViewModel() {
        viewModel.onLoginSuccess = {
            DispatchQueue.main.async {
                let chatVC = UsersViewController()
                chatVC.modalPresentationStyle = .fullScreen
                self.present(chatVC, animated: true, completion: nil)
            }
        }
        
        viewModel.onError = { errorMessage in
            DispatchQueue.main.async {
                self.hataMesaji(titleInput: "Hata!", messageInput: errorMessage)
            }
        }
    }
    
    @objc func loginTapped() {
        guard let name = nameTextField.text, let email = emailTextField.text, let password = passwordTextField.text, !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            hataMesaji(titleInput: "Hata!", messageInput: "İsim, Email ve Şifre Giriniz")
            return
        }
        viewModel.login(email: email, password: password)
    }
    
    @objc func registerTapped() {
        guard let name = nameTextField.text, let email = emailTextField.text, let password = passwordTextField.text, !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            hataMesaji(titleInput: "Hata!", messageInput: "İsim, Email ve Şifre Giriniz")
            return
        }
        viewModel.register(name:name, email: email, password: password) { success in
            if success {
                    print("✅ Kayıt başarılı! Kullanıcı Firestore'a kaydedildi.")
                    DispatchQueue.main.async {
                        let usersVC = UsersViewController()
                        self.navigationController?.pushViewController(usersVC, animated: true)
                    }
                } else {
                    print("❌ Kayıt başarısız! Lütfen tekrar deneyin.")
                }
        }
    }
    
    func hataMesaji(titleInput: String, messageInput: String) {
        let alert = UIAlertController(title: titleInput, message: messageInput, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
    
    func registerUser(name: String, email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Kayıt hatası: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let uid = result?.user.uid else {
                print("UID bulunamadı!")
                completion(false)
                return
            }
            
            let db = Firestore.firestore()
            let userData: [String: Any] = ["name": name, "email": email, "uid": uid]
            
            db.collection("users").document(uid).setData(userData) { error in
                if let error = error {
                    print("Firestore'a kaydedilemedi: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("🔥 Kullanıcı Firestore'a başarıyla kaydedildi! UID: \(uid)")
                    completion(true)
                }
            }
        }
    }


}
